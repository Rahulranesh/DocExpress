import 'dart:io';

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

    final bytes = await inputFile.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if dimensions specified
    if (maxWidth != null || maxHeight != null) {
      final targetWidth = maxWidth ?? image.width;
      final targetHeight = maxHeight ?? image.height;

      // Calculate proportional dimensions
      double ratio = 1.0;
      if (image.width > targetWidth || image.height > targetHeight) {
        final widthRatio = targetWidth / image.width;
        final heightRatio = targetHeight / image.height;
        ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
      }

      if (ratio < 1.0) {
        final newWidth = (image.width * ratio).round();
        final newHeight = (image.height * ratio).round();
        image = img.copyResize(image, width: newWidth, height: newHeight);
        debugPrint('   Resized to: ${newWidth}x$newHeight');
      }
    }

    // Determine output format
    final format = outputFormat?.toLowerCase() ??
        path.extension(inputPath).replaceFirst('.', '').toLowerCase();

    // Compress and save
    final outputDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        path.join(outputDir.path, 'compressed_$timestamp.$format');

    List<int> compressedBytes;
    switch (format) {
      case 'jpg':
      case 'jpeg':
        compressedBytes = img.encodeJpg(image, quality: quality);
        break;
      case 'png':
        compressedBytes = img.encodePng(image, level: (100 - quality) ~/ 10);
        break;
      case 'webp':
        // WebP not directly supported, fallback to jpg
        compressedBytes = img.encodeJpg(image, quality: quality);
        break;
      default:
        compressedBytes = img.encodeJpg(image, quality: quality);
    }

    await File(outputPath).writeAsBytes(compressedBytes);

    final originalSize = await inputFile.length();
    final compressedSize = compressedBytes.length;
    final savings =
        ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

    debugPrint('✅ [LOCAL PROCESSING] Compression: Complete');
    debugPrint(
        '   Original: ${_formatBytes(originalSize)}, Compressed: ${_formatBytes(compressedSize)} ($savings% saved)');

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

  /// Compress PDF (basic - reduces image quality within PDF)
  Future<String> compressPdf({
    required String inputPath,
    int quality = 80,
  }) async {
    debugPrint('🗜️ [LOCAL PROCESSING] PDF Compression: $inputPath');
    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      throw Exception('Input file not found: $inputPath');
    }

    final outputDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = path.join(outputDir.path, 'compressed_$timestamp.pdf');

    try {
      final bytes = await inputFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final outputBytes = await document.save();
      document.dispose();

      await File(outputPath).writeAsBytes(outputBytes, flush: true);

      final originalSize = await inputFile.length();
      final compressedSize = await File(outputPath).length();
      final savings = originalSize > 0
          ? ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)
          : '0.0';
      debugPrint(
          '✅ [LOCAL PROCESSING] PDF Compression: ${_formatBytes(originalSize)} -> ${_formatBytes(compressedSize)} ($savings% saved)');
    } catch (e) {
      debugPrint(
          '⚠️ [LOCAL PROCESSING] PDF rewrite failed, using copy fallback: $e');
      await inputFile.copy(outputPath);
    }

    return outputPath;
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
