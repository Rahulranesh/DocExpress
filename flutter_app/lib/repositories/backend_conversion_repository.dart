import 'package:flutter/foundation.dart';
import '../services/backend_conversion_service.dart';
import '../services/api_service.dart';

/// Repository for backend-based document conversions
/// Handles conversions that cannot be done locally on mobile devices
class BackendConversionRepository {
  final BackendConversionService _backendService;

  BackendConversionRepository(ApiService apiService)
      : _backendService = BackendConversionService(apiService);

  /// Extract images from PDF
  /// Returns list of image file paths
  Future<List<String>> extractImagesFromPdf(String pdfPath) async {
    try {
      return await _backendService.extractImagesFromPdf(pdfPath: pdfPath);
    } catch (e) {
      debugPrint('❌ [REPOSITORY] Extract images failed: $e');
      rethrow;
    }
  }

  /// Convert DOCX to PDF
  Future<String> convertDocxToPdf(String docxPath, {String? outputName}) async {
    try {
      return await _backendService.docxToPdf(
        docxPath: docxPath,
        outputName: outputName,
      );
    } catch (e) {
      debugPrint('❌ [REPOSITORY] DOCX to PDF failed: $e');
      rethrow;
    }
  }

  /// Convert PPTX to PDF
  Future<String> convertPptxToPdf(String pptxPath, {String? outputName}) async {
    try {
      return await _backendService.pptxToPdf(
        pptxPath: pptxPath,
        outputName: outputName,
      );
    } catch (e) {
      debugPrint('❌ [REPOSITORY] PPTX to PDF failed: $e');
      rethrow;
    }
  }

  /// Convert PDF to PPTX
  Future<String> convertPdfToPptx(String pdfPath, {String? outputName}) async {
    try {
      return await _backendService.pdfToPptx(
        pdfPath: pdfPath,
        outputName: outputName,
      );
    } catch (e) {
      debugPrint('❌ [REPOSITORY] PDF to PPTX failed: $e');
      rethrow;
    }
  }

  /// Convert PDF to DOCX
  Future<String> convertPdfToDocx(String pdfPath, {String? outputName}) async {
    try {
      return await _backendService.pdfToDocx(
        pdfPath: pdfPath,
        outputName: outputName,
      );
    } catch (e) {
      debugPrint('❌ [REPOSITORY] PDF to DOCX failed: $e');
      rethrow;
    }
  }
}
