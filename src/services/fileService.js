const File = require('../models/File');
const AppError = require('../utils/AppError');
const { getFileTypeFromMime, PAGINATION } = require('../utils/constants');
const fs = require('fs').promises;
const path = require('path');

class FileService {
  /**
   * Create file metadata record
   */
  async createFileMeta(fileData, userId) {
    const { originalname, mimetype, size, filename, path: filePath, storageKey } = fileData;

    const fileMeta = new File({
      owner: userId,
      originalName: originalname,
      filename,
      mimeType: mimetype,
      size,
      storagePath: filePath,
      storageKey: storageKey || filename,
      fileType: getFileTypeFromMime(mimetype),
    });

    await fileMeta.save();
    return fileMeta;
  }

  /**
   * Create multiple file metadata records
   */
  async createMultipleFileMeta(files, userId) {
    const fileRecords = await Promise.all(
      files.map((file) => this.createFileMeta(file, userId))
    );
    return fileRecords;
  }

  /**
   * Get file by ID
   */
  async getFileById(fileId, userId = null, includeDeleted = false) {
    const query = { _id: fileId };

    if (!includeDeleted) {
      query.isDeleted = false;
    }

    const file = await File.findOne(query);

    if (!file) {
      throw AppError.notFound('File not found');
    }

    // Check ownership if userId provided
    if (userId && file.owner.toString() !== userId.toString()) {
      throw AppError.forbidden('Access denied to this file');
    }

    return file;
  }

  /**
   * Get files by IDs
   */
  async getFilesByIds(fileIds, userId = null) {
    const query = { _id: { $in: fileIds }, isDeleted: false };

    if (userId) {
      query.owner = userId;
    }

    const files = await File.find(query);

    if (files.length !== fileIds.length) {
      throw AppError.notFound('One or more files not found');
    }

    return files;
  }

  /**
   * List files for user with pagination and filters
   */
  async listUserFiles(userId, options = {}) {
    const {
      page = PAGINATION.DEFAULT_PAGE,
      limit = PAGINATION.DEFAULT_LIMIT,
      fileType,
      sortBy = 'createdAt',
      sortOrder = -1,
    } = options;

    const query = { owner: userId, isDeleted: false };

    if (fileType) {
      query.fileType = fileType;
    }

    const skip = (page - 1) * limit;

    const [files, total] = await Promise.all([
      File.find(query)
        .sort({ [sortBy]: sortOrder })
        .skip(skip)
        .limit(limit),
      File.countDocuments(query),
    ]);

    return {
      files,
      pagination: { page, limit, total },
    };
  }

  /**
   * Update file metadata
   */
  async updateFileMeta(fileId, userId, updates) {
    const file = await this.getFileById(fileId, userId);

    // Only allow certain fields to be updated
    const allowedUpdates = ['originalName', 'metadata'];
    const filteredUpdates = {};

    for (const key of allowedUpdates) {
      if (updates[key] !== undefined) {
        filteredUpdates[key] = updates[key];
      }
    }

    Object.assign(file, filteredUpdates);
    await file.save();

    return file;
  }

  /**
   * Soft delete a file
   */
  async softDeleteFile(fileId, userId) {
    const file = await this.getFileById(fileId, userId);
    await file.softDelete();
    return file;
  }

  /**
   * Hard delete a file (removes from DB and disk)
   */
  async hardDeleteFile(fileId, userId) {
    const file = await this.getFileById(fileId, userId, true);

    // Remove from disk
    try {
      await fs.unlink(file.storagePath);
    } catch (err) {
      // Log but don't throw if file doesn't exist on disk
      console.warn(`Failed to delete file from disk: ${file.storagePath}`, err.message);
    }

    // Remove from database
    await File.deleteOne({ _id: fileId });

    return { deleted: true, fileId };
  }

  /**
   * Get file stats for user
   */
  async getUserFileStats(userId) {
    const stats = await File.aggregate([
      { $match: { owner: userId, isDeleted: false } },
      {
        $group: {
          _id: '$fileType',
          count: { $sum: 1 },
          totalSize: { $sum: '$size' },
        },
      },
    ]);

    const totalFiles = stats.reduce((sum, s) => sum + s.count, 0);
    const totalSize = stats.reduce((sum, s) => sum + s.totalSize, 0);

    return {
      byType: stats.reduce((acc, s) => {
        acc[s._id] = { count: s.count, size: s.totalSize };
        return acc;
      }, {}),
      totalFiles,
      totalSize,
    };
  }

  /**
   * Create output file metadata from job processing
   */
  async createOutputFile(outputData, userId, jobId = null) {
    const { filePath, originalName, mimeType } = outputData;

    const stats = await fs.stat(filePath);
    const filename = path.basename(filePath);
    const storageKey = path.relative(process.env.STORAGE_ROOT || './uploads', filePath);

    const fileMeta = new File({
      owner: userId,
      originalName,
      filename,
      mimeType,
      size: stats.size,
      storagePath: filePath,
      storageKey,
      fileType: getFileTypeFromMime(mimeType),
      sourceJob: jobId,
    });

    await fileMeta.save();
    return fileMeta;
  }

  /**
   * Verify file access for user
   */
  async verifyAccess(fileId, userId, requireOwnership = true) {
    const file = await File.findOne({ _id: fileId, isDeleted: false });

    if (!file) {
      throw AppError.notFound('File not found');
    }

    if (requireOwnership && file.owner.toString() !== userId.toString()) {
      throw AppError.forbidden('Access denied');
    }

    return file;
  }

  /**
   * Get the full storage path for a file
   */
  getFullPath(file) {
    if (path.isAbsolute(file.storagePath)) {
      return file.storagePath;
    }
    return path.resolve(file.storagePath);
  }

  /**
   * Clean up orphaned files (files without valid DB records)
   */
  async cleanupOrphanedFiles(storageRoot, dryRun = true) {
    // This would scan the storage directory and check against DB
    // Implementation depends on storage adapter
    // TODO: Implement full cleanup logic
    console.log('Cleanup orphaned files - not yet implemented');
    return { dryRun, cleaned: 0 };
  }
}

module.exports = new FileService();
