import 'dart:io';
import 'dart:ui' show Rect;
import 'dart:math' show Point;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Local OCR Service - handles text extraction from images offline
class LocalOcrService {
  static const _uuid = Uuid();
  TextRecognizer? _textRecognizer;

  /// Initialize the text recognizer
  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
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

  /// Extract text from a single image
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Extract text from multiple images
  Future<String> extractTextFromImages(List<String> imagePaths) async {
    final buffer = StringBuffer();
    
    for (int i = 0; i < imagePaths.length; i++) {
      if (i > 0) {
        buffer.writeln('\n--- Page ${i + 1} ---\n');
      }
      
      final text = await extractTextFromImage(imagePaths[i]);
      buffer.writeln(text);
    }
    
    return buffer.toString();
  }

  /// Extract text and save to file
  Future<String> extractTextToFile({
    required String imagePath,
    String? outputName,
  }) async {
    final text = await extractTextFromImage(imagePath);
    
    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${outputName ?? 'extracted_text'}_${_uuid.v4()}.txt',
    );
    
    await File(outputPath).writeAsString(text);
    return outputPath;
  }

  /// Extract text from images and save to file
  Future<String> extractTextsToFile({
    required List<String> imagePaths,
    String? outputName,
  }) async {
    final text = await extractTextFromImages(imagePaths);
    
    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${outputName ?? 'extracted_text'}_${_uuid.v4()}.txt',
    );
    
    await File(outputPath).writeAsString(text);
    return outputPath;
  }

  /// Get detailed text blocks with positions
  Future<List<TextBlockInfo>> extractTextBlocks(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    return recognizedText.blocks.map((block) {
      return TextBlockInfo(
        text: block.text,
        boundingBox: block.boundingBox,
        cornerPoints: block.cornerPoints,
        lines: block.lines.map((line) {
          return TextLineInfo(
            text: line.text,
            boundingBox: line.boundingBox,
            elements: line.elements.map((element) {
              return TextElementInfo(
                text: element.text,
                boundingBox: element.boundingBox,
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

/// Text block information
class TextBlockInfo {
  final String text;
  final Rect boundingBox;
  final List<Point<int>> cornerPoints;
  final List<TextLineInfo> lines;

  TextBlockInfo({
    required this.text,
    required this.boundingBox,
    required this.cornerPoints,
    required this.lines,
  });
}

/// Text line information
class TextLineInfo {
  final String text;
  final Rect boundingBox;
  final List<TextElementInfo> elements;

  TextLineInfo({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });
}

/// Text element (word) information
class TextElementInfo {
  final String text;
  final Rect boundingBox;

  TextElementInfo({
    required this.text,
    required this.boundingBox,
  });
}
