import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Jobs Repository - handles job/history operations
class JobsRepository {
  final ApiService _apiService;

  JobsRepository({required ApiService apiService}) : _apiService = apiService;

  /// Get all jobs for current user with pagination
  Future<PaginatedResponse<Job>> getJobs({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    debugPrint('📡 JobsRepository.getJobs() - calling API');
    debugPrint('📍 Endpoint: ${ApiEndpoints.jobs}');
    debugPrint('📋 Query: $queryParams');

    final response = await _apiService.get(
      ApiEndpoints.jobs,
      queryParameters: queryParams,
    );

    debugPrint('📥 Response status: ${response.statusCode}');
    debugPrint('📦 Response data: ${response.data}');

    if (response.statusCode == 200) {
      final responseData = response.data;

      // Handle different response formats
      // Format 1: {success: true, data: [...jobs...], pagination: {...}}
      // Format 2: {success: true, data: {jobs: [...], pagination: {...}}}
      List<dynamic> jobsList;
      Map<String, dynamic> paginationData;

      if (responseData['data'] is List) {
        // Direct array format
        jobsList = responseData['data'] as List;
        paginationData = responseData['pagination'] ?? {};
      } else if (responseData['data'] is Map) {
        // Nested format with 'jobs' key
        final dataMap = responseData['data'] as Map<String, dynamic>;
        jobsList = dataMap['jobs'] as List? ?? [];
        paginationData =
            dataMap['pagination'] ?? responseData['pagination'] ?? {};
      } else {
        jobsList = [];
        paginationData = {};
      }

      debugPrint('📊 Parsed ${jobsList.length} jobs');

      return PaginatedResponse<Job>(
        data: jobsList
            .map((json) => Job.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(paginationData),
      );
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch jobs',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get single job by ID
  Future<Job> getJob(String id) async {
    final response = await _apiService.get(ApiEndpoints.job(id));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return Job.fromJson(data['job'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch job',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get recent jobs
  Future<List<Job>> getRecentJobs({int limit = 10}) async {
    final response = await _apiService.get(
      ApiEndpoints.recentJobs,
      queryParameters: {'limit': limit},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final jobs = data['jobs'] ?? data;
      return (jobs as List)
          .map((j) => Job.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      message:
          response.data?['error']?['message'] ?? 'Failed to fetch recent jobs',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get job statistics
  Future<JobStats> getJobStats() async {
    final response = await _apiService.get(ApiEndpoints.jobStats);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return JobStats.fromJson(data);
    }

    throw ApiException(
      message:
          response.data?['error']?['message'] ?? 'Failed to fetch job stats',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get available job types
  Future<Map<String, dynamic>> getJobTypes() async {
    final response = await _apiService.get(ApiEndpoints.jobTypes);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return {
        'types': List<String>.from(data['types'] ?? []),
        'statuses': List<String>.from(data['statuses'] ?? []),
      };
    }

    throw ApiException(
      message:
          response.data?['error']?['message'] ?? 'Failed to fetch job types',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get pending jobs count
  Future<int> getPendingCount() async {
    final response = await _apiService.get(ApiEndpoints.pendingCount);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return data['pendingCount'] ?? 0;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ??
          'Failed to fetch pending count',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Check if user has reached job limit
  Future<Map<String, dynamic>> checkJobLimit() async {
    final response = await _apiService.get(ApiEndpoints.checkLimit);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return {
        'hasReachedLimit': data['hasReachedLimit'] ?? false,
        'maxConcurrent': data['maxConcurrent'] ?? 5,
      };
    }

    throw ApiException(
      message:
          response.data?['error']?['message'] ?? 'Failed to check job limit',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Cancel a pending job
  Future<Job> cancelJob(String id) async {
    final response = await _apiService.post(ApiEndpoints.cancelJob(id));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return Job.fromJson(data['job'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to cancel job',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Delete a job
  Future<void> deleteJob(String id) async {
    debugPrint('📤 DELETE request to: /jobs/$id');
    final response = await _apiService.delete('/jobs/$id');
    debugPrint('📥 DELETE response status: ${response.statusCode}');
    debugPrint('📥 DELETE response data: ${response.data}');

    if (response.statusCode == 200) {
      return;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to delete job',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Retry a failed job
  Future<Job> retryJob(String id) async {
    final response = await _apiService.post(ApiEndpoints.retryJob(id));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return Job.fromJson(data['job'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to retry job',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get jobs by status (helper methods)
  Future<PaginatedResponse<Job>> getPendingJobs({
    int page = 1,
    int limit = 20,
  }) async {
    return getJobs(page: page, limit: limit, status: 'PENDING');
  }

  Future<PaginatedResponse<Job>> getRunningJobs({
    int page = 1,
    int limit = 20,
  }) async {
    return getJobs(page: page, limit: limit, status: 'RUNNING');
  }

  Future<PaginatedResponse<Job>> getCompletedJobs({
    int page = 1,
    int limit = 20,
  }) async {
    return getJobs(page: page, limit: limit, status: 'COMPLETED');
  }

  Future<PaginatedResponse<Job>> getFailedJobs({
    int page = 1,
    int limit = 20,
  }) async {
    return getJobs(page: page, limit: limit, status: 'FAILED');
  }

  /// Get jobs by type (helper methods)
  Future<PaginatedResponse<Job>> getConversionJobs({
    int page = 1,
    int limit = 20,
  }) async {
    // Returns all conversion type jobs
    // Note: Backend might need filtering by multiple types
    return getJobs(page: page, limit: limit);
  }

  Future<PaginatedResponse<Job>> getCompressionJobs({
    int page = 1,
    int limit = 20,
  }) async {
    return getJobs(page: page, limit: limit, type: 'COMPRESS_IMAGE');
  }

  /// Get in-progress jobs
  Future<List<Job>> getInProgressJobs() async {
    final pendingResult = await getPendingJobs(limit: 50);
    final runningResult = await getRunningJobs(limit: 50);
    return [...pendingResult.data, ...runningResult.data];
  }

  /// Poll job status until completed or failed
  Future<Job> waitForJobCompletion(
    String jobId, {
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    void Function(Job)? onStatusChange,
  }) async {
    final startTime = DateTime.now();
    Job? lastJob;

    while (true) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > timeout) {
        throw ApiException(
          message: 'Job timed out',
          code: 'TIMEOUT',
        );
      }

      final job = await getJob(jobId);

      // Notify on status change
      if (lastJob?.status != job.status && onStatusChange != null) {
        onStatusChange(job);
      }
      lastJob = job;

      // Check if job is done
      if (job.status.isCompleted || job.status.isFailed) {
        return job;
      }

      // Wait before next poll
      await Future.delayed(pollInterval);
    }
  }

  /// Get job type label
  String getJobTypeLabel(String type) {
    final labels = {
      'IMAGE_TO_PDF': 'Images to PDF',
      'IMAGE_TO_PPTX': 'Images to PPTX',
      'IMAGE_TO_DOCX': 'Images to DOCX',
      'IMAGE_TO_TXT': 'Image OCR',
      'IMAGE_FORMAT_CONVERT': 'Image Format',
      'IMAGE_TRANSFORM': 'Image Transform',
      'IMAGE_MERGE': 'Merge Images',
      'PDF_TO_PPTX': 'PDF to PPTX',
      'PDF_TO_DOCX': 'PDF to DOCX',
      'PDF_TO_TXT': 'PDF to Text',
      'PPTX_TO_PDF': 'PPTX to PDF',
      'DOCX_TO_PDF': 'DOCX to PDF',
      'PDF_MERGE': 'Merge PDFs',
      'PDF_SPLIT': 'Split PDF',
      'PDF_REORDER': 'Reorder PDF',
      'PDF_EXTRACT_IMAGES': 'Extract Images',
      'PDF_EXTRACT_TEXT': 'Extract Text',
      'COMPRESS_IMAGE': 'Compress Image',
      'COMPRESS_VIDEO': 'Compress Video',
      'COMPRESS_PDF': 'Compress PDF',
    };
    return labels[type] ?? type;
  }

  /// Get job status color code
  String getStatusColorCode(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'warning';
      case JobStatus.running:
        return 'info';
      case JobStatus.completed:
        return 'success';
      case JobStatus.failed:
        return 'error';
    }
  }
}
