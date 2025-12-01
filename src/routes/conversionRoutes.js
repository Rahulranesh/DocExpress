/**
 * Conversion Routes - handles image and document conversion endpoints
 */

const express = require('express');
const router = express.Router();
const conversionController = require('../controllers/conversionController');
const { authenticate } = require('../middleware/auth');
const { body } = require('express-validator');
const { handleValidation } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

// Image to document conversions

/**
 * POST /api/convert/images-to-pdf
 * Convert multiple images to a single PDF
 */
router.post(
  '/images-to-pdf',
  [
    body('fileIds').isArray({ min: 1 }).withMessage('At least one image file ID is required'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    body('pageSize').optional().isIn(['A4', 'Letter', 'Legal']).withMessage('Invalid page size'),
    handleValidation,
  ],
  conversionController.imagesToPdf
);

/**
 * POST /api/convert/images-to-pptx
 * Convert multiple images to a PPTX (each image = one slide)
 */
router.post(
  '/images-to-pptx',
  [
    body('fileIds').isArray({ min: 1 }).withMessage('At least one image file ID is required'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    handleValidation,
  ],
  conversionController.imagesToPptx
);

/**
 * POST /api/convert/images-to-docx
 * Convert multiple images to a DOCX document
 */
router.post(
  '/images-to-docx',
  [
    body('fileIds').isArray({ min: 1 }).withMessage('At least one image file ID is required'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    body('title').optional().isString().trim().isLength({ max: 200 }),
    handleValidation,
  ],
  conversionController.imagesToDocx
);

/**
 * POST /api/convert/image-to-text
 * Extract text from image using OCR
 */
router.post(
  '/image-to-text',
  [
    body('fileId').isMongoId().withMessage('Valid image file ID is required'),
    handleValidation,
  ],
  conversionController.imageToText
);

// Image format conversions

/**
 * POST /api/convert/image-format
 * Convert image to different format (JPEG, PNG, WEBP, etc.)
 */
router.post(
  '/image-format',
  [
    body('fileId').isMongoId().withMessage('Valid file ID is required'),
    body('targetFormat')
      .notEmpty()
      .withMessage('Target format is required')
      .isIn(['jpeg', 'jpg', 'png', 'webp', 'tiff', 'gif'])
      .withMessage('Invalid target format'),
    body('quality').optional().isInt({ min: 1, max: 100 }).withMessage('Quality must be 1-100'),
    handleValidation,
  ],
  conversionController.convertImageFormat
);

/**
 * POST /api/convert/image-transform
 * Apply transforms to image (resize, rotate, crop, grayscale)
 */
router.post(
  '/image-transform',
  [
    body('fileId').isMongoId().withMessage('Valid file ID is required'),
    body('operations').isArray({ min: 1 }).withMessage('At least one operation is required'),
    body('operations.*.type')
      .isIn(['resize', 'rotate', 'crop', 'grayscale', 'flip', 'flop', 'blur', 'sharpen', 'negate'])
      .withMessage('Invalid operation type'),
    body('operations.*.options').optional().isObject(),
    body('format').optional().isIn(['jpeg', 'jpg', 'png', 'webp']),
    body('quality').optional().isInt({ min: 1, max: 100 }),
    handleValidation,
  ],
  conversionController.transformImage
);

/**
 * POST /api/convert/merge-images
 * Merge multiple images into one (horizontal or vertical)
 */
router.post(
  '/merge-images',
  [
    body('fileIds').isArray({ min: 2 }).withMessage('At least 2 images required for merge'),
    body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
    body('direction').optional().isIn(['horizontal', 'vertical']).withMessage('Direction must be horizontal or vertical'),
    body('format').optional().isIn(['jpeg', 'jpg', 'png', 'webp']),
    body('quality').optional().isInt({ min: 1, max: 100 }),
    body('gap').optional().isInt({ min: 0, max: 100 }),
    handleValidation,
  ],
  conversionController.mergeImages
);

// Document conversions

/**
 * POST /api/convert/pdf-to-docx
 * Convert PDF to DOCX
 */
router.post(
  '/pdf-to-docx',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    handleValidation,
  ],
  conversionController.pdfToDocx
);

/**
 * POST /api/convert/pdf-to-pptx
 * Convert PDF to PPTX
 */
router.post(
  '/pdf-to-pptx',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    handleValidation,
  ],
  conversionController.pdfToPptx
);

/**
 * POST /api/convert/pdf-to-text
 * Extract text from PDF
 */
router.post(
  '/pdf-to-text',
  [
    body('fileId').isMongoId().withMessage('Valid PDF file ID is required'),
    handleValidation,
  ],
  conversionController.pdfToText
);

/**
 * POST /api/convert/docx-to-pdf
 * Convert DOCX to PDF
 */
router.post(
  '/docx-to-pdf',
  [
    body('fileId').isMongoId().withMessage('Valid DOCX file ID is required'),
    handleValidation,
  ],
  conversionController.docxToPdf
);

/**
 * POST /api/convert/pptx-to-pdf
 * Convert PPTX to PDF
 */
router.post(
  '/pptx-to-pdf',
  [
    body('fileId').isMongoId().withMessage('Valid PPTX file ID is required'),
    handleValidation,
  ],
  conversionController.pptxToPdf
);

module.exports = router;
