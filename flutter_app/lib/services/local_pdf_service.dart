import 'dart:io';
import 'dart:ui' show Offset;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Local PDF Service - handles PDF creation operations
/// Uses pdf package for PDF creation from images and text
///
/// NOTE: For advanced operations (merge, split, watermark, compress, extract),
/// consider using a backend API service:
/// - Node.js with pdf-lib or PDFKit
/// - Python with PyPDF2 or pdfplumber
/// - Cloud services: AWS Textract, Google Cloud Vision
class LocalPdfService {
  static const _uuid = Uuid();

  /// Get output directory for saving files
  Future<Directory> _getOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(path.join(dir.path, 'docxpress_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Convert images to PDF
  Future<String> imagesToPdf({
    required List<String> imagePaths,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    String? title,
  }) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Decode and re-encode as JPEG to ensure compatibility
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) continue;

      final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
      final pdfImage = pw.MemoryImage(jpegBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'images_to_pdf'}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    return outputPath;
  }

  /// Create PDF from text
  Future<String> textToPdf({
    required String text,
    String? title,
    double fontSize = 12,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: title != null
            ? (context) => pw.Header(
                  level: 0,
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                )
            : null,
        build: (context) => [
          pw.Paragraph(
            text: text,
            style: pw.TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'text_to_pdf'}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    return outputPath;
  }

  /// Create a simple PDF with custom content
  Future<String> createPdf({
    required List<PdfContentItem> contents,
    String? title,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();

    final widgets = <pw.Widget>[];

    if (title != null) {
      widgets.add(
        pw.Header(
          level: 0,
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 20));
    }

    for (final content in contents) {
      switch (content.type) {
        case PdfContentType.text:
          widgets.add(
            pw.Paragraph(
              text: content.data,
              style: pw.TextStyle(fontSize: content.fontSize ?? 12),
            ),
          );
          break;
        case PdfContentType.heading:
          widgets.add(
            pw.Header(
              level: content.level ?? 1,
              child: pw.Text(
                content.data,
                style: pw.TextStyle(
                  fontSize: content.fontSize ?? 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case PdfContentType.image:
          try {
            final imageFile = File(content.data);
            final imageBytes = await imageFile.readAsBytes();
            final decodedImage = img.decodeImage(imageBytes);
            if (decodedImage != null) {
              final jpegBytes = img.encodeJpg(decodedImage, quality: 85);
              widgets.add(
                pw.Image(pw.MemoryImage(jpegBytes)),
              );
            }
          } catch (e) {
            // Skip invalid images
          }
          break;
        case PdfContentType.divider:
          widgets.add(pw.Divider());
          break;
        case PdfContentType.spacer:
          widgets.add(pw.SizedBox(height: content.fontSize ?? 20));
          break;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => widgets,
      ),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'document'}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    return outputPath;
  }

  /// Compress PDF - Use backend API for this operation
  /// Recommended: Use a server endpoint with pdf-lib or PyPDF2
  Future<String> compressPdf({
    required String inputPath,
    int quality = 60,
  }) async {
    throw UnimplementedError('PDF compression requires backend API. '
        'Consider using Node.js with pdf-lib or Python with PyPDF2. '
        'Alternative: Use cloud services like AWS Lambda with pdf-lib.');
  }

  /// Add watermark to PDF - Use backend API for this operation
  /// Recommended: Use a server endpoint with pdf-lib (Node.js) or reportlab (Python)
  Future<String> addWatermark({
    required String inputPath,
    required String watermarkText,
    double opacity = 0.3,
    double fontSize = 50,
  }) async {
    throw UnimplementedError('PDF watermarking requires backend API. '
        'Consider using Node.js with pdf-lib or Python with reportlab. '
        'Example API endpoint: POST /api/pdf/watermark');
  }

  /// Get PDF file info (basic - without page count)
  /// For page count, use backend API
  Future<Map<String, dynamic>> getPdfInfo(String inputPath) async {
    final file = File(inputPath);

    if (!await file.exists()) {
      throw Exception('PDF file not found');
    }

    final stat = await file.stat();

    return {
      'path': inputPath,
      'name': path.basename(inputPath),
      'size': stat.size,
      'sizeFormatted': _formatBytes(stat.size),
      'modified': stat.modified.toIso8601String(),
      'pageCount': 0, // Requires backend API to get accurate page count
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Merge multiple PDFs into one using Syncfusion
  Future<String> mergePdfs({
    required List<String> pdfPaths,
    String? title,
  }) async {
    debugPrint('📄 [PDF SERVICE] Merging ${pdfPaths.length} PDFs');

    if (pdfPaths.isEmpty) {
      throw Exception('No PDF files provided');
    }

    // Verify all files exist
    for (final pdfPath in pdfPaths) {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'merged'}_${_uuid.v4()}.pdf',
    );

    // Create a new PDF document for merging
    final mergedDocument = sf.PdfDocument();

    for (final pdfPath in pdfPaths) {
      final bytes = await File(pdfPath).readAsBytes();
      final sourceDocument = sf.PdfDocument(inputBytes: bytes);

      // Import all pages from source document
      for (int i = 0; i < sourceDocument.pages.count; i++) {
        final template = sourceDocument.pages[i].createTemplate();
        final page = mergedDocument.pages.add();
        page.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          sourceDocument.pages[i].getClientSize(),
        );
      }

      sourceDocument.dispose();
    }

    // Save merged document
    final outputBytes = await mergedDocument.save();
    await File(outputPath).writeAsBytes(outputBytes);
    mergedDocument.dispose();

    debugPrint('✅ [PDF SERVICE] PDFs merged successfully: $outputPath');
    return outputPath;
  }

  /// Split PDF into individual pages or specific page ranges using Syncfusion
  Future<List<String>> splitPdf({
    required String pdfPath,
    int? pageCount,
    List<int>? pages,
    int? startPage,
    int? endPage,
  }) async {
    debugPrint('📄 [PDF SERVICE] Splitting PDF: $pdfPath');

    final inputFile = File(pdfPath);
    if (!await inputFile.exists()) {
      throw Exception('PDF file not found');
    }

    final outputDir = await _getOutputDir();
    final bytes = await inputFile.readAsBytes();
    final sourceDocument = sf.PdfDocument(inputBytes: bytes);
    final totalPages = sourceDocument.pages.count;

    List<String> results = [];

    if (pages != null && pages.isNotEmpty) {
      // Extract specific pages
      for (final pageNum in pages) {
        if (pageNum < 1 || pageNum > totalPages) continue;

        final newDoc = sf.PdfDocument();
        final sourcePage = sourceDocument.pages[pageNum - 1];
        final template = sourcePage.createTemplate();
        final newPage = newDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          sourcePage.getClientSize(),
        );

        final outputPath = path.join(
          outputDir.path,
          'split_page${pageNum}_${_uuid.v4()}.pdf',
        );
        final outputBytes = await newDoc.save();
        await File(outputPath).writeAsBytes(outputBytes);
        newDoc.dispose();

        results.add(outputPath);
      }
    } else if (startPage != null || endPage != null) {
      // Extract page range
      final start = (startPage ?? 1).clamp(1, totalPages);
      final end = (endPage ?? totalPages).clamp(1, totalPages);

      final newDoc = sf.PdfDocument();
      for (int i = start; i <= end; i++) {
        final sourcePage = sourceDocument.pages[i - 1];
        final template = sourcePage.createTemplate();
        final newPage = newDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          sourcePage.getClientSize(),
        );
      }

      final outputPath = path.join(
        outputDir.path,
        'split_pages$start-${end}_${_uuid.v4()}.pdf',
      );
      final outputBytes = await newDoc.save();
      await File(outputPath).writeAsBytes(outputBytes);
      newDoc.dispose();

      results.add(outputPath);
    } else {
      // Split into individual pages
      for (int i = 0; i < totalPages; i++) {
        final newDoc = sf.PdfDocument();
        final sourcePage = sourceDocument.pages[i];
        final template = sourcePage.createTemplate();
        final newPage = newDoc.pages.add();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          sourcePage.getClientSize(),
        );

        final outputPath = path.join(
          outputDir.path,
          'split_page${i + 1}_${_uuid.v4()}.pdf',
        );
        final outputBytes = await newDoc.save();
        await File(outputPath).writeAsBytes(outputBytes);
        newDoc.dispose();

        results.add(outputPath);
      }
    }

    sourceDocument.dispose();

    if (results.isEmpty) {
      throw Exception('Failed to split PDF');
    }

    debugPrint('✅ [PDF SERVICE] PDF split into ${results.length} files');
    return results;
  }

  /// Split PDF and return single file path (for compatibility)
  Future<String> splitPdfSingle({
    required String pdfPath,
    List<int>? pages,
    int? startPage,
    int? endPage,
  }) async {
    final results = await splitPdf(
      pdfPath: pdfPath,
      pages: pages,
      startPage: startPage,
      endPage: endPage,
    );
    return results.first;
  }

  /// Reorder PDF pages using Syncfusion
  Future<String> reorderPages({
    required String pdfPath,
    required List<int> pageOrder,
  }) async {
    debugPrint('📄 [PDF SERVICE] Reordering PDF pages: $pageOrder');

    final inputFile = File(pdfPath);
    if (!await inputFile.exists()) {
      throw Exception('PDF file not found');
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'reordered_${_uuid.v4()}.pdf',
    );

    final bytes = await inputFile.readAsBytes();
    final sourceDocument = sf.PdfDocument(inputBytes: bytes);
    final totalPages = sourceDocument.pages.count;

    // Create new document with reordered pages
    final newDoc = sf.PdfDocument();

    for (final pageNum in pageOrder) {
      if (pageNum < 1 || pageNum > totalPages) continue;

      final sourcePage = sourceDocument.pages[pageNum - 1];
      final template = sourcePage.createTemplate();
      final newPage = newDoc.pages.add();
      newPage.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        sourcePage.getClientSize(),
      );
    }

    final outputBytes = await newDoc.save();
    await File(outputPath).writeAsBytes(outputBytes);

    sourceDocument.dispose();
    newDoc.dispose();

    debugPrint('✅ [PDF SERVICE] PDF pages reordered successfully: $outputPath');
    return outputPath;
  }

  /// Remove specific pages from PDF using Syncfusion
  Future<String> removePages({
    required String pdfPath,
    required List<int> pagesToRemove,
  }) async {
    debugPrint('📄 [PDF SERVICE] Removing pages from PDF: $pagesToRemove');

    final inputFile = File(pdfPath);
    if (!await inputFile.exists()) {
      throw Exception('PDF file not found');
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'removed_pages_${_uuid.v4()}.pdf',
    );

    final bytes = await inputFile.readAsBytes();
    final sourceDocument = sf.PdfDocument(inputBytes: bytes);
    final totalPages = sourceDocument.pages.count;

    // Create new document without removed pages
    final newDoc = sf.PdfDocument();
    final removeSet = pagesToRemove.toSet();

    for (int i = 1; i <= totalPages; i++) {
      if (removeSet.contains(i)) continue;

      final sourcePage = sourceDocument.pages[i - 1];
      final template = sourcePage.createTemplate();
      final newPage = newDoc.pages.add();
      newPage.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        sourcePage.getClientSize(),
      );
    }

    final outputBytes = await newDoc.save();
    await File(outputPath).writeAsBytes(outputBytes);

    sourceDocument.dispose();
    newDoc.dispose();

    debugPrint('✅ [PDF SERVICE] Pages removed successfully: $outputPath');
    return outputPath;
  }

  /// Rotate PDF pages using Syncfusion
  Future<String> rotatePages({
    required String pdfPath,
    required int rotationAngle,
    List<int>? pageNumbers,
  }) async {
    debugPrint('📄 [PDF SERVICE] Rotating PDF pages by $rotationAngle degrees');

    final inputFile = File(pdfPath);
    if (!await inputFile.exists()) {
      throw Exception('PDF file not found');
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      'rotated_${_uuid.v4()}.pdf',
    );

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);

    // Convert rotation angle to PdfPageRotateAngle
    sf.PdfPageRotateAngle angle;
    switch (rotationAngle % 360) {
      case 90:
        angle = sf.PdfPageRotateAngle.rotateAngle90;
        break;
      case 180:
        angle = sf.PdfPageRotateAngle.rotateAngle180;
        break;
      case 270:
        angle = sf.PdfPageRotateAngle.rotateAngle270;
        break;
      default:
        angle = sf.PdfPageRotateAngle.rotateAngle0;
    }

    // Apply rotation to specified pages or all pages
    if (pageNumbers != null && pageNumbers.isNotEmpty) {
      for (final pageNum in pageNumbers) {
        if (pageNum >= 1 && pageNum <= document.pages.count) {
          document.pages[pageNum - 1].rotation = angle;
        }
      }
    } else {
      for (int i = 0; i < document.pages.count; i++) {
        document.pages[i].rotation = angle;
      }
    }

    final outputBytes = await document.save();
    await File(outputPath).writeAsBytes(outputBytes);
    document.dispose();

    debugPrint('✅ [PDF SERVICE] Pages rotated successfully: $outputPath');
    return outputPath;
  }

  /// Get PDF page count using Syncfusion
  Future<int?> getPageCount(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      debugPrint('⚠️ [PDF SERVICE] Failed to get page count: $e');
      return null;
    }
  }

  /// Check if PDF is valid using Syncfusion
  Future<bool> isValidPdf(String pdfPath) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      document.dispose();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extract images from PDF by rendering pages as images
  /// Returns list of image file paths
  ///
  /// NOTE: This feature requires backend support or native platform code
  /// Syncfusion Flutter PDF doesn't support page rasterization
  /// Consider using a backend service or platform-specific implementation
  Future<List<String>> extractImagesFromPdf({
    required String pdfPath,
  }) async {
    debugPrint('📄 [PDF SERVICE] Extract images feature not available');
    debugPrint(
        '⚠️ This feature requires backend support or native implementation');

    // Return empty list - feature not implemented
    return [];

    /* IMPLEMENTATION NOTE:
     * To implement this feature, you can:
     * 1. Use a backend service (Node.js with pdf-lib, Python with pdf2image)
     * 2. Use platform-specific code (Android: PdfRenderer, iOS: PDFKit)
     * 3. Use a cloud service (AWS Textract, Google Cloud Vision)
     */
  }

  /// Extract text from PDF
  /// Returns extracted text content
  Future<String> extractTextFromPdf({
    required String pdfPath,
  }) async {
    debugPrint('📄 [PDF SERVICE] Extracting text from PDF');

    final inputFile = File(pdfPath);
    if (!await inputFile.exists()) {
      throw Exception('PDF file not found');
    }

    final bytes = await inputFile.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);

    final StringBuffer textBuffer = StringBuffer();

    try {
      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final text = sf.PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);

        if (text.isNotEmpty) {
          textBuffer.writeln(text);
          if (i < document.pages.count - 1) {
            textBuffer.writeln('\n--- Page ${i + 1} ---\n');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PDF SERVICE] Error extracting text: $e');
    } finally {
      document.dispose();
    }

    final extractedText = textBuffer.toString();
    debugPrint(
        '✅ [PDF SERVICE] Extracted ${extractedText.length} characters from PDF');
    return extractedText;
  }

  /// Extract text and images from PDF
  /// Returns map with text and image paths
  Future<Map<String, dynamic>> extractContentFromPdf({
    required String pdfPath,
  }) async {
    debugPrint('📄 [PDF SERVICE] Extracting content from PDF');

    final text = await extractTextFromPdf(pdfPath: pdfPath);
    final images = await extractImagesFromPdf(pdfPath: pdfPath);

    return {
      'text': text,
      'images': images,
      'hasText': text.isNotEmpty,
      'hasImages': images.isNotEmpty,
    };
  }
}

/// Content item for creating PDFs
class PdfContentItem {
  final PdfContentType type;
  final String data;
  final double? fontSize;
  final int? level;

  PdfContentItem({
    required this.type,
    required this.data,
    this.fontSize,
    this.level,
  });

  factory PdfContentItem.text(String text, {double fontSize = 12}) {
    return PdfContentItem(
      type: PdfContentType.text,
      data: text,
      fontSize: fontSize,
    );
  }

  factory PdfContentItem.heading(String text,
      {int level = 1, double fontSize = 18}) {
    return PdfContentItem(
      type: PdfContentType.heading,
      data: text,
      fontSize: fontSize,
      level: level,
    );
  }

  factory PdfContentItem.image(String imagePath) {
    return PdfContentItem(
      type: PdfContentType.image,
      data: imagePath,
    );
  }

  factory PdfContentItem.divider() {
    return PdfContentItem(
      type: PdfContentType.divider,
      data: '',
    );
  }

  factory PdfContentItem.spacer({double height = 20}) {
    return PdfContentItem(
      type: PdfContentType.spacer,
      data: '',
      fontSize: height,
    );
  }
}

enum PdfContentType {
  text,
  heading,
  image,
  divider,
  spacer,
}
