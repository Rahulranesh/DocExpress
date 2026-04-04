import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/local_file_service.dart';
import '../services/offline_service_manager.dart';

/// Offline Files Repository - replaces API-based files repository
/// Uses local storage instead of server uploads
class OfflineFilesRepository {
  final LocalFileService _fileService;

  OfflineFilesRepository({LocalFileService? fileService})
      : _fileService = fileService ?? offlineServices.fileService;

  /// Save a file locally (replaces upload)
  Future<FileModel> uploadFile(
    File file, {
    void Function(int sent, int total)? onProgress,
    String? category,
  }) async {
    debugPrint(
        '📁 [LOCAL STORAGE] Files: Saving file to local storage - ${file.path}');
    // Simulate progress callback
    if (onProgress != null) {
      final size = await file.length();
      onProgress(0, size);
      onProgress(size ~/ 2, size);
    }

    final localFile = await _fileService.saveFile(file, category: category);
    debugPrint('✅ [LOCAL STORAGE] Files: File saved with ID: ${localFile.id}');

    if (onProgress != null) {
      final size = await file.length();
      onProgress(size, size);
    }

    return _convertToFileModel(localFile);
  }

  /// Save multiple files
  Future<List<FileModel>> uploadMultipleFiles(
    List<File> files, {
    void Function(int sent, int total)? onProgress,
    String? category,
  }) async {
    final results = <FileModel>[];

    int totalSize = 0;
    for (final file in files) {
      totalSize += await file.length();
    }

    int processed = 0;
    for (final file in files) {
      final localFile = await _fileService.saveFile(file, category: category);
      results.add(_convertToFileModel(localFile));

      processed += await file.length();
      onProgress?.call(processed, totalSize);
    }

    return results;
  }

  /// Get all files with pagination
  Future<PaginatedResponse<FileModel>> getFiles({
    int page = 1,
    int limit = 20,
    String? fileType,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    debugPrint(
        '📁 [LOCAL STORAGE] Files: Fetching files from Hive (page: $page, type: $fileType)');
    final localFiles = await _fileService.getAllFiles(
      fileType: fileType,
      sortBy: sortBy,
      descending: sortOrder == 'desc',
    );

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final paginatedFiles = localFiles.skip(startIndex).take(limit).toList();

    final files = paginatedFiles.map((lf) => _convertToFileModel(lf)).toList();
    debugPrint(
        '✅ [LOCAL STORAGE] Files: Found ${localFiles.length} total files, returning ${files.length} for page $page');

    return PaginatedResponse<FileModel>(
      data: files,
      pagination: PaginationInfo(
        page: page,
        limit: limit,
        total: localFiles.length,
        totalPages: (localFiles.length / limit).ceil(),
      ),
    );
  }

  /// Get single file by ID
  Future<FileModel> getFile(String id) async {
    final localFile = await _fileService.getFile(id);
    if (localFile == null) {
      throw Exception('File not found');
    }
    return _convertToFileModel(localFile);
  }

  /// Get files by IDs
  Future<List<FileModel>> getFilesByIds(List<String> ids) async {
    final localFiles = await _fileService.getFilesByIds(ids);
    return localFiles.map((lf) => _convertToFileModel(lf)).toList();
  }

  /// Delete a file
  Future<void> deleteFile(String id) async {
    debugPrint(
        '📁 [LOCAL STORAGE] Files: Deleting file from local storage - ID: $id');
    await _fileService.deleteFile(id);
    debugPrint('✅ [LOCAL STORAGE] Files: File deleted successfully');
  }

  /// Delete multiple files
  Future<void> deleteFiles(List<String> ids) async {
    await _fileService.deleteFiles(ids);
  }

  /// Update file metadata
  Future<FileModel> updateFile(String id, {String? name}) async {
    final localFile = await _fileService.updateFile(id, name: name);
    if (localFile == null) {
      throw Exception('File not found');
    }
    return _convertToFileModel(localFile);
  }

  /// Get download URL (returns local path for offline)
  String getDownloadUrl(String fileId) {
    // For offline, we just return a placeholder
    // The actual path will be retrieved from getFile
    return 'local://$fileId';
  }

  /// Get actual file path
  Future<String?> getFilePath(String fileId) async {
    final localFile = await _fileService.getFile(fileId);
    return localFile?.path;
  }

  /// Get total storage used
  Future<int> getTotalStorageUsed() async {
    return await _fileService.getTotalStorageUsed();
  }

  /// Get file count
  Future<int> getFileCount({String? fileType}) async {
    return await _fileService.getFileCount(fileType: fileType);
  }

  /// Search files
  Future<List<FileModel>> searchFiles(String query) async {
    final localFiles = await _fileService.getAllFiles(search: query);
    return localFiles.map((lf) => _convertToFileModel(lf)).toList();
  }

  /// Rename a file
  Future<FileModel> renameFile(String id, String newName) async {
    debugPrint('📁 [LOCAL STORAGE] Files: Renaming file $id to $newName');
    final localFile = await _fileService.updateFile(id, name: newName);
    if (localFile == null) {
      throw Exception('File not found');
    }
    debugPrint('✅ [LOCAL STORAGE] Files: File renamed successfully');
    return _convertToFileModel(localFile);
  }

  /// Toggle favorite status
  Future<FileModel> toggleFavorite(String id) async {
    debugPrint('📁 [LOCAL STORAGE] Files: Toggling favorite for file $id');
    final localFile = await _fileService.toggleFavorite(id);
    if (localFile == null) {
      throw Exception('File not found');
    }
    debugPrint(
        '✅ [LOCAL STORAGE] Files: Favorite toggled to ${localFile.isFavorite}');
    return _convertToFileModel(localFile);
  }

  /// Get file statistics
  Future<FileStats> getFileStats() async {
    debugPrint('📁 [LOCAL STORAGE] Files: Getting file statistics');
    final allFiles = await _fileService.getAllFiles();

    int totalFiles = allFiles.length;
    int totalSize = 0;
    int imageCount = 0;
    int imageSize = 0;
    int pdfCount = 0;
    int pdfSize = 0;
    int videoCount = 0;
    int videoSize = 0;
    int otherCount = 0;
    int otherSize = 0;

    for (final file in allFiles) {
      totalSize += file.size;
      switch (file.fileType) {
        case 'image':
          imageCount++;
          imageSize += file.size;
          break;
        case 'pdf':
          pdfCount++;
          pdfSize += file.size;
          break;
        case 'video':
          videoCount++;
          videoSize += file.size;
          break;
        default:
          otherCount++;
          otherSize += file.size;
      }
    }

    debugPrint(
        '✅ [LOCAL STORAGE] Files: Stats - $totalFiles files, ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');

    return FileStats(
      totalFiles: totalFiles,
      totalSize: totalSize,
      byType: {
        'image': TypeStats(count: imageCount, size: imageSize),
        'pdf': TypeStats(count: pdfCount, size: pdfSize),
        'video': TypeStats(count: videoCount, size: videoSize),
        'other': TypeStats(count: otherCount, size: otherSize),
      },
    );
  }

  /// Download file (for offline, this copies to the specified path)
  Future<void> downloadFile(String id, String savePath) async {
    debugPrint('📁 [LOCAL STORAGE] Files: Downloading file $id to $savePath');
    
    try {
      final localFile = await _fileService.getFile(id);
      if (localFile == null) {
        throw Exception('File not found in local storage with ID: $id');
      }

      final sourceFile = File(localFile.path);
      if (!await sourceFile.exists()) {
        throw Exception('Source file not found at path: ${localFile.path}. File may have been deleted.');
      }

      final sourceSize = await sourceFile.length();
      if (sourceSize == 0) {
        throw Exception('Source file is empty (0 bytes)');
      }

      debugPrint('📥 Source file: ${localFile.path} (${_formatBytes(sourceSize)})');

      // Ensure destination directory exists
      final destDir = File(savePath).parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
        debugPrint('📁 Created destination directory: ${destDir.path}');
      }

      // Check if destination file already exists
      final destFile = File(savePath);
      if (await destFile.exists()) {
        await destFile.delete();
        debugPrint('🗑️ Replaced existing file: $savePath');
      }

      // Copy file
      await sourceFile.copy(savePath);

      // Verify copy was successful
      final copiedFile = File(savePath);
      if (!await copiedFile.exists()) {
        throw Exception('File copy verification failed - destination file does not exist');
      }

      final copiedSize = await copiedFile.length();
      if (copiedSize != sourceSize) {
        throw Exception('File copy verification failed - size mismatch. Source: $sourceSize, Copied: $copiedSize');
      }

      debugPrint('✅ [LOCAL STORAGE] Files: File successfully copied to $savePath (${_formatBytes(copiedSize)})');
    } catch (e) {
      debugPrint('❌ [LOCAL STORAGE] Files: Download failed: $e');
      rethrow;
    }
  }

  /// Helper to format bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Convert LocalFile to FileModel (for compatibility with existing UI)
  FileModel _convertToFileModel(LocalFile localFile) {
    return FileModel(
      id: localFile.id,
      originalName: localFile.name,
      filename: localFile.name,
      mimeType: localFile.mimeType,
      size: localFile.size,
      fileType: localFile.fileType,
      storagePath: localFile.path,
      storageKey: 'local_${localFile.id}',
      isFavorite: localFile.isFavorite,
      createdAt: localFile.createdAt,
      updatedAt: localFile.updatedAt,
    );
  }
}
