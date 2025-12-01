/**
 * PDF Routes - handles PDF manipulation endpoints
 */

const express = require('express');
const router = express.Router();
const pdfController = require('../controllers/pdfController');
const { authenticate } = require('../middleware/auth');
const { body, param } = require('express-validator');
const { handleValidation, validateMongoId } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

/**
 * POST /api/pdf/merge
 * Merge multiple PDFs into one
 */
router.post(
  '/merge',
  [
    body('fileIds').isArray({ min: 2 }).withMessage('At least 2 PDF files required for merge'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    handleValidation,
  ],
  pdfController.mergePdfs
);

/**
 * POST /api/pdf/split
 * Split PDF by page ranges
 */
router.post(
  '/split',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('ranges').isArray({ min: 1 }).withMessage('At least one page range is required'),
    body('ranges.*.start').isInt({ min: 1 }).withMessage('Start page must be a positive integer'),
    body('ranges.*.end').isInt({ min: 1 }).withMessage('End page must be a positive integer'),
    handleValidation,
  ],
  pdfController.splitPdf
);

/**
 * POST /api/pdf/reorder
 * Reorder pages in a PDF
 */
router.post(
  '/reorder',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('pageOrder').isArray({ min: 1 }).withMessage('Page order array is required'),
    body('pageOrder.*').isInt({ min: 1 }).withMessage('Page numbers must be positive integers'),
    handleValidation,
  ],
  pdfController.reorderPages
);

/**
 * POST /api/pdf/extract-text
 * Extract text content from PDF
 */
router.post(
  '/extract-text',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    handleValidation,
  ],
  pdfController.extractText
);

/**
 * POST /api/pdf/extract-images
 * Extract images from PDF pages
 */
router.post(
  '/extract-images',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    handleValidation,
  ],
  pdfController.extractImages
);

/**
 * POST /api/pdf/compress
 * Compress PDF to reduce file size
 */
router.post(
  '/compress',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('quality').optional().isIn(['low', 'medium', 'high']).withMessage('Quality must be low, medium, or high'),
    handleValidation,
  ],
  pdfController.compressPdf
);

/**
 * GET /api/pdf/:id/info
 * Get PDF metadata and information
 */
router.get(
  '/:id/info',
  validateMongoId('id'),
  pdfController.getPdfInfo
);

/**
 * POST /api/pdf/watermark
 * Add watermark text to PDF
 */
router.post(
  '/watermark',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('text').notEmpty().trim().isLength({ min: 1, max: 100 }).withMessage('Watermark text is required (max 100 chars)'),
    body('opacity').optional().isFloat({ min: 0.1, max: 1.0 }).withMessage('Opacity must be between 0.1 and 1.0'),
    body('fontSize').optional().isInt({ min: 10, max: 200 }).withMessage('Font size must be between 10 and 200'),
    handleValidation,
  ],
  pdfController.addWatermark
);

/**
 * POST /api/pdf/remove-pages
 * Remove specific pages from PDF
 */
router.post(
  '/remove-pages',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('pages').isArray({ min: 1 }).withMessage('Pages to remove array is required'),
    body('pages.*').isInt({ min: 1 }).withMessage('Page numbers must be positive integers'),
    handleValidation,
  ],
  pdfController.removePages
);

/**
 * POST /api/pdf/rotate-pages
 * Rotate specific pages in PDF
 */
router.post(
  '/rotate-pages',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    body('rotations').isObject().withMessage('Rotations object is required (pageNumber: degrees)'),
    handleValidation,
  ],
  pdfController.rotatePages
);

module.exports = router;
