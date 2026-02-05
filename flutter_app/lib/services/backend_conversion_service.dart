import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'api_service.dart';

/// Backend Conversion Service - Simplified
/// Uses direct file upload endpoints (no MongoDB, no auth required)
/// Perfect for the 5 features that need backend processing
class BackendConversionService {
  final ApiService _apiService;

  BackendConversionService(this._apiService);

  /// Get output directory for saving files
  Future<Directory> _getOutputDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(path.join(dir.path, 'docxpress_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Save downloaded file bytes to local storage
  Future<String> _saveDownloadedFile(List<int> bytes, String filename) async {
    final outputDir = await _getOutputDir();
    final outputPath = path.join(outputDir.path, filename);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return outputPath;
  }

  /// Convert DOCX to PDF
  Future<String> docxToPdf({
    required String docxPath,
    String? outputName,
  }) async {
    debugPrint('📄 [BACKEND SERVICE] Converting DOCX to PDF via backend');

    try {
      final file = File(docxPath);
      if (!await file.exists()) {
        throw Exception('DOCX file not found: $docxPath');
      }

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          docxPath,
          filename: path.basename(docxPath),
        ),
      });

      // Upload and convert in one request
      final response = await _apiService.dio.post(
        '/simple-convert/docx-to-pdf',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes, // Get file as bytes
          contentType: 'multipart/form-data',
        ),
      );

      // Save the PDF file
      final filename = outputName ??
          '${path.basenameWithoutExtension(docxPath)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputPath = await _saveDownloadedFile(response.data, filename);

      debugPrint('✅ [BACKEND SERVICE] DOCX to PDF completed: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('❌ [BACKEND SERVICE] DOCX to PDF failed: $e');
      throw ApiException(
          message: 'DOCX to PDF conversion failed: ${e.toString()}');
    }
  }

  /// Convert PPTX to PDF
  Future<String> pptxToPdf({
    required String pptxPath,
    String? outputName,
  }) async {
    debugPrint('📄 [BACKEND SERVICE] Converting PPTX to PDF via backend');

    try {
      final file = File(pptxPath);
      if (!await file.exists()) {
        throw Exception('PPTX file not found: $pptxPath');
      }

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pptxPath,
          filename: path.basename(pptxPath),
        ),
      });

      // Upload and convert in one request
      final response = await _apiService.dio.post(
        '/simple-convert/pptx-to-pdf',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'multipart/form-data',
        ),
      );

      // Save the PDF file
      final filename = outputName ??
          '${path.basenameWithoutExtension(pptxPath)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputPath = await _saveDownloadedFile(response.data, filename);

      debugPrint('✅ [BACKEND SERVICE] PPTX to PDF completed: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('❌ [BACKEND SERVICE] PPTX to PDF failed: $e');
      throw ApiException(
          message: 'PPTX to PDF conversion failed: ${e.toString()}');
    }
  }

  /// Convert PDF to DOCX
  Future<String> pdfToDocx({
    required String pdfPath,
    String? outputName,
  }) async {
    debugPrint('📄 [BACKEND SERVICE] Converting PDF to DOCX via backend');

    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfPath,
          filename: path.basename(pdfPath),
        ),
      });

      // Upload and convert in one request
      final response = await _apiService.dio.post(
        '/simple-convert/pdf-to-docx',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'multipart/form-data',
        ),
      );

      // Save the DOCX file
      final filename = outputName ??
          '${path.basenameWithoutExtension(pdfPath)}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final outputPath = await _saveDownloadedFile(response.data, filename);

      debugPrint('✅ [BACKEND SERVICE] PDF to DOCX completed: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('❌ [BACKEND SERVICE] PDF to DOCX failed: $e');
      throw ApiException(
          message: 'PDF to DOCX conversion failed: ${e.toString()}');
    }
  }

  /// Convert PDF to PPTX
  Future<String> pdfToPptx({
    required String pdfPath,
    String? outputName,
  }) async {
    debugPrint('📄 [BACKEND SERVICE] Converting PDF to PPTX via backend');

    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfPath,
          filename: path.basename(pdfPath),
        ),
      });

      // Upload and convert in one request
      final response = await _apiService.dio.post(
        '/simple-convert/pdf-to-pptx',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'multipart/form-data',
        ),
      );

      // Save the PPTX file
      final filename = outputName ??
          '${path.basenameWithoutExtension(pdfPath)}_${DateTime.now().millisecondsSinceEpoch}.pptx';
      final outputPath = await _saveDownloadedFile(response.data, filename);

      debugPrint('✅ [BACKEND SERVICE] PDF to PPTX completed: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('❌ [BACKEND SERVICE] PDF to PPTX failed: $e');
      throw ApiException(
          message: 'PDF to PPTX conversion failed: ${e.toString()}');
    }
  }

  /// Extract images from PDF
  Future<List<String>> extractImagesFromPdf({
    required String pdfPath,
  }) async {
    debugPrint('📄 [BACKEND SERVICE] Extracting images from PDF via backend');

    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }

      // Create form data with file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfPath,
          filename: path.basename(pdfPath),
        ),
      });

      // Upload and extract images
      final response = await _apiService.dio.post(
        '/simple-convert/pdf-extract-images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data['data'];
      final imagePaths = (data['images'] as List).cast<String>();

      debugPrint('✅ [BACKEND SERVICE] Extracted ${imagePaths.length} images');
      return imagePaths;
    } catch (e) {
      debugPrint('❌ [BACKEND SERVICE] Extract images failed: $e');
      throw ApiException(message: 'Extract images failed: ${e.toString()}');
    }
  }
}
