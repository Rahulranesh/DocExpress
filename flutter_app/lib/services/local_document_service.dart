import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'local_office_service.dart';
import 'local_pdf_service.dart';

/// Local Document Service - handles document conversions offline
/// Note: Full document conversion (DOCX, PPTX) requires external packages
/// This service provides what's possible with local processing
class LocalDocumentService {
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

  /// Check if a conversion is supported offline
  bool isConversionSupported(String sourceFormat, String targetFormat) {
    final source = sourceFormat.toLowerCase().replaceAll('.', '');
    final target = targetFormat.toLowerCase().replaceAll('.', '');

    // Supported conversions
    final supportedConversions = {
      // Image conversions (including OCR to text)
      'jpg': ['pdf', 'png', 'gif', 'bmp', 'tiff', 'txt', 'text'],
      'jpeg': ['pdf', 'png', 'gif', 'bmp', 'tiff', 'txt', 'text'],
      'png': ['pdf', 'jpg', 'gif', 'bmp', 'tiff', 'txt', 'text'],
      'gif': ['pdf', 'jpg', 'png', 'bmp', 'txt', 'text'],
      'bmp': ['pdf', 'jpg', 'png', 'gif', 'txt', 'text'],
      'webp': ['pdf', 'jpg', 'png', 'txt', 'text'],
      'tiff': ['pdf', 'jpg', 'png', 'txt', 'text'],
      'tif': ['pdf', 'jpg', 'png', 'txt', 'text'],
      // Text to PDF
      'txt': ['pdf'],
    };

    return supportedConversions[source]?.contains(target) ?? false;
  }

  /// Get unsupported conversion message
  String getUnsupportedMessage(String sourceFormat, String targetFormat) {
    final source = sourceFormat.toUpperCase().replaceAll('.', '');
    final target = targetFormat.toUpperCase().replaceAll('.', '');

    if (source == 'PDF' && (target == 'DOCX' || target == 'DOC')) {
      return 'PDF to Word conversion requires cloud processing. '
          'This feature is not available in offline mode.';
    }
    if (source == 'PDF' && (target == 'PPTX' || target == 'PPT')) {
      return 'PDF to PowerPoint conversion requires cloud processing. '
          'This feature is not available in offline mode.';
    }
    if ((source == 'DOCX' || source == 'DOC') && target == 'PDF') {
      return 'Word to PDF conversion requires cloud processing. '
          'This feature is not available in offline mode.';
    }
    if ((source == 'PPTX' || source == 'PPT') && target == 'PDF') {
      return 'PowerPoint to PDF conversion requires cloud processing. '
          'This feature is not available in offline mode.';
    }

    return '$source to $target conversion is not supported in offline mode.';
  }

  /// Convert images to PDF
  Future<String> imagesToPdf({
    required List<String> imagePaths,
    String? title,
  }) async {
    debugPrint(
        '📄 [DOCUMENT SERVICE] Converting ${imagePaths.length} images to PDF');

    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('⚠️ Image not found: $imagePath');
        continue;
      }

      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('⚠️ Failed to decode image: $imagePath');
        continue;
      }

      // Convert to JPEG for PDF compatibility
      final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
      final pdfImage = pw.MemoryImage(jpegBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
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

    debugPrint('✅ [DOCUMENT SERVICE] PDF created: $outputPath');
    return outputPath;
  }

  /// Convert text file to PDF
  Future<String> textToPdf({
    required String textFilePath,
    String? title,
  }) async {
    debugPrint('📄 [DOCUMENT SERVICE] Converting text to PDF');

    final textFile = File(textFilePath);
    if (!await textFile.exists()) {
      throw Exception('Text file not found: $textFilePath');
    }

    final text = await textFile.readAsString();
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
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    final outputDir = await _getOutputDir();
    final fileName = path.basenameWithoutExtension(textFilePath);
    final outputPath = path.join(
      outputDir.path,
      '${fileName}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    debugPrint('✅ [DOCUMENT SERVICE] PDF created: $outputPath');
    return outputPath;
  }

  /// Create PDF from raw text content
  Future<String> createPdfFromText({
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

  /// Convert images to a presentation-style PDF (one image per page, landscape)
  /// This serves as an alternative to PPTX for offline mode
  Future<String> imagesToPresentation({
    required List<String> imagePaths,
    String? title,
  }) async {
    debugPrint(
        '📄 [DOCUMENT SERVICE] Creating presentation PDF from ${imagePaths.length} images');

    final pdf = pw.Document();

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) continue;

      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) continue;

      final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
      final pdfImage = pw.MemoryImage(jpegBytes);

      pdf.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat.a4.landscape, // Landscape for presentation style
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              children: [
                if (i == 0 && title != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text(
                    'Slide ${i + 1} of ${imagePaths.length}',
                    style:
                        const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'presentation'}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    debugPrint('✅ [DOCUMENT SERVICE] Presentation PDF created: $outputPath');
    return outputPath;
  }

  /// Convert images to a document-style PDF (multiple images per page with captions)
  /// This serves as an alternative to DOCX for offline mode
  Future<String> imagesToDocument({
    required List<String> imagePaths,
    String? title,
  }) async {
    debugPrint(
        '📄 [DOCUMENT SERVICE] Creating document PDF from ${imagePaths.length} images');

    final pdf = pw.Document();
    final List<pw.Widget> content = [];

    if (title != null) {
      content.add(
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
      content.add(pw.SizedBox(height: 20));
    }

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) continue;

      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) continue;

      final jpegBytes = img.encodeJpg(decodedImage, quality: 85);
      final pdfImage = pw.MemoryImage(jpegBytes);

      content.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Image ${i + 1}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                constraints: const pw.BoxConstraints(maxHeight: 300),
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            ],
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => content,
      ),
    );

    final outputDir = await _getOutputDir();
    final outputPath = path.join(
      outputDir.path,
      '${title ?? 'document'}_${_uuid.v4()}.pdf',
    );

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    debugPrint('✅ [DOCUMENT SERVICE] Document PDF created: $outputPath');
    return outputPath;
  }

  /// Convert document - main entry point
  /// Returns the output path on success, throws on failure
  Future<String> convertDocument({
    required String inputPath,
    required String targetFormat,
  }) async {
    final sourceExt =
        path.extension(inputPath).toLowerCase().replaceAll('.', '');
    final target = targetFormat.toLowerCase().replaceAll('.', '');

    debugPrint('📄 [DOCUMENT SERVICE] Converting $sourceExt to $target');

    // Check if conversion is supported
    if (!isConversionSupported(sourceExt, target)) {
      throw UnsupportedError(getUnsupportedMessage(sourceExt, target));
    }

    // Image to PDF
    if (_isImageFormat(sourceExt) && target == 'pdf') {
      return await imagesToPdf(imagePaths: [inputPath]);
    }

    // Text to PDF
    if (sourceExt == 'txt' && target == 'pdf') {
      return await textToPdf(textFilePath: inputPath);
    }

    throw UnsupportedError(
        'Conversion from $sourceExt to $target is not implemented');
  }

  bool _isImageFormat(String ext) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'tif']
        .contains(ext);
  }
}
