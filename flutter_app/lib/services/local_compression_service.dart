import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:video_compress/video_compress.dart';

/// Local Compression Service - handles image and video compression locally
class LocalCompressionService {
  /// Initialize the service
  Future<void> init() async {
    debugPrint('🗜️ [LOCAL PROCESSING] Compression: Service initialized');
  }

  // ==================== Image Compression ====================

  /// Compress a single image
  Future<String> compressImage({
    required String inputPath,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
    String? outputFormat,
  }) async {
    debugPrint(
        '🗜️ [LOCAL PROCESSING] Compression: Compressing image - $inputPath');
    debugPrint(
        '   Quality: $quality, MaxWidth: $maxWidth, MaxHeight: $maxHeight');

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $inputPath');
    }

    final originalSize = await inputFile.length();
    final bytes = await inputFile.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Always resize to reduce size - scale down to max 1920x1080
    final targetMaxWidth = maxWidth ?? 1920;
    final targetMaxHeight = maxHeight ?? 1080;

    if (image.width > targetMaxWidth || image.height > targetMaxHeight) {
      final widthRatio = targetMaxWidth / image.width;
      final heightRatio = targetMaxHeight / image.height;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      final newWidth = (image.width * ratio).round();
      final newHeight = (image.height * ratio).round();
      image = img.copyResize(image, width: newWidth, height: newHeight);
      debugPrint('   Resized to: ${newWidth}x$newHeight');
    }

    // Determine output format and a compatible output extension.
    // Keep extension aligned with the actual encoder so gallery/apps read it correctly.
    final requestedFormat = outputFormat?.toLowerCase() ??
        path.extension(inputPath).replaceFirst('.', '').toLowerCase();

    String encoder;
    String outputExtension;
    switch (requestedFormat) {
      case 'png':
        encoder = 'png';
        outputExtension = 'png';
        break;
      case 'jpg':
      case 'jpeg':
        encoder = 'jpg';
        outputExtension = 'jpg';
        break;
      case 'webp':
        encoder = 'jpg';
        outputExtension = 'jpg';
        break;
      default:
        encoder = 'jpg';
        outputExtension = 'jpg';
    }

    // Compress and save
    final outputDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
      path.join(outputDir.path, 'compressed_$timestamp.$outputExtension');

    List<int> compressedBytes;
    
    // Use lower quality for practical compression while staying in valid JPEG range.
    final compressionQuality = min(95, max(10, quality <= 30 ? quality : quality - 20));
    
    switch (encoder) {
      case 'jpg':
        // JPEG: quality 30-80 for good compression
        compressedBytes = img.encodeJpg(image, quality: compressionQuality);
        break;
      case 'png':
        // PNG compression level 0-9 (higher = smaller/slower)
        final level = ((100 - compressionQuality) / 100 * 9).round().clamp(0, 9);
        compressedBytes = img.encodePng(image, level: level);
        break;
      default:
        compressedBytes = img.encodeJpg(image, quality: compressionQuality);
    }

    await File(outputPath).writeAsBytes(compressedBytes);

    final compressedSize = compressedBytes.length;
    final savings =
        ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

    debugPrint('✅ [LOCAL PROCESSING] Compression: Complete');
    debugPrint(
        '   Original: ${_formatBytes(originalSize)}, Compressed: ${_formatBytes(compressedSize)} ($savings% saved)');

    if (compressedSize >= originalSize) {
      debugPrint('⚠️ [LOCAL PROCESSING] Compression not effective, keeping processed output for consistency');
    }

    return outputPath;
  }

  /// Compress multiple images
  Future<List<String>> compressImages({
    required List<String> inputPaths,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
    String? outputFormat,
  }) async {
    debugPrint(
        '🗜️ [LOCAL PROCESSING] Compression: Batch compressing ${inputPaths.length} images');
    final results = <String>[];

    for (final inputPath in inputPaths) {
      try {
        final outputPath = await compressImage(
          inputPath: inputPath,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          outputFormat: outputFormat,
        );
        results.add(outputPath);
      } catch (e) {
        debugPrint(
            '❌ [LOCAL PROCESSING] Compression: Failed to compress $inputPath: $e');
      }
    }

    debugPrint(
        '✅ [LOCAL PROCESSING] Compression: Batch complete - ${results.length}/${inputPaths.length} successful');
    return results;
  }

  // ==================== Video Compression ====================

  /// Check if video compression is available
  bool get isVideoCompressionAvailable => true;

  /// Compress video using video_compress package
  Future<String> compressVideo({
    required String inputPath,
    String preset = 'medium',
    String? resolution,
    int? bitrate,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] Video Compression: Starting...');
    debugPrint('   Input: $inputPath');
    debugPrint('   Preset: $preset');

    try {
      // Map preset to quality
      final quality = preset == 'high'
          ? VideoQuality.HighestQuality
          : preset == 'low'
              ? VideoQuality.LowQuality
              : VideoQuality.MediumQuality;

      // Start compression
      final info = await VideoCompress.compressVideo(
        inputPath,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        throw Exception('Video compression failed - no output file');
      }

      final outputPath = info.file!.path;
      final originalSize = File(inputPath).lengthSync();
      final compressedSize = info.filesize ?? File(outputPath).lengthSync();
      final reduction = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);

      debugPrint('✅ [LOCAL PROCESSING] Video compressed successfully');
      debugPrint('   Output: $outputPath');
      debugPrint('   Original: ${_formatBytes(originalSize)}');
      debugPrint('   Compressed: ${_formatBytes(compressedSize)}');
      debugPrint('   Reduction: $reduction%');

      return outputPath;
    } catch (e) {
      debugPrint('❌ [LOCAL PROCESSING] Video compression failed: $e');

      // Fallback: Just copy the file
      debugPrint('⚠️ [LOCAL PROCESSING] Falling back to file copy');
      final inputFile = File(inputPath);
      final outputDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = path.basenameWithoutExtension(inputPath);
      final ext = path.extension(inputPath);
      final outputPath =
          path.join(outputDir.path, '${fileName}_compressed_$timestamp$ext');

      await inputFile.copy(outputPath);

      debugPrint('✅ [LOCAL PROCESSING] Video copied (compression unavailable)');
      return outputPath;
    }
  }

  /// Get video info (placeholder)
  Future<Map<String, dynamic>> getVideoInfo(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();

    return {
      'path': filePath,
      'size': stat.size,
      'sizeFormatted': _formatBytes(stat.size),
      'note': 'Full video metadata requires additional packages',
    };
  }

  // ==================== PDF Compression ====================

  /// Compress PDF (reduces size via document optimization)
  Future<String> compressPdf({
    required String inputPath,
    int quality = 80,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] PDF Compression: $inputPath');
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $inputPath');
    }

    final originalSize = await inputFile.length();

    final outputDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = path.join(outputDir.path, 'compressed_$timestamp.pdf');

    try {
      final bytes = await inputFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      
      // Note: syncfusion_flutter_pdf has limited compression options
      // The library optimizes streams but doesn't compress images directly
      final outputBytes = await document.save();
      document.dispose();

      await File(outputPath).writeAsBytes(outputBytes, flush: true);

      final compressedSize = await File(outputPath).length();
      final savings = originalSize > 0
          ? ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)
          : '0.0';
      
      debugPrint('ℹ️ [LOCAL PROCESSING] PDF: Document optimization attempted');
      debugPrint(
          '   Original: ${_formatBytes(originalSize)} → Processed: ${_formatBytes(compressedSize)} ($savings%)');

      if (compressedSize > (originalSize * 0.95)) {
        debugPrint(
          'ℹ️ [LOCAL PROCESSING] PDF: Compression gain is small; '
          'backend optimization is preferred for real reduction',
        );
      }

      debugPrint(
          '✅ [LOCAL PROCESSING] PDF Compression: Complete (${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)})');
      return outputPath;
    } catch (e) {
      debugPrint('❌ [LOCAL PROCESSING] PDF: Optimization failed ($e)');
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Estimate compressed size
  int estimateCompressedSize(int originalSize, int quality) {
    // Rough estimation based on quality
    final ratio = quality / 100;
    return (originalSize * ratio * 0.7).round();
  }
}
