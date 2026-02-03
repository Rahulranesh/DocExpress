/**
 * File Controller - handles file uploads and downloads
 */

const fileService = require('../services/fileService');
const storageService = require('../services/storageService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse, paginatedResponse } = require('../utils/response');
const AppError = require('../utils/AppError');
const path = require('path');
const fs = require('fs');

/**
 * Upload single file
 * POST /api/files/upload
 */
const uploadSingle = catchAsync(async (req, res) => {
  if (!req.file) {
    throw AppError.badRequest('No file uploaded');
  }

  const fileMeta = await fileService.createFileMeta(req.file, req.userId);

  successResponse(res, { file: fileMeta }, 'File uploaded successfully', 201);
});

/**
 * Upload multiple files
 * POST /api/files/upload-multiple
 */
const uploadMultiple = catchAsync(async (req, res) => {
  if (!req.files || req.files.length === 0) {
    throw AppError.badRequest('No files uploaded');
  }

  const files = await fileService.createMultipleFileMeta(req.files, req.userId);

  successResponse(res, { files, count: files.length }, 'Files uploaded successfully', 201);
});

/**
 * List user's files
 * GET /api/files
 */
const listFiles = catchAsync(async (req, res) => {
  const { page = 1, limit = 20, fileType, sortBy, sortOrder } = req.query;

  const result = await fileService.listUserFiles(req.userId, {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    fileType,
    sortBy,
    sortOrder: sortOrder === 'asc' ? 1 : -1,
  });

  paginatedResponse(res, result.files, result.pagination);
});

/**
 * Get single file metadata
 * GET /api/files/:id
 */
const getFile = catchAsync(async (req, res) => {
  const file = await fileService.getFileById(req.params.id, req.userId);
  successResponse(res, { file });
});

/**
 * Download file by ID
 * GET /api/files/:id/download
 */
const downloadFile = catchAsync(async (req, res) => {
  const file = await fileService.getFileById(req.params.id, req.userId);

  // Security check: ensure path is within storage root
  const fullPath = fileService.getFullPath(file);
  const normalizedPath = path.normalize(fullPath);
  const storageRoot = path.resolve(process.env.STORAGE_ROOT || './uploads');

  if (!normalizedPath.startsWith(storageRoot)) {
    throw AppError.forbidden('Invalid file path');
  }

  // Check file exists
  if (!fs.existsSync(fullPath)) {
    throw AppError.notFound('File not found on disk');
  }

  // Set headers for download
  res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(file.originalName)}"`);
  res.setHeader('Content-Type', file.mimeType);
  res.setHeader('Content-Length', file.size);

  // Stream file
  const readStream = fs.createReadStream(fullPath);
  readStream.pipe(res);
});

/**
 * Download file by storage key (for job outputs)
 * GET /api/files/download/:storageKey
 */
const downloadByKey = catchAsync(async (req, res) => {
  const storageKey = decodeURIComponent(req.params.storageKey);

  // Security: prevent directory traversal
  if (storageKey.includes('..')) {
    throw AppError.forbidden('Invalid file path');
  }

  const fullPath = storageService.getFullPath(storageKey);

  if (!fs.existsSync(fullPath)) {
    throw AppError.notFound('File not found');
  }

  // Get filename from path
  const filename = path.basename(fullPath);

  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.setHeader('Content-Type', 'application/octet-stream');

  const readStream = fs.createReadStream(fullPath);
  readStream.pipe(res);
});

/**
 * Delete file (hard delete)
 * DELETE /api/files/:id
 */
const deleteFile = catchAsync(async (req, res) => {
  console.log('🗑️ Delete file request for:', req.params.id, 'by user:', req.userId);
  const result = await fileService.hardDeleteFile(req.params.id, req.userId);
  console.log('🗑️ Delete file result:', result);
  successResponse(res, result, 'File deleted successfully');
});

/**
 * Hard delete file (permanent)
 * DELETE /api/files/:id/permanent
 */
const permanentDeleteFile = catchAsync(async (req, res) => {
  const result = await fileService.hardDeleteFile(req.params.id, req.userId);
  successResponse(res, result, 'File permanently deleted');
});

/**
 * Get user's file statistics
 * GET /api/files/stats
 */
const getFileStats = catchAsync(async (req, res) => {
  const stats = await fileService.getUserFileStats(req.userId);
  successResponse(res, { stats });
});

/**
 * Get files by IDs (for batch operations)
 * POST /api/files/batch
 */
const getFilesByIds = catchAsync(async (req, res) => {
  const { fileIds } = req.body;

  if (!fileIds || !Array.isArray(fileIds) || fileIds.length === 0) {
    throw AppError.badRequest('File IDs array required');
  }

  const files = await fileService.getFilesByIds(fileIds, req.userId);
  successResponse(res, { files });
});

/**
 * Rename file
 * PATCH /api/files/:id/rename
 */
const renameFile = catchAsync(async (req, res) => {
  const { newName } = req.body;

  if (!newName || typeof newName !== 'string' || newName.trim().length === 0) {
    throw AppError.badRequest('New name is required');
  }

  const file = await fileService.updateFileMeta(req.params.id, req.userId, {
    originalName: newName.trim(),
  });

  successResponse(res, { file }, 'File renamed successfully');
});

/**
 * Toggle favorite status
 * PATCH /api/files/:id/favorite
 */
const toggleFavorite = catchAsync(async (req, res) => {
  const file = await fileService.getFileById(req.params.id, req.userId);
  file.isFavorite = !file.isFavorite;
  await file.save();

  successResponse(res, { file }, file.isFavorite ? 'Added to favorites' : 'Removed from favorites');
});

module.exports = {
  uploadSingle,
  uploadMultiple,
  listFiles,
  getFile,
  downloadFile,
  downloadByKey,
  deleteFile,
  permanentDeleteFile,
  getFileStats,
  getFilesByIds,
  renameFile,
  toggleFavorite,
};
