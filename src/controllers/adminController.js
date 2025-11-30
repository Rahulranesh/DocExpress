/**
 * Admin Controller - handles administrative operations
 * All endpoints require admin role
 */

const authService = require('../services/authService');
const jobService = require('../services/jobService');
const noteService = require('../services/noteService');
const fileService = require('../services/fileService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse, paginatedResponse } = require('../utils/response');
const Job = require('../models/Job');
const User = require('../models/User');
const File = require('../models/File');

/**
 * Get all users (paginated)
 * GET /api/admin/users
 */
const getAllUsers = catchAsync(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;

  const result = await authService.getAllUsers({
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
  });

  paginatedResponse(res, result.users, {
    page: result.page,
    limit: result.limit,
    total: result.total,
  });
});

/**
 * Get single user details
 * GET /api/admin/users/:id
 */
const getUserById = catchAsync(async (req, res) => {
  const user = await authService.getUserById(req.params.id);
  successResponse(res, { user });
});

/**
 * Get all jobs (paginated with filters)
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

  const result = await jobService.getAllJobs(options);

  paginatedResponse(res, result.jobs, result.pagination);
});

/**
 * Get job details for diagnostics
 * GET /api/admin/jobs/:id
 */
const getJobDetails = catchAsync(async (req, res) => {
  const job = await Job.findById(req.params.id)
    .populate('userId', 'name email')
    .populate('inputFiles')
    .populate('outputFiles');

  if (!job) {
    return successResponse(res, null, 'Job not found', 404);
  }

  successResponse(res, { job });
});

/**
 * Get all notes (read-only)
 * GET /api/admin/notes
 */
const getAllNotes = catchAsync(async (req, res) => {
  const { page = 1, limit = 20, userId } = req.query;

  const options = {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
  };

  if (userId) options.userId = userId;

  const result = await noteService.getAllNotes(options);

  paginatedResponse(res, result.notes, result.pagination);
});

/**
 * Get system statistics
 * GET /api/admin/stats
 */
const getSystemStats = catchAsync(async (req, res) => {
  const [
    totalUsers,
    totalJobs,
    totalFiles,
    jobsByStatus,
    jobsByType,
    recentUsers,
  ] = await Promise.all([
    User.countDocuments(),
    Job.countDocuments(),
    File.countDocuments({ isDeleted: false }),
    Job.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
    Job.aggregate([
      { $group: { _id: '$type', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
    ]),
    User.countDocuments({
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
    }),
  ]);

  // Calculate storage usage
  const storageStats = await File.aggregate([
    { $match: { isDeleted: false } },
    {
      $group: {
        _id: '$fileType',
        count: { $sum: 1 },
        totalSize: { $sum: '$size' },
      },
    },
  ]);

  const stats = {
    users: {
      total: totalUsers,
      newThisWeek: recentUsers,
    },
    jobs: {
      total: totalJobs,
      byStatus: jobsByStatus.reduce((acc, s) => {
        acc[s._id] = s.count;
        return acc;
      }, {}),
      topTypes: jobsByType.map((t) => ({ type: t._id, count: t.count })),
    },
    files: {
      total: totalFiles,
      byType: storageStats.reduce((acc, s) => {
        acc[s._id] = { count: s.count, totalSize: s.totalSize };
        return acc;
      }, {}),
      totalStorage: storageStats.reduce((sum, s) => sum + s.totalSize, 0),
    },
  };

  successResponse(res, { stats });
});

/**
 * Get users with their job counts
 * GET /api/admin/users/with-stats
 */
const getUsersWithStats = catchAsync(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  const [users, total] = await Promise.all([
    User.aggregate([
      {
        $lookup: {
          from: 'jobs',
          localField: '_id',
          foreignField: 'userId',
          as: 'jobs',
        },
      },
      {
        $lookup: {
          from: 'files',
          localField: '_id',
          foreignField: 'owner',
          as: 'files',
        },
      },
      {
        $project: {
          name: 1,
          email: 1,
          role: 1,
          createdAt: 1,
          jobCount: { $size: '$jobs' },
          fileCount: {
            $size: {
              $filter: {
                input: '$files',
                cond: { $eq: ['$$this.isDeleted', false] },
              },
            },
          },
        },
      },
      { $sort: { createdAt: -1 } },
      { $skip: skip },
      { $limit: parseInt(limit, 10) },
    ]),
    User.countDocuments(),
  ]);

  paginatedResponse(res, users, {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    total,
  });
});

/**
 * Cleanup old jobs
 * POST /api/admin/cleanup/jobs
 */
const cleanupOldJobs = catchAsync(async (req, res) => {
  const { maxAgeDays = 30 } = req.body;

  const result = await jobService.cleanupOldJobs(maxAgeDays);

  successResponse(res, result, `Cleaned up ${result.deleted} old jobs`);
});

/**
 * Get failed jobs for review
 * GET /api/admin/jobs/failed
 */
const getFailedJobs = catchAsync(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);

  const [jobs, total] = await Promise.all([
    Job.find({ status: 'FAILED' })
      .populate('userId', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit, 10)),
    Job.countDocuments({ status: 'FAILED' }),
  ]);

  paginatedResponse(res, jobs, {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    total,
  });
});

module.exports = {
  getAllUsers,
  getUserById,
  getAllJobs,
  getJobDetails,
  getAllNotes,
  getSystemStats,
  getUsersWithStats,
  cleanupOldJobs,
  getFailedJobs,
};
