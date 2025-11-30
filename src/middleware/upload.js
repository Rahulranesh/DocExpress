const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const AppError = require('../utils/AppError');
const { isAllowedMimeType, FILE_SIZE_LIMITS, getFileTypeFromMime } = require('../utils/constants');

// Get storage root from environment
const getStorageRoot = () => {
  const root = process.env.STORAGE_ROOT || './uploads';
  // Ensure directory exists
  if (!fs.existsSync(root)) {
    fs.mkdirSync(root, { recursive: true });
  }
  return root;
};

// Generate unique filename
const generateFilename = (originalname) => {
  const ext = path.extname(originalname).toLowerCase();
  const uniqueId = uuidv4();
  const timestamp = Date.now();
  return `${timestamp}-${uniqueId}${ext}`;
};

// Configure disk storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const storageRoot = getStorageRoot();
    const fileType = getFileTypeFromMime(file.mimetype);

    // Organize by file type subdirectory
    const destDir = path.join(storageRoot, fileType);

    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir, { recursive: true });
    }

    cb(null, destDir);
  },
  filename: (req, file, cb) => {
    const filename = generateFilename(file.originalname);
    cb(null, filename);
  },
});

// File filter
const fileFilter = (req, file, cb) => {
  if (isAllowedMimeType(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new AppError.unsupportedMedia(`File type ${file.mimetype} is not supported`), false);
  }
};

// Get max file size based on MIME type
const getMaxFileSize = (mimeType) => {
  const fileType = getFileTypeFromMime(mimeType);

  switch (fileType) {
    case 'video':
      return FILE_SIZE_LIMITS.VIDEO;
    case 'image':
      return FILE_SIZE_LIMITS.IMAGE;
    case 'document':
    case 'pdf':
      return FILE_SIZE_LIMITS.DOCUMENT;
    default:
      return FILE_SIZE_LIMITS.DEFAULT;
  }
};

// Default upload configuration
const defaultMaxSize = parseInt(process.env.MAX_FILE_SIZE, 10) || FILE_SIZE_LIMITS.DEFAULT;

// Base multer instance
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: defaultMaxSize,
    files: 20, // Max files per request
  },
});

// Upload middleware for single file
const uploadSingle = (fieldName = 'file') => upload.single(fieldName);

// Upload middleware for multiple files (same field)
const uploadMultiple = (fieldName = 'files', maxCount = 10) => upload.array(fieldName, maxCount);

// Upload middleware for multiple fields
const uploadFields = (fields) => upload.fields(fields);

// Custom upload with type-specific limits
const uploadWithLimits = (options = {}) => {
  const { fieldName = 'file', maxCount = 1, maxSize = defaultMaxSize } = options;

  const customUpload = multer({
    storage,
    fileFilter,
    limits: {
      fileSize: maxSize,
      files: maxCount,
    },
  });

  if (maxCount === 1) {
    return customUpload.single(fieldName);
  }
  return customUpload.array(fieldName, maxCount);
};

// Memory storage for smaller files that need immediate processing
const memoryStorage = multer.memoryStorage();

const uploadToMemory = multer({
  storage: memoryStorage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB for memory uploads
    files: 5,
  },
});

// Helper to attach file info to request
const attachFileInfo = (req, res, next) => {
  if (req.file) {
    req.file.storageKey = path.join(getFileTypeFromMime(req.file.mimetype), req.file.filename);
    req.file.fileType = getFileTypeFromMime(req.file.mimetype);
  }
  if (req.files) {
    const files = Array.isArray(req.files) ? req.files : Object.values(req.files).flat();
    files.forEach((file) => {
      file.storageKey = path.join(getFileTypeFromMime(file.mimetype), file.filename);
      file.fileType = getFileTypeFromMime(file.mimetype);
    });
  }
  next();
};

// Error handler for multer errors
const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return next(AppError.tooLarge('File size exceeds the maximum allowed limit'));
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return next(AppError.badRequest('Too many files uploaded'));
    }
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      return next(AppError.badRequest('Unexpected field name for file upload'));
    }
    return next(AppError.badRequest(`Upload error: ${err.message}`));
  }
  next(err);
};

module.exports = {
  upload,
  uploadSingle,
  uploadMultiple,
  uploadFields,
  uploadWithLimits,
  uploadToMemory,
  attachFileInfo,
  handleUploadError,
  generateFilename,
  getStorageRoot,
};
