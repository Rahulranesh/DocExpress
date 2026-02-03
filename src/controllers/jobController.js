/**
 * Jobs Controller - handles job management and history
 */

const jobService = require('../services/jobService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse, paginatedResponse } = require('../utils/response');
const { JOB_TYPES, JOB_STATUS } = require('../utils/constants');

/**
 * Get all jobs for current user
 * GET /api/jobs
 */
const getUserJobs = catchAsync(async (req, res) => {
  const { page = 1, limit = 20, type, status, sortBy, sortOrder } = req.query;

  const options = {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    sortBy: sortBy || 'createdAt',
    sortOrder: sortOrder === 'asc' ? 1 : -1,
  };

  if (type) options.type = type;
  if (status) options.status = status;

  const { jobs, pagination } = await jobService.getUserJobs(req.userId, options);
  paginatedResponse(res, jobs, pagination);
});

/**
 * Get single job by ID
 * GET /api/jobs/:id
 */
const getJob = catchAsync(async (req, res) => {
  const job = await jobService.getJobById(req.params.id, req.userId);
  successResponse(res, { job });
});

/**
 * Get recent jobs for current user
 * GET /api/jobs/recent
 */
const getRecentJobs = catchAsync(async (req, res) => {
  const { limit = 10 } = req.query;
  const jobs = await jobService.getRecentJobs(req.userId, parseInt(limit, 10));
  successResponse(res, { jobs });
});

/**
 * Get job statistics for current user
 * GET /api/jobs/stats
 */
const getJobStats = catchAsync(async (req, res) => {
  const stats = await jobService.getUserJobStats(req.userId);
  successResponse(res, { stats });
});

/**
 * Cancel a pending job
 * POST /api/jobs/:id/cancel
 */
const cancelJob = catchAsync(async (req, res) => {
  const job = await jobService.cancelJob(req.params.id, req.userId);
  successResponse(res, { job }, 'Job cancelled successfully');
});

/**
 * Retry a failed job
 * POST /api/jobs/:id/retry
 */
const retryJob = catchAsync(async (req, res) => {
  const job = await jobService.retryJob(req.params.id, req.userId);
  successResponse(res, { job }, 'Job queued for retry', 201);
});

/**
 * Delete a job
 * DELETE /api/jobs/:id
 */
const deleteJob = catchAsync(async (req, res) => {
  console.log('🗑️ Delete job request for:', req.params.id, 'by user:', req.userId);
  await jobService.deleteJob(req.params.id, req.userId);
  console.log('🗑️ Job deleted successfully');
  successResponse(res, { deleted: true }, 'Job deleted successfully');
});

/**
 * Get available job types
 * GET /api/jobs/types
 */
const getJobTypes = catchAsync(async (req, res) => {
  const types = Object.values(JOB_TYPES);
  const statuses = Object.values(JOB_STATUS);

  successResponse(res, {
    types,
    statuses,
  });
});

/**
 * Get pending jobs count for current user
 * GET /api/jobs/pending-count
 */
const getPendingCount = catchAsync(async (req, res) => {
  const count = await jobService.getPendingJobsCount(req.userId);
  successResponse(res, { pendingCount: count });
});

/**
 * Check if user has reached job limit
 * GET /api/jobs/check-limit
 */
const checkJobLimit = catchAsync(async (req, res) => {
  const maxConcurrent = parseInt(process.env.MAX_CONCURRENT_JOBS, 10) || 5;
  const hasReachedLimit = await jobService.hasReachedJobLimit(req.userId, maxConcurrent);

  successResponse(res, {
    hasReachedLimit,
    maxConcurrent,
  });
});

// Admin endpoints

/**
 * Get all jobs (admin)
 * GET /api/admin/jobs
 */
const getAllJobs = catchAsync(async (req, res) => {
  const { page = 1, limit = 20, type, status, userId, sortBy, sortOrder } = req.query;

  const options = {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    sortBy: sortBy || 'createdAt',
    sortOrder: sortOrder === 'asc' ? 1 : -1,
  };

  if (type) options.type = type;
  if (status) options.status = status;
  if (userId) options.userId = userId;

  const { jobs, pagination } = await jobService.getAllJobs(options);
  paginatedResponse(res, jobs, pagination);
});

/**
 * Get job by ID (admin - no ownership check)
 * GET /api/admin/jobs/:id
 */
const getJobAdmin = catchAsync(async (req, res) => {
  const job = await jobService.getJobById(req.params.id);
  successResponse(res, { job });
});

/**
 * Cleanup old jobs (admin)
 * POST /api/admin/jobs/cleanup
 */
const cleanupOldJobs = catchAsync(async (req, res) => {
  const { maxAgeDays = 30 } = req.body;
  const result = await jobService.cleanupOldJobs(parseInt(maxAgeDays, 10));
  successResponse(res, result, `Cleaned up ${result.deleted} old jobs`);
});

module.exports = {
  getUserJobs,
  getJob,
  getRecentJobs,
  getJobStats,
  cancelJob,
  retryJob,
  deleteJob,
  getJobTypes,
  getPendingCount,
  checkJobLimit,
  // Admin
  getAllJobs,
  getJobAdmin,
  cleanupOldJobs,
};
