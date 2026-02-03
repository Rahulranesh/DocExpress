/**
 * Job Service - manages job lifecycle and history
 */

const Job = require('../models/Job');
const File = require('../models/File');
const AppError = require('../utils/AppError');
const { JOB_STATUS, PAGINATION } = require('../utils/constants');

class JobService {
  /**
   * Create a new job
   * @param {Object} jobData - Job creation data
   * @returns {Promise<Job>}
   */
  async createJob(jobData) {
    const { userId, type, inputFileIds = [], options = {} } = jobData;

    const job = new Job({
      userId,
      type,
      inputFiles: inputFileIds,
      options,
      status: JOB_STATUS.PENDING,
    });

    await job.save();
    return job;
  }

  /**
   * Get job by ID
   * @param {string} jobId - Job ID
   * @param {string} userId - User ID for ownership check
   * @returns {Promise<Job>}
   */
  async getJobById(jobId, userId = null) {
    const job = await Job.findById(jobId)
      .populate('inputFiles', 'originalName mimeType size storagePath')
      .populate('outputFiles', 'originalName mimeType size storagePath storageKey');

    if (!job) {
      throw AppError.notFound('Job not found');
    }

    // Check ownership if userId provided
    if (userId && job.userId.toString() !== userId.toString()) {
      throw AppError.forbidden('Access denied to this job');
    }

    // Filter out null files (deleted files that were referenced)
    const jobObj = job.toObject();
    jobObj.inputFiles = (jobObj.inputFiles || []).filter(f => f !== null);
    jobObj.outputFiles = (jobObj.outputFiles || []).filter(f => f !== null);

    return jobObj;
  }

  /**
   * Update job status to running
   * @param {string} jobId - Job ID
   * @returns {Promise<Job>}
   */
  async startJob(jobId) {
    const job = await Job.findById(jobId);
    if (!job) {
      throw AppError.notFound('Job not found');
    }

    job.status = JOB_STATUS.RUNNING;
    await job.save();
    return job;
  }

  /**
   * Mark job as completed with output files
   * @param {string} jobId - Job ID
   * @param {string[]} outputFileIds - Array of output file IDs
   * @returns {Promise<Job>}
   */
  async completeJob(jobId, outputFileIds = []) {
    const job = await Job.findById(jobId);
    if (!job) {
      throw AppError.notFound('Job not found');
    }

    job.status = JOB_STATUS.COMPLETED;
    job.outputFiles = outputFileIds;
    job.completedAt = new Date();
    await job.save();

    return job.populate('outputFiles', 'originalName mimeType size storagePath storageKey');
  }

  /**
   * Mark job as failed with error message
   * @param {string} jobId - Job ID
   * @param {string} errorMessage - Error description
   * @returns {Promise<Job>}
   */
  async failJob(jobId, errorMessage) {
    const job = await Job.findById(jobId);
    if (!job) {
      throw AppError.notFound('Job not found');
    }

    job.status = JOB_STATUS.FAILED;
    job.errorMessage = errorMessage;
    job.completedAt = new Date();
    await job.save();

    return job;
  }

  /**
   * Get jobs for user with pagination and filters
   * @param {string} userId - User ID
   * @param {Object} options - Query options
   * @returns {Promise<{jobs: Job[], pagination: Object}>}
   */
  async getUserJobs(userId, options = {}) {
    const {
      page = PAGINATION.DEFAULT_PAGE,
      limit = PAGINATION.DEFAULT_LIMIT,
      type,
      status,
      sortBy = 'createdAt',
      sortOrder = -1,
    } = options;

    const query = { userId };

    if (type) {
      query.type = type;
    }

    if (status) {
      query.status = status;
    }

    const skip = (page - 1) * Math.min(limit, PAGINATION.MAX_LIMIT);
    const actualLimit = Math.min(limit, PAGINATION.MAX_LIMIT);

    const [jobs, total] = await Promise.all([
      Job.find(query)
        .sort({ [sortBy]: sortOrder })
        .skip(skip)
        .limit(actualLimit)
        .populate('inputFiles', 'originalName mimeType size')
        .populate('outputFiles', 'originalName mimeType size storageKey'),
      Job.countDocuments(query),
    ]);

    // Filter out null files (deleted files that were referenced)
    const cleanedJobs = jobs.map(job => {
      const jobObj = job.toObject();
      jobObj.inputFiles = (jobObj.inputFiles || []).filter(f => f !== null);
      jobObj.outputFiles = (jobObj.outputFiles || []).filter(f => f !== null);
      return jobObj;
    });

    return {
      jobs: cleanedJobs,
      pagination: {
        page,
        limit: actualLimit,
        total,
      },
    };
  }

  /**
   * Get all jobs (admin)
   * @param {Object} options - Query options
   * @returns {Promise<{jobs: Job[], pagination: Object}>}
   */
  async getAllJobs(options = {}) {
    const {
      page = PAGINATION.DEFAULT_PAGE,
      limit = PAGINATION.DEFAULT_LIMIT,
      type,
      status,
      userId,
      sortBy = 'createdAt',
      sortOrder = -1,
    } = options;

    const query = {};

    if (type) query.type = type;
    if (status) query.status = status;
    if (userId) query.userId = userId;

    const skip = (page - 1) * Math.min(limit, PAGINATION.MAX_LIMIT);
    const actualLimit = Math.min(limit, PAGINATION.MAX_LIMIT);

    const [jobs, total] = await Promise.all([
      Job.find(query)
        .sort({ [sortBy]: sortOrder })
        .skip(skip)
        .limit(actualLimit)
        .populate('userId', 'name email')
        .populate('inputFiles', 'originalName mimeType size')
        .populate('outputFiles', 'originalName mimeType size'),
      Job.countDocuments(query),
    ]);

    // Filter out null files (deleted files that were referenced)
    const cleanedJobs = jobs.map(job => {
      const jobObj = job.toObject();
      jobObj.inputFiles = (jobObj.inputFiles || []).filter(f => f !== null);
      jobObj.outputFiles = (jobObj.outputFiles || []).filter(f => f !== null);
      return jobObj;
    });

    return {
      jobs: cleanedJobs,
      pagination: {
        page,
        limit: actualLimit,
        total,
      },
    };
  }

  /**
   * Get job statistics for user
   * @param {string} userId - User ID
   * @returns {Promise<Object>}
   */
  async getUserJobStats(userId) {
    const stats = await Job.aggregate([
      { $match: { userId: userId } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ]);

    const typeStats = await Job.aggregate([
      { $match: { userId: userId } },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
        },
      },
    ]);

    const totalJobs = await Job.countDocuments({ userId });

    return {
      total: totalJobs,
      byStatus: stats.reduce((acc, s) => {
        acc[s._id] = s.count;
        return acc;
      }, {}),
      byType: typeStats.reduce((acc, s) => {
        acc[s._id] = s.count;
        return acc;
      }, {}),
    };
  }

  /**
   * Delete old completed jobs (cleanup)
   * @param {number} maxAgeDays - Max age in days
   * @returns {Promise<{deleted: number}>}
   */
  async cleanupOldJobs(maxAgeDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - maxAgeDays);

    const result = await Job.deleteMany({
      status: { $in: [JOB_STATUS.COMPLETED, JOB_STATUS.FAILED] },
      completedAt: { $lt: cutoffDate },
    });

    return { deleted: result.deletedCount };
  }

  /**
   * Cancel a pending job
   * @param {string} jobId - Job ID
   * @param {string} userId - User ID
   * @returns {Promise<Job>}
   */
  async cancelJob(jobId, userId) {
    const job = await Job.findOne({ _id: jobId, userId });

    if (!job) {
      throw AppError.notFound('Job not found');
    }

    if (job.status !== JOB_STATUS.PENDING) {
      throw AppError.badRequest('Only pending jobs can be cancelled');
    }

    job.status = JOB_STATUS.FAILED;
    job.errorMessage = 'Cancelled by user';
    job.completedAt = new Date();
    await job.save();

    return job;
  }

  /**
   * Delete a job
   * @param {string} jobId - Job ID
   * @param {string} userId - User ID
   * @returns {Promise<void>}
   */
  async deleteJob(jobId, userId) {
    console.log('🔧 deleteJob called with jobId:', jobId, 'userId:', userId);
    const job = await Job.findOne({ _id: jobId, userId });

    if (!job) {
      console.log('🔧 Job not found');
      throw AppError.notFound('Job not found');
    }

    console.log('🔧 Job found:', job._id, job.type);
    const deleteResult = await Job.deleteOne({ _id: jobId });
    console.log('🔧 Database delete result:', deleteResult);
  }

  /**
   * Retry a failed job
   * @param {string} jobId - Job ID
   * @param {string} userId - User ID
   * @returns {Promise<Job>}
   */
  async retryJob(jobId, userId) {
    const originalJob = await Job.findOne({ _id: jobId, userId });

    if (!originalJob) {
      throw AppError.notFound('Job not found');
    }

    if (originalJob.status !== JOB_STATUS.FAILED) {
      throw AppError.badRequest('Only failed jobs can be retried');
    }

    // Create a new job with same parameters
    const newJob = new Job({
      userId: originalJob.userId,
      type: originalJob.type,
      inputFiles: originalJob.inputFiles,
      options: originalJob.options,
      status: JOB_STATUS.PENDING,
    });

    await newJob.save();
    return newJob;
  }

  /**
   * Execute job synchronously
   * This is a wrapper that handles job lifecycle for sync operations
   * @param {Object} jobData - Job data
   * @param {Function} processor - Async function that processes the job
   * @returns {Promise<Job>}
   */
  async executeJob(jobData, processor) {
    // Create the job
    const job = await this.createJob(jobData);

    try {
      // Mark as running
      await this.startJob(job._id);

      // Execute the processor function
      const outputFileIds = await processor(job);

      // Mark as completed
      const completedJob = await this.completeJob(job._id, outputFileIds);
      return completedJob;
    } catch (error) {
      // Mark as failed
      await this.failJob(job._id, error.message || 'Unknown error');
      throw error;
    }
  }

  /**
   * Get recent jobs for user
   * @param {string} userId - User ID
   * @param {number} limit - Number of jobs to return
   * @returns {Promise<Job[]>}
   */
  async getRecentJobs(userId, limit = 10) {
    const jobs = await Job.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('inputFiles', 'originalName mimeType')
      .populate('outputFiles', 'originalName mimeType storageKey');

    // Filter out null files (deleted files that were referenced)
    return jobs.map(job => {
      const jobObj = job.toObject();
      jobObj.inputFiles = (jobObj.inputFiles || []).filter(f => f !== null);
      jobObj.outputFiles = (jobObj.outputFiles || []).filter(f => f !== null);
      return jobObj;
    });
  }

  /**
   * Get pending jobs count for user
   * @param {string} userId - User ID
   * @returns {Promise<number>}
   */
  async getPendingJobsCount(userId) {
    return Job.countDocuments({
      userId,
      status: { $in: [JOB_STATUS.PENDING, JOB_STATUS.RUNNING] },
    });
  }

  /**
   * Check if user has reached job limit
   * @param {string} userId - User ID
   * @param {number} maxConcurrent - Max concurrent jobs allowed
   * @returns {Promise<boolean>}
   */
  async hasReachedJobLimit(userId, maxConcurrent = 5) {
    const pendingCount = await this.getPendingJobsCount(userId);
    return pendingCount >= maxConcurrent;
  }
}

module.exports = new JobService();
