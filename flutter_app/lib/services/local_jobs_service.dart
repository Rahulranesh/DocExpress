import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Local Job model for Hive storage
class LocalJob {
  final String id;
  final String type;
  final String status;
  final String? inputFileId;
  final String? outputFileId;
  final String? inputFileName;
  final String? outputFileName;
  final Map<String, dynamic>? options;
  final String? error;
  final int progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  LocalJob({
    required this.id,
    required this.type,
    required this.status,
    this.inputFileId,
    this.outputFileId,
    this.inputFileName,
    this.outputFileName,
    this.options,
    this.error,
    this.progress = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'inputFileId': inputFileId,
      'outputFileId': outputFileId,
      'inputFileName': inputFileName,
      'outputFileName': outputFileName,
      'options': options,
      'error': error,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory LocalJob.fromMap(Map<String, dynamic> map) {
    return LocalJob(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'pending',
      inputFileId: map['inputFileId'],
      outputFileId: map['outputFileId'],
      inputFileName: map['inputFileName'],
      outputFileName: map['outputFileName'],
      options: map['options'] != null ? Map<String, dynamic>.from(map['options']) : null,
      error: map['error'],
      progress: map['progress'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }

  LocalJob copyWith({
    String? status,
    String? outputFileId,
    String? outputFileName,
    String? error,
    int? progress,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return LocalJob(
      id: id,
      type: type,
      status: status ?? this.status,
      inputFileId: inputFileId,
      outputFileId: outputFileId ?? this.outputFileId,
      inputFileName: inputFileName,
      outputFileName: outputFileName ?? this.outputFileName,
      options: options,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Local Jobs Service - manages job history locally using Hive
class LocalJobsService {
  static const String _boxName = 'local_jobs';
  late Box<Map> _jobsBox;
  final _uuid = const Uuid();

  /// Initialize the service
  Future<void> init() async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Initializing Hive box');
    _jobsBox = await Hive.openBox<Map>(_boxName);
    debugPrint('✅ [LOCAL STORAGE] Jobs: Initialized with ${_jobsBox.length} jobs');
  }

  /// Create a new job record
  Future<LocalJob> createJob({
    required String type,
    String? inputFileId,
    String? inputFileName,
    Map<String, dynamic>? options,
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Creating job - type: $type');
    final now = DateTime.now();
    final job = LocalJob(
      id: _uuid.v4(),
      type: type,
      status: 'pending',
      inputFileId: inputFileId,
      inputFileName: inputFileName,
      options: options,
      progress: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _jobsBox.put(job.id, job.toMap());
    debugPrint('✅ [LOCAL STORAGE] Jobs: Job created - ${job.id}');
    return job;
  }

  /// Update job status
  Future<LocalJob?> updateJob(
    String id, {
    String? status,
    String? outputFileId,
    String? outputFileName,
    String? error,
    int? progress,
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Updating job $id');
    final data = _jobsBox.get(id);
    if (data == null) return null;

    final job = LocalJob.fromMap(Map<String, dynamic>.from(data));
    final updatedJob = job.copyWith(
      status: status,
      outputFileId: outputFileId,
      outputFileName: outputFileName,
      error: error,
      progress: progress,
      updatedAt: DateTime.now(),
      completedAt: status == 'completed' || status == 'failed' ? DateTime.now() : null,
    );

    await _jobsBox.put(id, updatedJob.toMap());
    debugPrint('✅ [LOCAL STORAGE] Jobs: Job updated - status: ${updatedJob.status}');
    return updatedJob;
  }

  /// Get all jobs
  Future<List<LocalJob>> getAllJobs({
    String? type,
    String? status,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Fetching all jobs');
    final jobs = _jobsBox.values
        .map((data) => LocalJob.fromMap(Map<String, dynamic>.from(data)))
        .where((job) {
          if (type != null && job.type != type) return false;
          if (status != null && job.status != status) return false;
          return true;
        })
        .toList();

    // Sort
    jobs.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'type':
          comparison = a.type.compareTo(b.type);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'updatedAt':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return descending ? -comparison : comparison;
    });

    debugPrint('✅ [LOCAL STORAGE] Jobs: Found ${jobs.length} jobs');
    return jobs;
  }

  /// Get a single job
  Future<LocalJob?> getJob(String id) async {
    final data = _jobsBox.get(id);
    if (data == null) return null;
    return LocalJob.fromMap(Map<String, dynamic>.from(data));
  }

  /// Get recent jobs
  Future<List<LocalJob>> getRecentJobs({int limit = 10}) async {
    final jobs = await getAllJobs(sortBy: 'createdAt', descending: true);
    return jobs.take(limit).toList();
  }

  /// Delete a job
  Future<void> deleteJob(String id) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Deleting job $id');
    await _jobsBox.delete(id);
    debugPrint('✅ [LOCAL STORAGE] Jobs: Job deleted');
  }

  /// Delete multiple jobs
  Future<void> deleteJobs(List<String> ids) async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Deleting ${ids.length} jobs');
    for (final id in ids) {
      await _jobsBox.delete(id);
    }
    debugPrint('✅ [LOCAL STORAGE] Jobs: Jobs deleted');
  }

  /// Clear all jobs
  Future<void> clearAllJobs() async {
    debugPrint('📋 [LOCAL STORAGE] Jobs: Clearing all jobs');
    await _jobsBox.clear();
    debugPrint('✅ [LOCAL STORAGE] Jobs: All jobs cleared');
  }

  /// Get job stats
  Future<Map<String, int>> getJobStats() async {
    final jobs = await getAllJobs();
    final stats = <String, int>{
      'total': jobs.length,
      'pending': 0,
      'processing': 0,
      'completed': 0,
      'failed': 0,
    };

    for (final job in jobs) {
      stats[job.status] = (stats[job.status] ?? 0) + 1;
    }

    return stats;
  }
}
