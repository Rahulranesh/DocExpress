// Job type constants
const JOB_TYPES = {
  // Image conversions
  IMAGE_TO_PDF: 'IMAGE_TO_PDF',
  IMAGE_TO_PPTX: 'IMAGE_TO_PPTX',
  IMAGE_TO_DOCX: 'IMAGE_TO_DOCX',
  IMAGE_TO_TXT: 'IMAGE_TO_TXT',
  IMAGE_FORMAT_CONVERT: 'IMAGE_FORMAT_CONVERT',
  IMAGE_TRANSFORM: 'IMAGE_TRANSFORM',
  IMAGE_MERGE: 'IMAGE_MERGE',

  // Document conversions
  PDF_TO_PPTX: 'PDF_TO_PPTX',
  PDF_TO_DOCX: 'PDF_TO_DOCX',
  PDF_TO_TXT: 'PDF_TO_TXT',
  PPTX_TO_PDF: 'PPTX_TO_PDF',
  DOCX_TO_PDF: 'DOCX_TO_PDF',

  // PDF operations
  PDF_MERGE: 'PDF_MERGE',
  PDF_SPLIT: 'PDF_SPLIT',
  PDF_REORDER: 'PDF_REORDER',
  PDF_EXTRACT_IMAGES: 'PDF_EXTRACT_IMAGES',
  PDF_EXTRACT_TEXT: 'PDF_EXTRACT_TEXT',

  // Compression
  COMPRESS_IMAGE: 'COMPRESS_IMAGE',
  COMPRESS_VIDEO: 'COMPRESS_VIDEO',
  COMPRESS_PDF: 'COMPRESS_PDF',
};

// Job status constants
const JOB_STATUS = {
  PENDING: 'PENDING',
  RUNNING: 'RUNNING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
};

// File type classifications
const FILE_TYPES = {
  IMAGE: 'image',
  PDF: 'pdf',
  VIDEO: 'video',
  DOCUMENT: 'document',
  TEXT: 'text',
  OTHER: 'other',
};

// Supported MIME types by category
const MIME_TYPES = {
  IMAGE: [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/gif',
    'image/bmp',
    'image/tiff',
  ],
  PDF: ['application/pdf'],
  VIDEO: [
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'video/x-msvideo',
    'video/webm',
    'video/x-matroska',
  ],
  DOCUMENT: [
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // .docx
    'application/msword', // .doc
    'application/vnd.openxmlformats-officedocument.presentationml.presentation', // .pptx
    'application/vnd.ms-powerpoint', // .ppt
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
    'application/vnd.ms-excel', // .xls
  ],
  TEXT: ['text/plain'],
};

// Supported image formats for conversion
const IMAGE_FORMATS = {
  JPEG: 'jpeg',
  JPG: 'jpg',
  PNG: 'png',
  WEBP: 'webp',
  HEIC: 'heic',
  GIF: 'gif',
  TIFF: 'tiff',
};

// Video compression presets
const VIDEO_PRESETS = {
  LOW: {
    name: 'low',
    resolution: '480p',
    videoBitrate: '500k',
    audioBitrate: '64k',
    width: 854,
    height: 480,
  },
  MEDIUM: {
    name: 'medium',
    resolution: '720p',
    videoBitrate: '1500k',
    audioBitrate: '128k',
    width: 1280,
    height: 720,
  },
  HIGH: {
    name: 'high',
    resolution: '1080p',
    videoBitrate: '3000k',
    audioBitrate: '192k',
    width: 1920,
    height: 1080,
  },
};

// Image quality presets
const IMAGE_QUALITY = {
  LOW: 30,
  MEDIUM: 60,
  HIGH: 80,
  ORIGINAL: 100,
};

// User roles
const USER_ROLES = {
  USER: 'user',
  ADMIN: 'admin',
};

// File size limits (in bytes)
const FILE_SIZE_LIMITS = {
  IMAGE: 20 * 1024 * 1024, // 20MB
  VIDEO: 500 * 1024 * 1024, // 500MB
  DOCUMENT: 50 * 1024 * 1024, // 50MB
  DEFAULT: 50 * 1024 * 1024, // 50MB
};

// Pagination defaults
const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 20,
  MAX_LIMIT: 100,
};

// Helper to get file type from MIME
const getFileTypeFromMime = (mimeType) => {
  if (MIME_TYPES.IMAGE.includes(mimeType)) return FILE_TYPES.IMAGE;
  if (MIME_TYPES.PDF.includes(mimeType)) return FILE_TYPES.PDF;
  if (MIME_TYPES.VIDEO.includes(mimeType)) return FILE_TYPES.VIDEO;
  if (MIME_TYPES.DOCUMENT.includes(mimeType)) return FILE_TYPES.DOCUMENT;
  if (MIME_TYPES.TEXT.includes(mimeType)) return FILE_TYPES.TEXT;
  return FILE_TYPES.OTHER;
};

// Helper to validate allowed MIME types
const isAllowedMimeType = (mimeType) => {
  const allAllowed = [
    ...MIME_TYPES.IMAGE,
    ...MIME_TYPES.PDF,
    ...MIME_TYPES.VIDEO,
    ...MIME_TYPES.DOCUMENT,
    ...MIME_TYPES.TEXT,
  ];
  return allAllowed.includes(mimeType);
};

module.exports = {
  JOB_TYPES,
  JOB_STATUS,
  FILE_TYPES,
  MIME_TYPES,
  IMAGE_FORMATS,
  VIDEO_PRESETS,
  IMAGE_QUALITY,
  USER_ROLES,
  FILE_SIZE_LIMITS,
  PAGINATION,
  getFileTypeFromMime,
  isAllowedMimeType,
};
