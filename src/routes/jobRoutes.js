/**
 * Jobs Routes - handles job management and history
 */

const express = require('express');
const router = express.Router();
const jobController = require('../controllers/jobController');
const { authenticate } = require('../middleware/auth');
const { validateJobId, validatePagination } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

// Get available job types and statuses
router.get('/types', jobController.getJobTypes);

// Get recent jobs for current user
router.get('/recent', jobController.getRecentJobs);

// Get job statistics for current user
router.get('/stats', jobController.getJobStats);

// Get pending jobs count
router.get('/pending-count', jobController.getPendingCount);

// Check if user has reached job limit
router.get('/check-limit', jobController.checkJobLimit);

// Get all jobs for current user (with pagination and filters)
router.get('/', validatePagination, jobController.getUserJobs);

// Get single job by ID
router.get('/:id', validateJobId, jobController.getJob);

// Cancel a pending job
router.post('/:id/cancel', validateJobId, jobController.cancelJob);

// Delete a job
router.delete('/:id', validateJobId, jobController.deleteJob);

// Retry a failed job
router.post('/:id/retry', validateJobId, jobController.retryJob);

module.exports = router;
