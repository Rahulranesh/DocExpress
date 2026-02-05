import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../services/local_image_service.dart';
import '../services/local_pdf_service.dart';
import '../services/local_ocr_service.dart';
import '../services/local_file_service.dart';
import '../services/local_jobs_service.dart';
import '../services/local_document_service.dart';
import '../services/local_office_service.dart';
import '../services/offline_service_manager.dart';
import '../services/api_service.dart';
import 'backend_conversion_repository.dart';

/// Offline Conversion Repository - replaces API-based conversion repository
/// All operations are performed locally on the device
/// Falls back to backend service for unsupported conversions
class OfflineConversionRepository {
  final LocalImageService _imageService;
  final LocalPdfService _pdfService;
  final LocalOcrService _ocrService;
  final LocalFileService _fileService;
  final LocalJobsService _jobsService;
  final ApiService _apiService;

  OfflineConversionRepository({
    LocalImageService? imageService,
    LocalPdfService? pdfService,
    LocalOcrService? ocrService,
    LocalFileService? fileService,
    LocalJobsService? jobsService,
    required ApiService apiService,
  })  : _imageService = imageService ?? offlineServices.imageService,
        _apiService = apiService,
        _pdfService = pdfService ?? offlineServices.pdfService,
        _ocrService = ocrService ?? offlineServices.ocrService,
        _fileService = fileService ?? offlineServices.fileService,
        _jobsService = jobsService ?? offlineServices.jobsService;

  // ==================== Image Conversions ====================

  /// Convert images to PDF
  Future<ConversionResult> imagesToPdf({
    required List<String> filePaths,
    String pageSize = 'A4',
    String? title,
  }) async {
    debugPrint(
        '🔄 [LOCAL PROCESSING] Conversion: Converting ${filePaths.length} images to PDF locally');

    // Create job entry
    final job = await _jobsService.createJob(
      type: 'images_to_pdf',
      inputFileName: '${filePaths.length} images',
      options: {'pageSize': pageSize, 'title': title},
    );

    try {
      final outputPath = await _pdfService.imagesToPdf(
        imagePaths: filePaths,
        title: title,
      );
      debugPrint('✅ [LOCAL PROCESSING] Conversion: PDF created at $outputPath');

      // Save to file service
      final savedFile = await _fileService.saveFile(File(outputPath));

      // Update job as completed
      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully converted ${filePaths.length} images to PDF',
      );
    } catch (e) {
      // Update job as failed
      await _jobsService.updateJob(
        job.id,
        status: 'failed',
        error: e.toString(),
      );
      return ConversionResult(
        success: false,
        message: 'Failed to convert images to PDF: $e',
      );
    }
  }

  /// Convert images to PowerPoint (PPTX) file
  Future<ConversionResult> imagesToPptx({
    required List<String> filePaths,
    String? title,
  }) async {
    debugPrint(
        '🔄 [LOCAL PROCESSING] Conversion: Converting ${filePaths.length} images to PPTX');

    final job = await _jobsService.createJob(
      type: 'images_to_pptx',
      inputFileName: '${filePaths.length} images',
      options: {'title': title},
    );

    try {
      final officeService = LocalOfficeService();
      final outputPath = await officeService.imagesToPptx(
        imagePaths: filePaths,
        title: title,
      );
      debugPrint('✅ [LOCAL PROCESSING] Conversion: PPTX created');

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message:
            'Created PowerPoint presentation with ${filePaths.length} slides',
      );
    } catch (e) {
      await _jobsService.updateJob(
        job.id,
        status: 'failed',
        error: e.toString(),
      );
      return ConversionResult(
        success: false,
        message: 'Failed to create presentation: $e',
      );
    }
  }

  /// Convert images to Word document (DOCX) file
  Future<ConversionResult> imagesToDocx({
    required List<String> filePaths,
    String? title,
  }) async {
    debugPrint(
        '🔄 [LOCAL PROCESSING] Conversion: Converting ${filePaths.length} images to DOCX');

    final job = await _jobsService.createJob(
      type: 'images_to_docx',
      inputFileName: '${filePaths.length} images',
      options: {'title': title},
    );

    try {
      final officeService = LocalOfficeService();
      final outputPath = await officeService.imagesToDocx(
        imagePaths: filePaths,
        title: title,
      );
      debugPrint('✅ [LOCAL PROCESSING] Conversion: DOCX created');

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Created Word document with ${filePaths.length} images',
      );
    } catch (e) {
      await _jobsService.updateJob(
        job.id,
        status: 'failed',
        error: e.toString(),
      );
      return ConversionResult(
        success: false,
        message: 'Failed to create document: $e',
      );
    }
  }

  /// Convert image format (e.g., PNG to JPG)
  Future<ConversionResult> convertImageFormat({
    required String filePath,
    required String targetFormat,
    int quality = 80,
  }) async {
    debugPrint(
        '🔄 [LOCAL PROCESSING] Conversion: Converting image to $targetFormat locally');

    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_format_convert',
      inputFileName: inputFileName,
      options: {'targetFormat': targetFormat, 'quality': quality},
    );

    try {
      final outputPath = await _imageService.convertFormat(
        inputPath: filePath,
        targetFormat: targetFormat,
        quality: quality,
      );
      debugPrint(
          '✅ [LOCAL PROCESSING] Conversion: Image format converted successfully');

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully converted to $targetFormat',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to convert image format: $e',
      );
    }
  }

  /// Extract text from image using OCR
  Future<ConversionResult> imageToText({
    required String filePath,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'ocr',
      inputFileName: inputFileName,
    );

    try {
      final text = await _ocrService.extractTextFromImage(filePath);

      // Save text to file
      final outputPath = await _ocrService.extractTextToFile(
        imagePath: filePath,
        outputName: 'ocr_result',
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        extractedText: text,
        message: 'Successfully extracted text from image',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to extract text: $e',
      );
    }
  }

  /// Resize image
  Future<ConversionResult> resizeImage({
    required String filePath,
    int? width,
    int? height,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_resize',
      inputFileName: inputFileName,
      options: {'width': width, 'height': height},
    );

    try {
      final outputPath = await _imageService.resizeImage(
        inputPath: filePath,
        width: width,
        height: height,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully resized image',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to resize image: $e',
      );
    }
  }

  /// Rotate image
  Future<ConversionResult> rotateImage({
    required String filePath,
    required int degrees,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_rotate',
      inputFileName: inputFileName,
      options: {'degrees': degrees},
    );

    try {
      final outputPath = await _imageService.rotateImage(
        inputPath: filePath,
        degrees: degrees,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully rotated image by $degrees degrees',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to rotate image: $e',
      );
    }
  }

  /// Crop image
  Future<ConversionResult> cropImage({
    required String filePath,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_crop',
      inputFileName: inputFileName,
      options: {'x': x, 'y': y, 'width': width, 'height': height},
    );

    try {
      final outputPath = await _imageService.cropImage(
        inputPath: filePath,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully cropped image',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to crop image: $e',
      );
    }
  }

  /// Apply grayscale filter
  Future<ConversionResult> grayscaleImage({
    required String filePath,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_grayscale',
      inputFileName: inputFileName,
    );

    try {
      final outputPath = await _imageService.grayscaleImage(
        inputPath: filePath,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully applied grayscale filter',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to apply grayscale: $e',
      );
    }
  }

  /// Merge images
  Future<ConversionResult> mergeImages({
    required List<String> filePaths,
    bool vertical = true,
    int gap = 0,
  }) async {
    final job = await _jobsService.createJob(
      type: 'image_merge',
      inputFileName: '${filePaths.length} images',
      options: {'vertical': vertical, 'gap': gap},
    );

    try {
      final outputPath = await _imageService.mergeImages(
        inputPaths: filePaths,
        vertical: vertical,
        gap: gap,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully merged ${filePaths.length} images',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to merge images: $e',
      );
    }
  }

  // ==================== PDF Operations ====================

  /// Text to PDF
  Future<ConversionResult> textToPdf({
    required String text,
    String? title,
  }) async {
    final job = await _jobsService.createJob(
      type: 'text_to_pdf',
      inputFileName: title ?? 'text',
    );

    try {
      final outputPath = await _pdfService.textToPdf(
        text: text,
        title: title,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully created PDF from text',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to create PDF: $e',
      );
    }
  }

  /// Merge multiple PDFs (limited offline - creates combined document)
  Future<ConversionResult> mergePdfs({
    List<String>? fileIds,
    List<String>? filePaths,
    String? title,
  }) async {
    debugPrint('🔄 [LOCAL PROCESSING] Conversion: Merging PDFs locally');

    // Get actual file paths
    List<String> paths = filePaths ?? [];
    if (fileIds != null && fileIds.isNotEmpty) {
      for (final id in fileIds) {
        final filePath = await getFilePath(id);
        if (filePath != null) paths.add(filePath);
      }
    }

    if (paths.isEmpty) {
      return ConversionResult(
        success: false,
        message: 'No PDF files provided',
      );
    }

    final job = await _jobsService.createJob(
      type: 'pdf_merge',
      inputFileName: '${paths.length} PDFs',
      options: {'title': title},
    );

    try {
      final outputPath = await _pdfService.mergePdfs(
        pdfPaths: paths,
        title: title,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully merged ${paths.length} PDFs',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'PDF merge failed: $e',
      );
    }
  }

  /// Split PDF into pages
  Future<ConversionResult> splitPdf({
    String? fileId,
    String? filePath,
    List<int>? pages,
    int? startPage,
    int? endPage,
  }) async {
    debugPrint('🔄 [LOCAL PROCESSING] Conversion: Splitting PDF locally');

    String? actualPath = filePath;
    if (fileId != null && actualPath == null) {
      actualPath = await getFilePath(fileId);
    }

    if (actualPath == null) {
      return ConversionResult(
        success: false,
        message: 'PDF file not found',
      );
    }

    final inputFileName = path.basename(actualPath);
    final job = await _jobsService.createJob(
      type: 'pdf_split',
      inputFileName: inputFileName,
      options: {'pages': pages, 'startPage': startPage, 'endPage': endPage},
    );

    try {
      final outputPath = await _pdfService.splitPdfSingle(
        pdfPath: actualPath,
        pages: pages,
        startPage: startPage,
        endPage: endPage,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully split PDF',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'PDF split failed: $e',
      );
    }
  }

  /// Reorder PDF pages (limited offline support)
  Future<ConversionResult> reorderPdfPages({
    String? fileId,
    String? filePath,
    required List<int> pageOrder,
  }) async {
    debugPrint(
        '🔄 [LOCAL PROCESSING] Conversion: Reordering PDF pages locally');

    String? actualPath = filePath;
    if (fileId != null && actualPath == null) {
      actualPath = await getFilePath(fileId);
    }

    if (actualPath == null) {
      return ConversionResult(
        success: false,
        message: 'PDF file not found',
      );
    }

    final inputFileName = path.basename(actualPath);
    final job = await _jobsService.createJob(
      type: 'pdf_reorder',
      inputFileName: inputFileName,
      options: {'pageOrder': pageOrder},
    );

    try {
      final outputPath = await _pdfService.reorderPages(
        pdfPath: actualPath,
        pageOrder: pageOrder,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully reordered PDF pages',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'PDF reorder failed: $e',
      );
    }
  }

  /// Convert document (supports image to PDF, text to PDF, and OCR)
  Future<ConversionResult> convertDocument({
    String? fileId,
    String? filePath,
    required String targetFormat,
  }) async {
    debugPrint('🔄 [CONVERSION] Document conversion');

    String? actualPath = filePath;
    if (fileId != null && actualPath == null) {
      actualPath = await getFilePath(fileId);
    }

    if (actualPath == null) {
      return ConversionResult(
        success: false,
        message: 'File not found',
      );
    }

    final ext = path.extension(actualPath).toLowerCase();
    final target = targetFormat.toLowerCase();
    final inputFileName = path.basename(actualPath);
    final documentService = LocalDocumentService();

    // Check if conversion is supported locally
    final sourceFormat = ext.replaceAll('.', '');
    final isLocallySupported =
        documentService.isConversionSupported(sourceFormat, target);

    // If not supported locally, try backend service
    if (!isLocallySupported) {
      debugPrint(
          '⚠️ [CONVERSION] Not supported locally, trying backend service...');

      try {
        // Try backend conversion
        final backendRepo = BackendConversionRepository(_apiService);
        String? outputPath;

        // DOCX to PDF
        if ((ext == '.docx' || ext == '.doc') && target == 'pdf') {
          outputPath = await backendRepo.convertDocxToPdf(actualPath);
        }
        // PPTX to PDF
        else if ((ext == '.pptx' || ext == '.ppt') && target == 'pdf') {
          outputPath = await backendRepo.convertPptxToPdf(actualPath);
        }
        // PDF to DOCX
        else if (ext == '.pdf' && (target == 'docx' || target == 'doc')) {
          outputPath = await backendRepo.convertPdfToDocx(actualPath);
        }
        // PDF to PPTX
        else if (ext == '.pdf' && (target == 'pptx' || target == '.ppt')) {
          outputPath = await backendRepo.convertPdfToPptx(actualPath);
        }

        if (outputPath != null) {
          // Save to file service
          final savedFile = await _fileService.saveFile(File(outputPath));

          debugPrint('✅ [BACKEND] Document converted successfully');
          return ConversionResult(
            success: true,
            outputPath: savedFile.path,
            fileId: savedFile.id,
            message: 'Successfully converted to ${target.toUpperCase()}',
          );
        }
      } catch (e) {
        debugPrint('❌ [BACKEND] Conversion failed: $e');
        return ConversionResult(
          success: false,
          message:
              'Backend conversion failed: ${e.toString()}\n\nPlease ensure backend server is running.',
        );
      }

      // If backend also doesn't support it
      final message =
          documentService.getUnsupportedMessage(sourceFormat, target);
      debugPrint('⚠️ [CONVERSION] Unsupported conversion: $message');
      return ConversionResult(
        success: false,
        message: message,
      );
    }

    // Create job entry for local conversion
    final job = await _jobsService.createJob(
      type: 'document_convert',
      inputFileName: inputFileName,
      options: {'targetFormat': target},
    );

    try {
      String outputPath;

      // Image to PDF
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.tif']
          .contains(ext)) {
        if (target == 'pdf') {
          outputPath =
              await documentService.imagesToPdf(imagePaths: [actualPath]);
        } else if (target == 'txt' || target == 'text') {
          // Use OCR for image to text
          return imageToText(filePath: actualPath);
        } else {
          // Image format conversion
          return convertImageFormat(
            filePath: actualPath,
            targetFormat: target,
          );
        }
      }
      // Text to PDF
      else if (ext == '.txt' && target == 'pdf') {
        outputPath = await documentService.textToPdf(textFilePath: actualPath);
      }
      // Unsupported
      else {
        await _jobsService.updateJob(
          job.id,
          status: 'failed',
          error: 'Unsupported conversion',
        );
        return ConversionResult(
          success: false,
          message: documentService.getUnsupportedMessage(sourceFormat, target),
        );
      }

      // Save to file service
      final savedFile = await _fileService.saveFile(File(outputPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      debugPrint('✅ [LOCAL] Document converted successfully');
      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully converted to ${target.toUpperCase()}',
      );
    } catch (e) {
      await _jobsService.updateJob(
        job.id,
        status: 'failed',
        error: e.toString(),
      );
      return ConversionResult(
        success: false,
        message: 'Failed to convert document: $e',
      );
    }
  }

  /// Transform image (rotate, flip, etc.)
  Future<ConversionResult> transformImage({
    String? fileId,
    String? filePath,
    int? rotate,
    bool flipHorizontal = false,
    bool flipVertical = false,
  }) async {
    debugPrint('🔄 [LOCAL PROCESSING] Conversion: Transforming image locally');

    String? actualPath = filePath;
    if (fileId != null && actualPath == null) {
      actualPath = await getFilePath(fileId);
    }

    if (actualPath == null) {
      return ConversionResult(
        success: false,
        message: 'Image file not found',
      );
    }

    final inputFileName = path.basename(actualPath);
    final job = await _jobsService.createJob(
      type: 'image_transform',
      inputFileName: inputFileName,
      options: {
        'rotate': rotate,
        'flipHorizontal': flipHorizontal,
        'flipVertical': flipVertical
      },
    );

    try {
      String currentPath = actualPath;

      // Apply rotation if specified
      if (rotate != null && rotate != 0) {
        currentPath = await _imageService.rotateImage(
          inputPath: currentPath,
          degrees: rotate,
        );
      }

      // Apply flips if specified
      if (flipHorizontal) {
        currentPath = await _imageService.flipImage(
          inputPath: currentPath,
          horizontal: true,
        );
      }

      if (flipVertical) {
        currentPath = await _imageService.flipImage(
          inputPath: currentPath,
          horizontal: false,
        );
      }

      final savedFile = await _fileService.saveFile(File(currentPath));

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        message: 'Successfully transformed image',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Image transformation failed: $e',
      );
    }
  }

  // ==================== Compression ====================

  /// Compress image
  Future<ConversionResult> compressImage({
    required String filePath,
    int quality = 60,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final inputFileName = path.basename(filePath);
    final job = await _jobsService.createJob(
      type: 'image_compress',
      inputFileName: inputFileName,
      options: {
        'quality': quality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight
      },
    );

    try {
      final outputPath = await _imageService.compressImage(
        inputPath: filePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final savedFile = await _fileService.saveFile(File(outputPath));

      // Calculate compression ratio
      final originalSize = await File(filePath).length();
      final newSize = savedFile.size;
      final ratio =
          ((originalSize - newSize) / originalSize * 100).toStringAsFixed(1);

      await _jobsService.updateJob(
        job.id,
        status: 'completed',
        outputFileId: savedFile.id,
        outputFileName: savedFile.name,
        progress: 100,
      );

      return ConversionResult(
        success: true,
        outputPath: savedFile.path,
        fileId: savedFile.id,
        originalSize: originalSize,
        compressedSize: newSize,
        message: 'Compressed by $ratio%',
      );
    } catch (e) {
      await _jobsService.updateJob(job.id,
          status: 'failed', error: e.toString());
      return ConversionResult(
        success: false,
        message: 'Failed to compress image: $e',
      );
    }
  }

  /// Get image info
  Future<Map<String, dynamic>> getImageInfo(String filePath) async {
    return await _imageService.getImageInfo(filePath);
  }

  /// Get PDF info
  Future<Map<String, dynamic>> getPdfInfo(String filePath) async {
    return await _pdfService.getPdfInfo(filePath);
  }

  /// Get file path from file ID
  Future<String?> getFilePath(String fileId) async {
    final file = await _fileService.getFile(fileId);
    return file?.path;
  }

  /// Extract images from PDF
  /// Uses backend service as local extraction is not supported
  Future<ConversionResult> extractImagesFromPdf({
    String? fileId,
    String? filePath,
  }) async {
    debugPrint('🔄 [CONVERSION] Extract images from PDF');

    String? actualPath = filePath;
    if (fileId != null && actualPath == null) {
      actualPath = await getFilePath(fileId);
    }

    if (actualPath == null) {
      return ConversionResult(
        success: false,
        message: 'PDF file not found',
      );
    }

    // Extract images is not supported locally - use backend
    debugPrint('⚠️ [CONVERSION] Extract images not supported locally, trying backend...');

    try {
      // Try backend conversion
      final backendRepo = BackendConversionRepository(_apiService);
      final imagePaths = await backendRepo.extractImagesFromPdf(actualPath);

      if (imagePaths.isEmpty) {
        return ConversionResult(
          success: false,
          message: 'No images found in PDF or extraction failed',
        );
      }

      // Save images to file service
      final savedFiles = <String>[];
      for (final imagePath in imagePaths) {
        final savedFile = await _fileService.saveFile(File(imagePath));
        savedFiles.add(savedFile.path);
      }

      debugPrint('✅ [BACKEND] Extracted ${imagePaths.length} images successfully');
      return ConversionResult(
        success: true,
        outputPath: savedFiles.isNotEmpty ? savedFiles.first : null,
        message: 'Successfully extracted ${imagePaths.length} images from PDF',
        extractedImages: savedFiles,
      );
    } catch (e) {
      debugPrint('❌ [BACKEND] Extract images failed: $e');
      return ConversionResult(
        success: false,
        message:
            'Failed to extract images: ${e.toString()}\n\nPlease ensure backend server is running.',
      );
    }
  }
}

/// Result of a conversion operation
class ConversionResult {
  final bool success;
  final String? outputPath;
  final String? fileId;
  final String? extractedText;
  final List<String>? extractedImages;
  final int? originalSize;
  final int? compressedSize;
  final String message;

  ConversionResult({
    required this.success,
    this.outputPath,
    this.fileId,
    this.extractedText,
    this.extractedImages,
    this.originalSize,
    this.compressedSize,
    required this.message,
  });

  /// Compression ratio as percentage
  double? get compressionRatio {
    if (originalSize == null || compressedSize == null) return null;
    return (originalSize! - compressedSize!) / originalSize! * 100;
  }
}
