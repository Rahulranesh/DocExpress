import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/local_jobs_service.dart';
import '../services/offline_service_manager.dart';

/// Offline Jobs Repository - replaces API-based jobs repository
/// Uses local Hive storage instead of MongoDB
class OfflineJobsRepository {
  final LocalJobsService _jobsService;

  OfflineJobsRepository({LocalJobsService? jobsService})
      : _jobsService = jobsService ?? offlineServices.jobsService;

  /// Get all jobs with pagination
  Future<PaginatedResponse<Job>> getJobs({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Fetching jobs from Hive (page: $page)');
    
    final localJobs = await _jobsService.getAllJobs(
      type: type,
      status: status,
      sortBy: sortBy,
      descending: sortOrder == 'desc',
    );

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final paginatedJobs = localJobs.skip(startIndex).take(limit).toList();
    final jobs = paginatedJobs.map((lj) => _convertToJob(lj)).toList();

    debugPrint('✅ [LOCAL STORAGE] Jobs: Found ${localJobs.length} total, returning ${jobs.length} for page $page');

    return PaginatedResponse<Job>(
      data: jobs,
      pagination: PaginationInfo(
        page: page,
        limit: limit,
        total: localJobs.length,
        totalPages: (localJobs.length / limit).ceil(),
      ),
    );
  }

  /// Get single job by ID
  Future<Job> getJob(String id) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Getting job $id');
    final localJob = await _jobsService.getJob(id);
    if (localJob == null) {
      throw Exception('Job not found');
    }
    return _convertToJob(localJob);
  }

  /// Get recent jobs
  Future<List<Job>> getRecentJobs({int limit = 10}) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Getting recent jobs (limit: $limit)');
    final localJobs = await _jobsService.getRecentJobs(limit: limit);
    return localJobs.map((lj) => _convertToJob(lj)).toList();
  }

  /// Create a job record (for tracking local operations)
  Future<Job> createJob({
    required String type,
    String? inputFileId,
    String? inputFileName,
    Map<String, dynamic>? options,
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Creating job - type: $type');
    final localJob = await _jobsService.createJob(
      type: type,
      inputFileId: inputFileId,
      inputFileName: inputFileName,
      options: options,
    );
    return _convertToJob(localJob);
  }

  /// Update job status
  Future<Job> updateJob(
    String id, {
    String? status,
    String? outputFileId,
    String? outputFileName,
    String? error,
    int? progress,
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Updating job $id');
    final localJob = await _jobsService.updateJob(
      id,
      status: status,
      outputFileId: outputFileId,
      outputFileName: outputFileName,
      error: error,
      progress: progress,
    );
    if (localJob == null) {
      throw Exception('Job not found');
    }
    return _convertToJob(localJob);
  }

  /// Delete a job
  Future<void> deleteJob(String id) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Deleting job $id');
    await _jobsService.deleteJob(id);
    debugPrint('✅ [LOCAL STORAGE] Jobs: Job deleted');
  }

  /// Retry a failed job (creates new job with same parameters)
  Future<Job> retryJob(String id) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Retrying job $id');
    final oldJob = await _jobsService.getJob(id);
    if (oldJob == null) {
      throw Exception('Job not found');
    }
    
    // Create a new job with same parameters
    final newJob = await _jobsService.createJob(
      type: oldJob.type,
      inputFileId: oldJob.inputFileId,
      inputFileName: oldJob.inputFileName,
      options: oldJob.options,
    );
    
    return _convertToJob(newJob);
  }

  /// Get job stats
  Future<JobStats> getJobStats() async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Getting job stats');
    final stats = await _jobsService.getJobStats();
    
    return JobStats(
      total: stats['total'] ?? 0,
      byStatus: {
        'PENDING': stats['pending'] ?? 0,
        'PROCESSING': stats['processing'] ?? 0,
        'COMPLETED': stats['completed'] ?? 0,
        'FAILED': stats['failed'] ?? 0,
      },
      byType: {},
    );
  }

  /// Clear all jobs
  Future<void> clearAllJobs() async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Clearing all jobs');
    await _jobsService.clearAllJobs();
  }

  /// Convert LocalJob to Job model
  Job _convertToJob(LocalJob localJob) {
    return Job(
      id: localJob.id,
      userId: 'local_user', // Local user placeholder
      type: localJob.type,
      status: JobStatus.fromString(localJob.status),
      inputFiles: localJob.inputFileId != null 
          ? [FileModel(
              id: localJob.inputFileId!,
              originalName: localJob.inputFileName ?? 'input',
              filename: localJob.inputFileName ?? 'input',
              mimeType: '',
              size: 0,
              storagePath: '',
              storageKey: '',
              fileType: '',
              createdAt: localJob.createdAt,
              updatedAt: localJob.updatedAt,
            )]
          : [],
      outputFiles: localJob.outputFileId != null 
          ? [FileModel(
              id: localJob.outputFileId!,
              originalName: localJob.outputFileName ?? 'output',
              filename: localJob.outputFileName ?? 'output',
              mimeType: '',
              size: 0,
              storagePath: '',
              storageKey: '',
              fileType: '',
              createdAt: localJob.createdAt,
              updatedAt: localJob.updatedAt,
            )]
          : [],
      options: localJob.options ?? {},
      errorMessage: localJob.error,
      createdAt: localJob.createdAt,
      updatedAt: localJob.updatedAt,
      completedAt: localJob.completedAt,
    );
  }
}
