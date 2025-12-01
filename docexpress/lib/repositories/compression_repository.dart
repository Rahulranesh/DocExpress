import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Compression Repository - handles image, video, and PDF compression operations
class CompressionRepository {
  final ApiService _apiService;

  CompressionRepository({required ApiService apiService})
      : _apiService = apiService;

  // ==================== Image Compression ====================

  /// Compress a single image
  Future<Job> compressImage({
    required String fileId,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    String? format,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.compressImage,
      data: CompressionRequest(
        fileId: fileId,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        format: format,
      ).toJson(),
    );

    return _parseJobResponse(response, 'Failed to compress image');
  }

  /// Compress multiple images (batch)
  Future<Job> compressImages({
    required List<String> fileIds,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    String? format,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.compressImages,
      data: {
        'fileIds': fileIds,
        if (quality != null) 'quality': quality,
        if (maxWidth != null) 'maxWidth': maxWidth,
        if (maxHeight != null) 'maxHeight': maxHeight,
        if (format != null) 'format': format,
      },
    );

    return _parseJobResponse(response, 'Failed to compress images');
  }

  // ==================== Video Compression ====================

  /// Compress video with preset
  Future<Job> compressVideo({
    required String fileId,
    String? preset,
    String? resolution,
    String? customBitrate,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.compressVideo,
      data: {
        'fileId': fileId,
        if (preset != null) 'preset': preset,
        if (resolution != null) 'resolution': resolution,
        if (customBitrate != null) 'customBitrate': customBitrate,
      },
    );

    return _parseJobResponse(response, 'Failed to compress video');
  }

  /// Compress video to specific resolution
  Future<Job> compressVideoToResolution({
    required String fileId,
    required String resolution,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.compressVideoResolution,
      data: {
        'fileId': fileId,
        'resolution': resolution,
      },
    );

    return _parseJobResponse(response, 'Failed to compress video');
  }

  /// Get video metadata/info
  Future<Map<String, dynamic>> getVideoInfo(String fileId) async {
    final response = await _apiService.get(ApiEndpoints.videoInfo(fileId));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return {
        'file': data['file'],
        'metadata': data['metadata'],
      };
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to get video info',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Extract thumbnail from video
  Future<FileModel> extractVideoThumbnail({
    required String fileId,
    String? timestamp,
    int? width,
    int? height,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.videoThumbnail,
      data: {
        'fileId': fileId,
        if (timestamp != null) 'timestamp': timestamp,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to extract thumbnail',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Extract audio from video
  Future<FileModel> extractAudioFromVideo({
    required String fileId,
    String format = 'mp3',
    String bitrate = '192k',
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.videoExtractAudio,
      data: {
        'fileId': fileId,
        'format': format,
        'bitrate': bitrate,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to extract audio',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  // ==================== PDF Compression ====================

  /// Compress PDF
  Future<Job> compressPdf({
    required String fileId,
    String quality = 'medium',
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.compressPdf,
      data: {
        'fileId': fileId,
        'quality': quality,
      },
    );

    return _parseJobResponse(response, 'Failed to compress PDF');
  }

  // ==================== Presets & Info ====================

  /// Get available compression presets
  Future<Map<String, dynamic>> getPresets() async {
    final response = await _apiService.get(ApiEndpoints.compressPresets);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return data['presets'] ?? data;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to get presets',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  // ==================== Helper Methods ====================

  /// Parse job response from API
  Job _parseJobResponse(dynamic response, String defaultError) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return Job.fromJson(data['job'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? defaultError,
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  // ==================== Static Helpers ====================

  /// Get quality label from value
  static String getQualityLabel(int quality) {
    if (quality <= 30) return 'Low';
    if (quality <= 60) return 'Medium';
    if (quality <= 80) return 'High';
    return 'Maximum';
  }

  /// Get quality value from preset
  static int getQualityFromPreset(String preset) {
    switch (preset.toLowerCase()) {
      case 'low':
        return AppConstants.lowQuality;
      case 'medium':
        return AppConstants.mediumQuality;
      case 'high':
        return AppConstants.highQuality;
      case 'maximum':
      case 'max':
        return AppConstants.maxQuality;
      default:
        return AppConstants.mediumQuality;
    }
  }

  /// Get video preset options
  static List<Map<String, dynamic>> get videoPresets => [
        {
          'value': 'low',
          'label': 'Low Quality',
          'description': '480p - Smaller file size',
          'resolution': '480p',
        },
        {
          'value': 'medium',
          'label': 'Medium Quality',
          'description': '720p - Balanced',
          'resolution': '720p',
        },
        {
          'value': 'high',
          'label': 'High Quality',
          'description': '1080p - Best quality',
          'resolution': '1080p',
        },
      ];

  /// Get video resolution options
  static List<Map<String, dynamic>> get videoResolutions => [
        {'value': '480p', 'label': '480p', 'description': 'SD Quality'},
        {'value': '720p', 'label': '720p', 'description': 'HD Quality'},
        {'value': '1080p', 'label': '1080p', 'description': 'Full HD'},
      ];

  /// Get image quality presets
  static List<Map<String, dynamic>> get imageQualityPresets => [
        {
          'value': AppConstants.lowQuality,
          'label': 'Low',
          'description': 'Smallest file size',
        },
        {
          'value': AppConstants.mediumQuality,
          'label': 'Medium',
          'description': 'Balanced quality',
        },
        {
          'value': AppConstants.highQuality,
          'label': 'High',
          'description': 'Better quality',
        },
        {
          'value': AppConstants.maxQuality,
          'label': 'Maximum',
          'description': 'Best quality',
        },
      ];

  /// Get PDF quality presets
  static List<Map<String, dynamic>> get pdfQualityPresets => [
        {
          'value': 'low',
          'label': 'Aggressive',
          'description': 'Maximum compression',
        },
        {
          'value': 'medium',
          'label': 'Balanced',
          'description': 'Good compression',
        },
        {
          'value': 'high',
          'label': 'Light',
          'description': 'Minimal compression',
        },
      ];

  /// Supported audio output formats for video extraction
  static List<String> get supportedAudioFormats => ['mp3', 'aac', 'wav'];

  /// Supported image output formats for compression
  static List<String> get supportedImageFormats => ['jpeg', 'png', 'webp'];

  /// Estimate compressed file size (rough estimate)
  static int estimateCompressedSize({
    required int originalSize,
    required int quality,
  }) {
    // Very rough estimate based on quality
    final ratio = quality / 100.0;
    // At 100% quality, keep ~90% of size
    // At 0% quality, reduce to ~10% of size
    final estimatedRatio = 0.1 + (0.8 * ratio);
    return (originalSize * estimatedRatio).round();
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Calculate compression ratio
  static String calculateCompressionRatio(int original, int compressed) {
    if (original == 0) return '0%';
    final ratio = ((1 - compressed / original) * 100);
    return '${ratio.toStringAsFixed(1)}%';
  }
}
