import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Local Image Service - handles all image operations offline
class LocalImageService {
  static const _uuid = Uuid();

  /// Get temporary directory for processing
  Future<Directory> _getTempDir() async {
    final dir = await getTemporaryDirectory();
    final processingDir =
        Directory(path.join(dir.path, 'docxpress_processing'));
    if (!await processingDir.exists()) {
      await processingDir.create(recursive: true);
    }
    return processingDir;
  }

  /// Get output directory for saving files
  Future<Directory> _getOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(path.join(dir.path, 'docxpress_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Compress an image
  /// Returns the path to the compressed image
  Future<String> compressImage({
    required String inputPath,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if needed
    if (maxWidth != null || maxHeight != null) {
      image = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );
    }

    // Encode with quality
    final outputBytes = img.encodeJpg(image, quality: quality);

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'compressed_${_uuid.v4()}.jpg',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Convert image format
  Future<String> convertFormat({
    required String inputPath,
    required String targetFormat,
    int quality = 80,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    Uint8List outputBytes;
    String extension;

    switch (targetFormat.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        outputBytes = img.encodeJpg(image, quality: quality);
        extension = 'jpg';
        break;
      case 'png':
        outputBytes = img.encodePng(image);
        extension = 'png';
        break;
      case 'webp':
        // Note: image package has limited webp support
        outputBytes = img.encodeJpg(image, quality: quality);
        extension = 'jpg'; // Fallback to jpg
        break;
      case 'gif':
        // GIF encoding is slow, run in background isolate
        outputBytes = await compute(_encodeGifInIsolate, image);
        extension = 'gif';
        break;
      case 'bmp':
        outputBytes = img.encodeBmp(image);
        extension = 'bmp';
        break;
      case 'tiff':
      case 'tif':
        outputBytes = img.encodeTiff(image);
        extension = 'tiff';
        break;
      default:
        outputBytes = img.encodeJpg(image, quality: quality);
        extension = 'jpg';
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'converted_${_uuid.v4()}.$extension',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Resize image
  Future<String> resizeImage({
    required String inputPath,
    int? width,
    int? height,
    bool maintainAspect = true,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    if (width == null && height == null) {
      throw ArgumentError('Width or height must be provided');
    }

    image = img.copyResize(
      image,
      width: width,
      height: height,
      maintainAspect: maintainAspect,
    );

    final extension = path.extension(inputPath).replaceFirst('.', '');
    Uint8List outputBytes;

    if (extension.toLowerCase() == 'png') {
      outputBytes = img.encodePng(image);
    } else {
      outputBytes = img.encodeJpg(image, quality: 90);
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'resized_${_uuid.v4()}.${extension.isNotEmpty ? extension : 'jpg'}',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Rotate image
  Future<String> rotateImage({
    required String inputPath,
    required int degrees,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Normalize degrees to 0, 90, 180, 270
    final normalizedDegrees = degrees % 360;

    switch (normalizedDegrees) {
      case 90:
        image = img.copyRotate(image, angle: 90);
        break;
      case 180:
        image = img.copyRotate(image, angle: 180);
        break;
      case 270:
        image = img.copyRotate(image, angle: 270);
        break;
      default:
        image = img.copyRotate(image, angle: normalizedDegrees.toDouble());
    }

    final extension = path.extension(inputPath).replaceFirst('.', '');
    Uint8List outputBytes;

    if (extension.toLowerCase() == 'png') {
      outputBytes = img.encodePng(image);
    } else {
      outputBytes = img.encodeJpg(image, quality: 90);
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'rotated_${_uuid.v4()}.${extension.isNotEmpty ? extension : 'jpg'}',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Crop image
  Future<String> cropImage({
    required String inputPath,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    image = img.copyCrop(image, x: x, y: y, width: width, height: height);

    final extension = path.extension(inputPath).replaceFirst('.', '');
    Uint8List outputBytes;

    if (extension.toLowerCase() == 'png') {
      outputBytes = img.encodePng(image);
    } else {
      outputBytes = img.encodeJpg(image, quality: 90);
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'cropped_${_uuid.v4()}.${extension.isNotEmpty ? extension : 'jpg'}',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Apply grayscale filter
  Future<String> grayscaleImage({
    required String inputPath,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    image = img.grayscale(image);

    final extension = path.extension(inputPath).replaceFirst('.', '');
    Uint8List outputBytes;

    if (extension.toLowerCase() == 'png') {
      outputBytes = img.encodePng(image);
    } else {
      outputBytes = img.encodeJpg(image, quality: 90);
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'grayscale_${_uuid.v4()}.${extension.isNotEmpty ? extension : 'jpg'}',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Merge multiple images vertically or horizontally
  Future<String> mergeImages({
    required List<String> inputPaths,
    bool vertical = true,
    int gap = 0,
    int quality = 90,
  }) async {
    if (inputPaths.isEmpty) {
      throw ArgumentError('At least one image is required');
    }

    debugPrint('🔄 [IMAGE SERVICE] Merging ${inputPaths.length} images...');

    // Read all image bytes first (I/O on main thread is fine)
    final imageBytesList = <Uint8List>[];
    for (final inputPath in inputPaths) {
      final file = File(inputPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        imageBytesList.add(bytes);
      }
    }

    if (imageBytesList.isEmpty) {
      throw Exception('No valid images found');
    }

    // Run the heavy image processing in an isolate
    final outputBytes = await compute(
      _mergeImagesInIsolate,
      _MergeImagesParams(
        imageBytesList: imageBytesList,
        vertical: vertical,
        gap: gap,
        quality: quality,
      ),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'merged_${_uuid.v4()}.jpg',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    debugPrint('✅ [IMAGE SERVICE] Images merged successfully');
    return outputPath;
  }

  /// Get image info
  Future<Map<String, dynamic>> getImageInfo(String inputPath) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();
    final fileStat = await inputFile.stat();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return {
      'width': image.width,
      'height': image.height,
      'format': path.extension(inputPath).replaceFirst('.', '').toUpperCase(),
      'size': fileStat.size,
      'sizeFormatted': _formatBytes(fileStat.size),
    };
  }

  /// Flip image horizontally or vertically
  Future<String> flipImage({
    required String inputPath,
    required bool horizontal,
  }) async {
    final inputFile = File(inputPath);
    final bytes = await inputFile.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    if (horizontal) {
      image = img.flipHorizontal(image);
    } else {
      image = img.flipVertical(image);
    }

    final extension = path.extension(inputPath).replaceFirst('.', '');
    Uint8List outputBytes;

    if (extension.toLowerCase() == 'png') {
      outputBytes = img.encodePng(image);
    } else {
      outputBytes = img.encodeJpg(image, quality: 90);
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'flipped_${_uuid.v4()}.${extension.isNotEmpty ? extension : 'jpg'}',
    );

    await File(outputPath).writeAsBytes(outputBytes);
    return outputPath;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Top-level function for GIF encoding in isolate
/// Must be top-level or static for compute() to work
Uint8List _encodeGifInIsolate(img.Image image) {
  // Reduce colors for GIF (GIF only supports 256 colors)
  final quantized = img.quantize(image, numberOfColors: 256);
  final gifEncoder = img.GifEncoder();
  gifEncoder.addFrame(quantized, duration: 100);
  return Uint8List.fromList(gifEncoder.finish()!);
}

/// Parameters for merge images isolate function
class _MergeImagesParams {
  final List<Uint8List> imageBytesList;
  final bool vertical;
  final int gap;
  final int quality;

  _MergeImagesParams({
    required this.imageBytesList,
    required this.vertical,
    required this.gap,
    required this.quality,
  });
}

/// Top-level function for merging images in isolate
Uint8List _mergeImagesInIsolate(_MergeImagesParams params) {
  final images = <img.Image>[];

  for (final bytes in params.imageBytesList) {
    final image = img.decodeImage(bytes);
    if (image != null) {
      images.add(image);
    }
  }

  if (images.isEmpty) {
    throw Exception('No valid images found');
  }

  int totalWidth;
  int totalHeight;

  if (params.vertical) {
    totalWidth = images.map((i) => i.width).reduce((a, b) => a > b ? a : b);
    totalHeight = images.map((i) => i.height).reduce((a, b) => a + b) +
        (params.gap * (images.length - 1));
  } else {
    totalWidth = images.map((i) => i.width).reduce((a, b) => a + b) +
        (params.gap * (images.length - 1));
    totalHeight = images.map((i) => i.height).reduce((a, b) => a > b ? a : b);
  }

  final mergedImage = img.Image(width: totalWidth, height: totalHeight);

  // Fill with white background
  img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));

  int offset = 0;
  for (final image in images) {
    if (params.vertical) {
      img.compositeImage(mergedImage, image, dstX: 0, dstY: offset);
      offset += image.height + params.gap;
    } else {
      img.compositeImage(mergedImage, image, dstX: offset, dstY: 0);
      offset += image.width + params.gap;
    }
  }

  return Uint8List.fromList(
      img.encodeJpg(mergedImage, quality: params.quality));
}
