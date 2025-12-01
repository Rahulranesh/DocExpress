const { validationResult, body, param, query } = require('express-validator');
const AppError = require('../utils/AppError');

// Middleware to check validation results
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map((err) => err.msg);
    return next(AppError.badRequest(messages.join(', '), 'VALIDATION_ERROR'));
  }
  next();
};

// Auth validators
const validateRegister = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be 2-100 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Invalid email format')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  handleValidation,
];

const validateLogin = [
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Invalid email format')
    .normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidation,
];

// Note validators
const validateCreateNote = [
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ max: 200 })
    .withMessage('Title cannot exceed 200 characters'),
  body('content')
    .optional()
    .isString()
    .isLength({ max: 50000 })
    .withMessage('Content cannot exceed 50000 characters'),
  body('tags')
    .optional()
    .isArray({ max: 20 })
    .withMessage('Tags must be an array with max 20 items'),
  body('tags.*').optional().isString().trim().isLength({ max: 50 }),
  body('pinned').optional().isBoolean().withMessage('Pinned must be a boolean'),
  handleValidation,
];

const validateUpdateNote = [
  param('id').isMongoId().withMessage('Invalid note ID'),
  body('title')
    .optional()
    .trim()
    .isLength({ min: 1, max: 200 })
    .withMessage('Title must be 1-200 characters'),
  body('content')
    .optional()
    .isString()
    .isLength({ max: 50000 })
    .withMessage('Content cannot exceed 50000 characters'),
  body('tags')
    .optional()
    .isArray({ max: 20 })
    .withMessage('Tags must be an array with max 20 items'),
  body('tags.*').optional().isString().trim().isLength({ max: 50 }),
  body('pinned').optional().isBoolean().withMessage('Pinned must be a boolean'),
  handleValidation,
];

// File validators
const validateFileId = [
  param('id').isMongoId().withMessage('Invalid file ID'),
  handleValidation,
];

// Job validators
const validateJobId = [
  param('id').isMongoId().withMessage('Invalid job ID'),
  handleValidation,
];

// Pagination validators
const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer')
    .toInt(),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be 1-100')
    .toInt(),
  handleValidation,
];

// Image conversion validators
const validateImageConvert = [
  body('format')
    .notEmpty()
    .withMessage('Target format is required')
    .isIn(['jpeg', 'jpg', 'png', 'webp', 'tiff', 'gif'])
    .withMessage('Invalid target format'),
  body('quality')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Quality must be 1-100'),
  handleValidation,
];

// Image transform validators
const validateImageTransform = [
  body('operations').isArray({ min: 1 }).withMessage('Operations array required'),
  body('operations.*.type')
    .isIn(['resize', 'rotate', 'crop', 'grayscale'])
    .withMessage('Invalid operation type'),
  body('operations.*.options').optional().isObject(),
  handleValidation,
];

// Video compression validators
const validateVideoCompress = [
  body('preset')
    .optional()
    .isIn(['low', 'medium', 'high'])
    .withMessage('Preset must be low, medium, or high'),
  body('resolution')
    .optional()
    .isIn(['480p', '720p', '1080p'])
    .withMessage('Invalid resolution'),
  handleValidation,
];

// PDF operations validators
const validatePdfMerge = [
  body('fileIds')
    .isArray({ min: 2 })
    .withMessage('At least 2 files required for merge'),
  body('fileIds.*').isMongoId().withMessage('Invalid file ID'),
  handleValidation,
];

const validatePdfSplit = [
  body('fileId').isMongoId().withMessage('Invalid file ID'),
  body('ranges')
    .isArray({ min: 1 })
    .withMessage('At least one page range required'),
  body('ranges.*.start')
    .isInt({ min: 1 })
    .withMessage('Start page must be positive'),
  body('ranges.*.end')
    .isInt({ min: 1 })
    .withMessage('End page must be positive'),
  handleValidation,
];

const validatePdfReorder = [
  body('fileId').isMongoId().withMessage('Invalid file ID'),
  body('pageOrder')
    .isArray({ min: 1 })
    .withMessage('Page order array required'),
  body('pageOrder.*')
    .isInt({ min: 1 })
    .withMessage('Page numbers must be positive'),
  handleValidation,
];

// MongoId param validator
const validateMongoId = (paramName = 'id') => [
  param(paramName).isMongoId().withMessage(`Invalid ${paramName}`),
  handleValidation,
];

module.exports = {
  handleValidation,
  validateRegister,
  validateLogin,
  validateCreateNote,
  validateUpdateNote,
  validateFileId,
  validateJobId,
  validatePagination,
  validateImageConvert,
  validateImageTransform,
  validateVideoCompress,
  validatePdfMerge,
  validatePdfSplit,
  validatePdfReorder,
  validateMongoId,
};
