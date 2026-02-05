import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/local_compression_service.dart';
import '../services/local_file_service.dart';
import '../services/local_jobs_service.dart';
import '../services/offline_service_manager.dart';

/// Offline Compression Repository - replaces API-based compression repository
/// All compression operations are performed locally on the device
class OfflineCompressionRepository {
  final LocalCompressionService _compressionService;
  final LocalFileService _fileService;
  final LocalJobsService _jobsService;

  OfflineCompressionRepository({
    LocalCompressionService? compressionService,
    LocalFileService? fileService,
    LocalJobsService? jobsService,
  })  : _compressionService = compressionService ?? offlineServices.compressionService,
        _fileService = fileService ?? offlineServices.fileService,
        _jobsService = jobsService ?? offlineServices.jobsService;

  // ==================== Image Compression ====================

  /// Compress a single image
  Future<CompressionResult> compressImage({
    required String filePath,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
    String? format,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] Compression: Compressing image locally');
    
    // Create job record
    final job = await _jobsService.createJob(
      type: 'compress_image',
      inputFileName: filePath.split('/').last,
      options: {'quality': quality, 'maxWidth': maxWidth, 'maxHeight': maxHeight},
    );

    try {
      // Perform compression
      final outputPath = await _compressionService.compressImage(
        inputPath: filePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        outputFormat: format,
      );

      // Save to file service
      final savedFile = await _fileService.saveFile(File(outputPath));

      // Update job
      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      debugPrint('✅ [LOCAL PROCESSING] Compression: Image compressed successfully');

      return CompressionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        originalSize: File(filePath).lengthSync(),
        compressedSize: savedFile.size,
        message: 'Image compressed successfully',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id, status: 'failed', error: e.toString());
      
      return CompressionResult(
        success: false,
        message: 'Failed to compress image: $e',
      );
    }
  }

  /// Compress multiple images
  Future<List<CompressionResult>> compressImages({
    required List<String> filePaths,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
    String? format,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] Compression: Batch compressing ${filePaths.length} images');
    
    final results = <CompressionResult>[];
    
    for (final filePath in filePaths) {
      final result = await compressImage(
        filePath: filePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
      );
      results.add(result);
    }

    final successful = results.where((r) => r.success).length;
    debugPrint('✅ [LOCAL PROCESSING] Compression: Batch complete - $successful/${filePaths.length} successful');
    
    return results;
  }

  // ==================== Video Compression ====================

  /// Check if video compression is available
  bool get isVideoCompressionAvailable => _compressionService.isVideoCompressionAvailable;

  /// Compress video
  Future<CompressionResult> compressVideo({
    required String filePath,
    String preset = 'medium',
    String? resolution,
    int? bitrate,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] Compression: Video compression requested');
    
    if (!isVideoCompressionAvailable) {
      debugPrint('⚠️ [LOCAL PROCESSING] Compression: Video compression not available offline');
      return CompressionResult(
        success: false,
        message: 'Video compression is not available offline. '
            'This feature requires the ffmpeg_kit_flutter package.',
      );
    }

    // Create job record
    final job = await _jobsService.createJob(
      type: 'compress_video',
      inputFileName: filePath.split('/').last,
      options: {'preset': preset, 'resolution': resolution, 'bitrate': bitrate},
    );

    try {
      final outputPath = await _compressionService.compressVideo(
        inputPath: filePath,
        preset: preset,
        resolution: resolution,
        bitrate: bitrate,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return CompressionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        originalSize: File(filePath).lengthSync(),
        compressedSize: savedFile.size,
        message: 'Video compressed successfully',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id, status: 'failed', error: e.toString());
      
      return CompressionResult(
        success: false,
        message: 'Failed to compress video: $e',
      );
    }
  }

  /// Get video info
  Future<Map<String, dynamic>> getVideoInfo(String filePath) async {
    return await _compressionService.getVideoInfo(filePath);
  }

  // ==================== PDF Compression ====================

  /// Compress PDF
  Future<CompressionResult> compressPdf({
    required String filePath,
    int quality = 80,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] Compression: Compressing PDF');
    
    final job = await _jobsService.createJob(
      type: 'compress_pdf',
      inputFileName: filePath.split('/').last,
      options: {'quality': quality},
    );

    try {
      final outputPath = await _compressionService.compressPdf(
        inputPath: filePath,
        quality: quality,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return CompressionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'PDF compressed (limited compression available offline)',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id, status: 'failed', error: e.toString());
      
      return CompressionResult(
        success: false,
        message: 'Failed to compress PDF: $e',
      );
    }
  }
}

/// Result of a compression operation
class CompressionResult {
  final bool success;
  final String? outputPath;
  final String? fileId;
  final int? originalSize;
  final int? compressedSize;
  final String message;

  CompressionResult({
    required this.success,
    this.outputPath,
    this.fileId,
    this.originalSize,
    this.compressedSize,
    required this.message,
  });

  double get compressionRatio {
    if (originalSize == null || compressedSize == null || originalSize == 0) {
      return 0;
    }
    return 1 - (compressedSize! / originalSize!);
  }

  String get savingsPercentage => '${(compressionRatio * 100).toStringAsFixed(1)}%';
}
