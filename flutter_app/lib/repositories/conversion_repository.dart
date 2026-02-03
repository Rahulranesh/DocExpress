import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Conversion Repository - handles all conversion and PDF operations
class ConversionRepository {
  final ApiService _apiService;

  ConversionRepository({required ApiService apiService})
      : _apiService = apiService;

  // ==================== Image Conversions ====================

  /// Convert images to PDF
  Future<Job> imagesToPdf({
    required List<String> fileIds,
    String pageSize = 'A4',
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.imagesToPdf,
      data: {
        'fileIds': fileIds,
        'pageSize': pageSize,
      },
    );

    return _parseJobResponse(response, 'Failed to convert images to PDF');
  }

  /// Convert images to PPTX
  Future<Job> imagesToPptx({
    required List<String> fileIds,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.imagesToPptx,
      data: {'fileIds': fileIds},
    );

    return _parseJobResponse(response, 'Failed to convert images to PPTX');
  }

  /// Convert images to DOCX
  Future<Job> imagesToDocx({
    required List<String> fileIds,
    String? title,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.imagesToDocx,
      data: {
        'fileIds': fileIds,
        if (title != null) 'title': title,
      },
    );

    return _parseJobResponse(response, 'Failed to convert images to DOCX');
  }

  /// Convert image to text using OCR
  Future<Job> imageToText({
    required String fileId,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.imageToText,
      data: {'fileId': fileId},
    );

    return _parseJobResponse(response, 'Failed to extract text from image');
  }

  /// Convert image format (e.g., PNG to JPG)
  Future<Job> convertImageFormat({
    String? fileId,
    String? filePath,
    required String targetFormat,
    int quality = 80,
  }) async {
    if (fileId == null && filePath == null) {
      throw ArgumentError('Either fileId or filePath must be provided');
    }

    final data = <String, dynamic>{
      if (fileId != null) 'fileId': fileId,
      if (filePath != null) 'filePath': filePath,
      'targetFormat': targetFormat,
      'quality': quality,
    };

    final response = await _apiService.post(
      ApiEndpoints.imageFormat,
      data: data,
    );

    return _parseJobResponse(response, 'Failed to convert image format');
  }

  /// Apply transforms to image (resize, rotate, crop, grayscale)
  Future<Job> transformImage({
    required String fileId,
    required List<TransformOperation> operations,
    String format = 'jpeg',
    int quality = 80,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.imageTransform,
      data: ImageTransformRequest(
        fileId: fileId,
        operations: operations,
        format: format,
        quality: quality,
      ).toJson(),
    );

    return _parseJobResponse(response, 'Failed to transform image');
  }

  /// Merge multiple images into one
  Future<Job> mergeImages({
    required List<String> fileIds,
    String direction = 'vertical',
    String format = 'jpeg',
    int quality = 80,
    int gap = 0,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.mergeImages,
      data: {
        'fileIds': fileIds,
        'direction': direction,
        'format': format,
        'quality': quality,
        'gap': gap,
      },
    );

    return _parseJobResponse(response, 'Failed to merge images');
  }

  // ==================== Document Conversions ====================

  /// Convert PDF to DOCX
  Future<Job> pdfToDocx({
    required String fileId,
    String? outputName,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfToDocx,
      data: {
        'fileId': fileId,
        if (outputName != null) 'outputName': outputName,
      },
    );

    return _parseJobResponse(response, 'Failed to convert PDF to DOCX');
  }

  /// Convert PDF to PPTX
  Future<Job> pdfToPptx({
    required String fileId,
    String? outputName,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfToPptx,
      data: {
        'fileId': fileId,
        if (outputName != null) 'outputName': outputName,
      },
    );

    return _parseJobResponse(response, 'Failed to convert PDF to PPTX');
  }

  /// Convert PDF to Text
  Future<Job> pdfToText({
    required String fileId,
    String? outputName,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfToText,
      data: {
        'fileId': fileId,
        if (outputName != null) 'outputName': outputName,
      },
    );

    return _parseJobResponse(response, 'Failed to extract text from PDF');
  }

  /// Convert DOCX to PDF
  Future<Job> docxToPdf({
    required String fileId,
    String? outputName,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.docxToPdf,
      data: {
        'fileId': fileId,
        if (outputName != null) 'outputName': outputName,
      },
    );

    return _parseJobResponse(response, 'Failed to convert DOCX to PDF');
  }

  /// Convert PPTX to PDF
  Future<Job> pptxToPdf({
    required String fileId,
    String? outputName,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pptxToPdf,
      data: {
        'fileId': fileId,
        if (outputName != null) 'outputName': outputName,
      },
    );

    return _parseJobResponse(response, 'Failed to convert PPTX to PDF');
  }

  // ==================== PDF Operations ====================

  /// Merge multiple PDFs into one
  Future<Job> mergePdfs({
    required List<String> fileIds,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfMerge,
      data: PdfMergeRequest(fileIds: fileIds).toJson(),
    );

    return _parseJobResponse(response, 'Failed to merge PDFs');
  }

  /// Split PDF by page ranges
  Future<Job> splitPdf({
    required String fileId,
    required List<PageRange> ranges,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfSplit,
      data: PdfSplitRequest(fileId: fileId, ranges: ranges).toJson(),
    );

    return _parseJobResponse(response, 'Failed to split PDF');
  }

  /// Reorder PDF pages
  Future<Job> reorderPdfPages({
    required String fileId,
    required List<int> pageOrder,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfReorder,
      data: PdfReorderRequest(fileId: fileId, pageOrder: pageOrder).toJson(),
    );

    return _parseJobResponse(response, 'Failed to reorder PDF pages');
  }

  /// Extract text from PDF
  Future<Job> extractTextFromPdf({
    required String fileId,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfExtractText,
      data: {'fileId': fileId},
    );

    return _parseJobResponse(response, 'Failed to extract text from PDF');
  }

  /// Extract images from PDF
  Future<Job> extractImagesFromPdf({
    required String fileId,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfExtractImages,
      data: {'fileId': fileId},
    );

    return _parseJobResponse(response, 'Failed to extract images from PDF');
  }

  /// Get PDF info/metadata
  Future<Map<String, dynamic>> getPdfInfo(String fileId) async {
    final response = await _apiService.get(ApiEndpoints.pdfInfo(fileId));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return data['info'] ?? data;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to get PDF info',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Add watermark to PDF
  Future<FileModel> addWatermarkToPdf({
    required String fileId,
    required String text,
    double opacity = 0.3,
    int fontSize = 50,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfWatermark,
      data: {
        'fileId': fileId,
        'text': text,
        'opacity': opacity,
        'fontSize': fontSize,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to add watermark',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Remove pages from PDF
  Future<FileModel> removePdfPages({
    required String fileId,
    required List<int> pages,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfRemovePages,
      data: {
        'fileId': fileId,
        'pages': pages,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to remove pages',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Rotate PDF pages
  Future<FileModel> rotatePdfPages({
    required String fileId,
    required Map<int, int> rotations, // pageNumber: degrees
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.pdfRotatePages,
      data: {
        'fileId': fileId,
        'rotations': rotations.map((k, v) => MapEntry(k.toString(), v)),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return FileModel.fromJson(data['file'] ?? data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to rotate pages',
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

  /// Create resize operation
  static TransformOperation resizeOperation({
    int? width,
    int? height,
    String fit = 'inside',
  }) {
    return TransformOperation(
      type: 'resize',
      options: {
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'fit': fit,
      },
    );
  }

  /// Create rotate operation
  static TransformOperation rotateOperation(int angle) {
    return TransformOperation(
      type: 'rotate',
      options: {'angle': angle},
    );
  }

  /// Create crop operation
  static TransformOperation cropOperation({
    required int left,
    required int top,
    required int width,
    required int height,
  }) {
    return TransformOperation(
      type: 'crop',
      options: {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      },
    );
  }

  /// Create grayscale operation
  static TransformOperation grayscaleOperation() {
    return const TransformOperation(type: 'grayscale');
  }

  /// Create flip operation
  static TransformOperation flipOperation() {
    return const TransformOperation(type: 'flip');
  }

  /// Create flop (horizontal flip) operation
  static TransformOperation flopOperation() {
    return const TransformOperation(type: 'flop');
  }

  /// Create blur operation
  static TransformOperation blurOperation({double sigma = 3}) {
    return TransformOperation(
      type: 'blur',
      options: {'sigma': sigma},
    );
  }

  /// Create sharpen operation
  static TransformOperation sharpenOperation() {
    return const TransformOperation(type: 'sharpen');
  }

  /// Create negate (invert colors) operation
  static TransformOperation negateOperation() {
    return const TransformOperation(type: 'negate');
  }

  /// Get supported image output formats
  static List<String> get supportedImageFormats => [
        'jpeg',
        'png',
        'webp',
        'tiff',
        'gif',
      ];

  /// Get supported document output formats
  static List<String> get supportedDocumentFormats => [
        'pdf',
        'docx',
        'pptx',
        'txt',
      ];

  /// Get supported PDF page sizes
  static List<String> get supportedPageSizes => [
        'A4',
        'Letter',
        'Legal',
        'A3',
      ];

  /// Convenience method used by UI to convert documents by file paths.
  /// Note: File upload should be handled in the UI layer before calling this method.
  /// This method expects file IDs that have already been uploaded.
  Future<Job> convertDocument({
    required List<String> fileIds,
    required String conversionType,
    String? outputName,
  }) async {
    // Route to appropriate conversion method based on type
    switch (conversionType.toUpperCase()) {
      case 'IMAGE_TO_PDF':
        return imagesToPdf(fileIds: fileIds);
      case 'IMAGE_TO_PPTX':
        return imagesToPptx(fileIds: fileIds);
      case 'IMAGE_TO_DOCX':
        return imagesToDocx(fileIds: fileIds);
      case 'PDF_TO_PPTX':
        if (fileIds.length != 1)
          throw ArgumentError('PDF to PPTX requires exactly one file');
        return pdfToPptx(fileId: fileIds.first, outputName: outputName);
      case 'PDF_TO_DOCX':
        if (fileIds.length != 1)
          throw ArgumentError('PDF to DOCX requires exactly one file');
        return pdfToDocx(fileId: fileIds.first, outputName: outputName);
      case 'DOCX_TO_PDF':
        if (fileIds.length != 1)
          throw ArgumentError('DOCX to PDF requires exactly one file');
        return docxToPdf(fileId: fileIds.first, outputName: outputName);
      case 'PPTX_TO_PDF':
        if (fileIds.length != 1)
          throw ArgumentError('PPTX to PDF requires exactly one file');
        return pptxToPdf(fileId: fileIds.first, outputName: outputName);
      case 'IMAGE_TO_TXT':
      case 'IMAGE_TO_TEXT':
      case 'OCR':
        if (fileIds.length != 1)
          throw ArgumentError('Image to Text requires exactly one file');
        return imageToText(fileId: fileIds.first);
      case 'IMAGE_MERGE':
      case 'MERGE_IMAGES':
        if (fileIds.length < 2)
          throw ArgumentError('Merge images requires at least 2 images');
        return mergeImages(fileIds: fileIds);
      case 'PDF_TO_TXT':
      case 'PDF_TO_TEXT':
      case 'PDF_EXTRACT_TEXT':
        if (fileIds.length != 1)
          throw ArgumentError(
              'Extract text from PDF requires exactly one file');
        return extractTextFromPdf(fileId: fileIds.first);
      case 'PDF_EXTRACT_IMAGES':
        if (fileIds.length != 1)
          throw ArgumentError(
              'Extract images from PDF requires exactly one file');
        return extractImagesFromPdf(fileId: fileIds.first);
      default:
        throw ArgumentError('Unknown conversion type: $conversionType');
    }
  }

  /// Get conversion type from input and output formats
  static String getConversionType(String inputType, String outputFormat) {
    final key = '${inputType.toUpperCase()}_TO_${outputFormat.toUpperCase()}';
    return key;
  }
}
