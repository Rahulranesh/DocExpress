import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Files Repository - handles file upload, download, and management operations
class FilesRepository {
  final ApiService _apiService;

  FilesRepository({required ApiService apiService}) : _apiService = apiService;

  /// Upload a single file
  Future<FileModel> uploadFile(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _apiService.uploadFile(
      ApiEndpoints.uploadFile,
      file,
      fieldName: 'file',
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to upload file',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Upload multiple files
  Future<List<FileModel>> uploadMultipleFiles(
    List<File> files, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _apiService.uploadMultipleFiles(
      ApiEndpoints.uploadMultiple,
      files,
      fieldName: 'files',
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      final filesList = data['files'] ?? data;
      return (filesList as List)
          .map((f) => FileModel.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to upload files',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get all files for current user with pagination
  Future<PaginatedResponse<FileModel>> getFiles({
    int page = 1,
    int limit = 20,
    String? fileType,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (fileType != null && fileType.isNotEmpty) {
      queryParams['fileType'] = fileType;
    }

    final response = await _apiService.get(
      ApiEndpoints.files,
      queryParameters: queryParams,
    );

    debugPrint('📥 Files Response status: ${response.statusCode}');
    debugPrint('📦 Files Response data: ${response.data}');

    if (response.statusCode == 200) {
      final responseData = response.data;

      // Handle different response formats
      List<dynamic> filesList;
      Map<String, dynamic> paginationData;

      if (responseData['data'] is List) {
        // Direct array format
        filesList = responseData['data'] as List;
        paginationData = responseData['pagination'] ?? {};
      } else if (responseData['data'] is Map) {
        // Nested format with 'files' key
        final dataMap = responseData['data'] as Map<String, dynamic>;
        filesList = dataMap['files'] as List? ?? [];
        paginationData =
            dataMap['pagination'] ?? responseData['pagination'] ?? {};
      } else {
        filesList = [];
        paginationData = {};
      }

      debugPrint('📊 Parsed ${filesList.length} files');

      return PaginatedResponse<FileModel>(
        data: filesList
            .map((json) => FileModel.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(paginationData),
      );
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch files',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get single file by ID
  Future<FileModel> getFile(String id) async {
    final response = await _apiService.get(ApiEndpoints.file(id));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch file',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get multiple files by IDs
  Future<List<FileModel>> getFilesByIds(List<String> ids) async {
    final response = await _apiService.post(
      ApiEndpoints.fileBatch,
      data: {'fileIds': ids},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final filesList = data['files'] ?? data;
      return (filesList as List)
          .map((f) => FileModel.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch files',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Download file to local path
  Future<String> downloadFile(
    String fileId,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final response = await _apiService.downloadFile(
      ApiEndpoints.downloadFile(fileId),
      savePath,
      onReceiveProgress: onProgress,
    );

    if (response.statusCode == 200) {
      return savePath;
    }

    throw ApiException(
      message: 'Failed to download file',
      statusCode: response.statusCode,
    );
  }

  /// Download file by storage key
  Future<String> downloadFileByKey(
    String storageKey,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    final encodedKey = Uri.encodeComponent(storageKey);
    final response = await _apiService.downloadFile(
      '/files/download/$encodedKey',
      savePath,
      onReceiveProgress: onProgress,
    );

    if (response.statusCode == 200) {
      return savePath;
    }

    throw ApiException(
      message: 'Failed to download file',
      statusCode: response.statusCode,
    );
  }

  /// Delete file (hard delete)
  Future<void> deleteFile(String id) async {
    debugPrint('📤 DELETE request to: ${ApiEndpoints.file(id)}');
    final response = await _apiService.delete(ApiEndpoints.file(id));
    debugPrint('📥 DELETE response status: ${response.statusCode}');
    debugPrint('📥 DELETE response data: ${response.data}');

    if (response.statusCode == 200) {
      return;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to delete file',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Rename file
  Future<FileModel> renameFile(String id, String newName) async {
    final response = await _apiService.patch(
      '${ApiEndpoints.file(id)}/rename',
      data: {'newName': newName},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to rename file',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Toggle favorite status
  Future<FileModel> toggleFavorite(String id) async {
    final response = await _apiService.patch(
      '${ApiEndpoints.file(id)}/favorite',
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message:
          response.data?['error']?['message'] ?? 'Failed to toggle favorite',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Permanently delete file
  Future<void> permanentlyDeleteFile(String id) async {
    final response =
        await _apiService.delete('${ApiEndpoints.file(id)}/permanent');

    if (response.statusCode == 200) {
      return;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to delete file',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get file statistics
  Future<FileStats> getFileStats() async {
    final response = await _apiService.get(ApiEndpoints.fileStats);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return FileStats.fromJson(data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch stats',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get files by type (helper methods)
  Future<PaginatedResponse<FileModel>> getImages({
    int page = 1,
    int limit = 20,
  }) async {
    return getFiles(page: page, limit: limit, fileType: 'image');
  }

  Future<PaginatedResponse<FileModel>> getPdfs({
    int page = 1,
    int limit = 20,
  }) async {
    return getFiles(page: page, limit: limit, fileType: 'pdf');
  }

  Future<PaginatedResponse<FileModel>> getVideos({
    int page = 1,
    int limit = 20,
  }) async {
    return getFiles(page: page, limit: limit, fileType: 'video');
  }

  Future<PaginatedResponse<FileModel>> getDocuments({
    int page = 1,
    int limit = 20,
  }) async {
    return getFiles(page: page, limit: limit, fileType: 'document');
  }

  /// Get recent files
  Future<List<FileModel>> getRecentFiles({int limit = 10}) async {
    final result = await getFiles(
      page: 1,
      limit: limit,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );
    return result.data;
  }

  /// Batch delete files
  Future<void> deleteFiles(List<String> ids) async {
    final futures = ids.map((id) => deleteFile(id));
    await Future.wait(futures);
  }

  /// Check if file exists locally
  Future<bool> fileExistsLocally(String path) async {
    return File(path).exists();
  }

  /// Get local file path for a file model
  String getLocalPath(FileModel file, String downloadDir) {
    return '$downloadDir/${file.filename}';
  }

  /// Get download URL for a file
  String getDownloadUrl(String fileId) {
    return '${_apiService.baseUrl}${ApiEndpoints.downloadFile(fileId)}';
  }
}
