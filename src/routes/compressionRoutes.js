/**
 * Compression Routes - handles image, video, and PDF compression endpoints
 */

const express = require('express');
const router = express.Router();
const compressionController = require('../controllers/compressionController');
const { authenticate } = require('../middleware/auth');
const { body, param } = require('express-validator');
const { handleValidation, validateMongoId } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/compress/presets
 * Get available compression presets for all types
 */
router.get('/presets', compressionController.getPresets);

// Image compression routes

/**
 * POST /api/compress/image
 * Compress a single image
 */
router.post(
  '/image',
  [
    body('fileId').isMongoId().withMessage('Valid image file ID is required'),
    body('quality').optional().isInt({ min: 1, max: 100 }).withMessage('Quality must be 1-100'),
    body('maxWidth').optional().isInt({ min: 1, max: 10000 }).withMessage('Invalid max width'),
    body('maxHeight').optional().isInt({ min: 1, max: 10000 }).withMessage('Invalid max height'),
    body('format').optional().isIn(['jpeg', 'jpg', 'png', 'webp']).withMessage('Invalid output format'),
    handleValidation,
  ],
  compressionController.compressImage
);

/**
 * POST /api/compress/images
 * Compress multiple images (batch)
 */
router.post(
  '/images',
  [
    body('fileIds').isArray({ min: 1 }).withMessage('At least one image file ID is required'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    body('quality').optional().isInt({ min: 1, max: 100 }).withMessage('Quality must be 1-100'),
    body('maxWidth').optional().isInt({ min: 1, max: 10000 }).withMessage('Invalid max width'),
    body('maxHeight').optional().isInt({ min: 1, max: 10000 }).withMessage('Invalid max height'),
    body('format').optional().isIn(['jpeg', 'jpg', 'png', 'webp']).withMessage('Invalid output format'),
    handleValidation,
  ],
  compressionController.compressImages
);

// Video compression routes

/**
 * POST /api/compress/video
 * Compress a video with preset or custom settings
 */
router.post(
  '/video',
  [
    body('fileId').isMongoId().withMessage('Valid video file ID is required'),
    body('preset').optional().isIn(['low', 'medium', 'high']).withMessage('Invalid preset'),
    body('resolution').optional().isIn(['480p', '720p', '1080p']).withMessage('Invalid resolution'),
    body('customBitrate').optional().isString().withMessage('Bitrate must be a string (e.g., "1500k")'),
    handleValidation,
  ],
  compressionController.compressVideo
);

/**
 * POST /api/compress/video/resolution
 * Compress video to specific resolution
 */
router.post(
  '/video/resolution',
  [
    body('fileId').isMongoId().withMessage('Valid video file ID is required'),
    body('resolution')
      .notEmpty()
      .withMessage('Resolution is required')
      .isIn(['480p', '720p', '1080p'])
      .withMessage('Invalid resolution'),
    handleValidation,
  ],
  compressionController.compressVideoToResolution
);

/**
 * GET /api/compress/video/:id/info
 * Get video metadata/info
 */
router.get(
  '/video/:id/info',
  validateMongoId('id'),
  compressionController.getVideoInfo
);

/**
 * POST /api/compress/video/thumbnail
 * Extract thumbnail from video
 */
router.post(
  '/video/thumbnail',
  [
    body('fileId').isMongoId().withMessage('Valid video file ID is required'),
    body('timestamp').optional().isString().withMessage('Timestamp must be a string (e.g., "00:00:05")'),
    body('width').optional().isInt({ min: 50, max: 1920 }).withMessage('Width must be 50-1920'),
    body('height').optional().isInt({ min: 50, max: 1080 }).withMessage('Height must be 50-1080'),
    handleValidation,
  ],
  compressionController.extractVideoThumbnail
);

/**
 * POST /api/compress/video/extract-audio
 * Extract audio from video
 */
router.post(
  '/video/extract-audio',
  [
    body('fileId').isMongoId().withMessage('Valid video file ID is required'),
    body('format').optional().isIn(['mp3', 'aac', 'wav']).withMessage('Invalid audio format'),
    body('bitrate').optional().isString().withMessage('Bitrate must be a string (e.g., "192k")'),
    handleValidation,
  ],
  compressionController.extractVideoAudio
);

// PDF compression routes

/**
 * POST /api/compress/pdf
 * Compress a PDF file
 */
router.post(
  '/pdf',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('quality').optional().isIn(['low', 'medium', 'high']).withMessage('Invalid quality preset'),
    handleValidation,
  ],
  compressionController.compressPdf
);

module.exports = router;
