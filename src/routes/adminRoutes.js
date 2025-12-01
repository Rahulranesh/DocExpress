/**
 * Admin Routes - administrative endpoints (requires admin role)
 */

const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const jobController = require('../controllers/jobController');
const { authenticate, requireAdmin } = require('../middleware/auth');
const { validatePagination, validateMongoId } = require('../middleware/validate');

// All routes require authentication and admin role
router.use(authenticate);
router.use(requireAdmin);

// System statistics
router.get('/stats', adminController.getSystemStats);

// User management
router.get('/users', validatePagination, adminController.getAllUsers);
router.get('/users/with-stats', validatePagination, adminController.getUsersWithStats);
router.get('/users/:id', validateMongoId('id'), adminController.getUserById);

// Job management
router.get('/jobs', validatePagination, adminController.getAllJobs);
router.get('/jobs/failed', validatePagination, adminController.getFailedJobs);
router.get('/jobs/:id', validateMongoId('id'), adminController.getJobDetails);

// Notes (read-only)
router.get('/notes', validatePagination, adminController.getAllNotes);

// Cleanup operations
router.post('/cleanup/jobs', adminController.cleanupOldJobs);

module.exports = router;
