/**
 * File Routes - handles file uploads and management
 */

const express = require('express');
const router = express.Router();
const fileController = require('../controllers/fileController');
const { authenticate } = require('../middleware/auth');
const { uploadSingle, uploadMultiple, attachFileInfo, handleUploadError } = require('../middleware/upload');
const { validateFileId, validatePagination } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

// Upload routes
router.post(
  '/upload',
  uploadSingle('file'),
  handleUploadError,
  attachFileInfo,
  fileController.uploadSingle
);

router.post(
  '/upload-multiple',
  uploadMultiple('files', 10),
  handleUploadError,
  attachFileInfo,
  fileController.uploadMultiple
);

// File listing and stats
router.get('/', validatePagination, fileController.listFiles);
router.get('/stats', fileController.getFileStats);

// Batch operations
router.post('/batch', fileController.getFilesByIds);

// Single file operations
router.get('/:id', validateFileId, fileController.getFile);
router.get('/:id/download', validateFileId, fileController.downloadFile);
router.delete('/:id', validateFileId, fileController.deleteFile);
router.delete('/:id/permanent', validateFileId, fileController.permanentDeleteFile);

// Download by storage key (for job outputs)
router.get('/download/:storageKey(*)', fileController.downloadByKey);

module.exports = router;
