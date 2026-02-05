import 'dart:io';

import 'local_auth_service.dart';
import 'local_compression_service.dart';
import 'local_file_service.dart';
import 'local_image_service.dart';
import 'local_jobs_service.dart';
import 'local_notes_service.dart';
import 'local_ocr_service.dart';
import 'local_pdf_service.dart';

/// Offline Service Manager - Central manager for all local services
/// This replaces the need for API calls to a backend server
class OfflineServiceManager {
  static OfflineServiceManager? _instance;
  
  late final LocalAuthService authService;
  late final LocalCompressionService compressionService;
  late final LocalFileService fileService;
  late final LocalImageService imageService;
  late final LocalJobsService jobsService;
  late final LocalNotesService notesService;
  late final LocalOcrService ocrService;
  late final LocalPdfService pdfService;
  
  bool _initialized = false;

  OfflineServiceManager._();

  /// Get singleton instance
  static OfflineServiceManager get instance {
    _instance ??= OfflineServiceManager._();
    return _instance!;
  }

  /// Initialize all services
  Future<void> init() async {
    if (_initialized) return;

    authService = LocalAuthService();
    compressionService = LocalCompressionService();
    fileService = LocalFileService();
    imageService = LocalImageService();
    jobsService = LocalJobsService();
    notesService = LocalNotesService();
    ocrService = LocalOcrService();
    pdfService = LocalPdfService();

    // Initialize services that need it
    await authService.init();
    await compressionService.init();
    await fileService.init();
    await jobsService.init();
    await notesService.init();

    _initialized = true;
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Ensure initialized
  Future<void> ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  // ==================== Auth Operations ====================

  Future<LocalUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await ensureInitialized();
    return authService.register(name: name, email: email, password: password);
  }

  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    await ensureInitialized();
    return authService.login(email: email, password: password);
  }

  Future<void> logout() async {
    await ensureInitialized();
    return authService.logout();
  }

  Future<LocalUser?> getCurrentUser() async {
    await ensureInitialized();
    return authService.getCurrentUser();
  }

  Future<bool> isLoggedIn() async {
    await ensureInitialized();
    return authService.isLoggedIn();
  }

  Future<LocalUser> continueAsGuest() async {
    await ensureInitialized();
    return authService.continueAsGuest();
  }

  // ==================== File Operations ====================

  Future<LocalFile> saveFile(File file, {String? category}) async {
    await ensureInitialized();
    return fileService.saveFile(file, category: category);
  }

  Future<List<LocalFile>> getAllFiles({
    String? fileType,
    String? category,
    String? search,
  }) async {
    await ensureInitialized();
    return fileService.getAllFiles(
      fileType: fileType,
      category: category,
      search: search,
    );
  }

  Future<LocalFile?> getFile(String id) async {
    await ensureInitialized();
    return fileService.getFile(id);
  }

  Future<void> deleteFile(String id) async {
    await ensureInitialized();
    return fileService.deleteFile(id);
  }

  // ==================== Notes Operations ====================

  Future<LocalNote> createNote({
    required String title,
    String content = '',
    List<String>? tags,
    bool pinned = false,
  }) async {
    await ensureInitialized();
    return notesService.createNote(
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
    );
  }

  Future<List<LocalNote>> getAllNotes({
    bool? pinned,
    String? tag,
    String? search,
  }) async {
    await ensureInitialized();
    return notesService.getAllNotes(
      pinned: pinned,
      tag: tag,
      search: search,
    );
  }

  Future<LocalNote?> getNote(String id) async {
    await ensureInitialized();
    return notesService.getNote(id);
  }

  Future<LocalNote?> updateNote(
    String id, {
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
  }) async {
    await ensureInitialized();
    return notesService.updateNote(
      id,
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
    );
  }

  Future<void> deleteNote(String id) async {
    await ensureInitialized();
    return notesService.deleteNote(id);
  }

  // ==================== Image Operations ====================

  Future<String> compressImage({
    required String inputPath,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    await ensureInitialized();
    return imageService.compressImage(
      inputPath: inputPath,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  Future<String> convertImageFormat({
    required String inputPath,
    required String targetFormat,
    int quality = 80,
  }) async {
    await ensureInitialized();
    return imageService.convertFormat(
      inputPath: inputPath,
      targetFormat: targetFormat,
      quality: quality,
    );
  }

  Future<String> resizeImage({
    required String inputPath,
    int? width,
    int? height,
  }) async {
    await ensureInitialized();
    return imageService.resizeImage(
      inputPath: inputPath,
      width: width,
      height: height,
    );
  }

  Future<String> rotateImage({
    required String inputPath,
    required int degrees,
  }) async {
    await ensureInitialized();
    return imageService.rotateImage(
      inputPath: inputPath,
      degrees: degrees,
    );
  }

  Future<String> mergeImages({
    required List<String> inputPaths,
    bool vertical = true,
    int gap = 0,
  }) async {
    await ensureInitialized();
    return imageService.mergeImages(
      inputPaths: inputPaths,
      vertical: vertical,
      gap: gap,
    );
  }

  // ==================== PDF Operations ====================

  Future<String> imagesToPdf({
    required List<String> imagePaths,
    String? title,
  }) async {
    await ensureInitialized();
    return pdfService.imagesToPdf(
      imagePaths: imagePaths,
      title: title,
    );
  }

  Future<String> textToPdf({
    required String text,
    String? title,
  }) async {
    await ensureInitialized();
    return pdfService.textToPdf(
      text: text,
      title: title,
    );
  }

  // ==================== OCR Operations ====================

  Future<String> extractTextFromImage(String imagePath) async {
    await ensureInitialized();
    return ocrService.extractTextFromImage(imagePath);
  }

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    await ensureInitialized();
    return ocrService.extractTextFromImages(imagePaths);
  }

  Future<String> extractTextToFile({
    required String imagePath,
    String? outputName,
  }) async {
    await ensureInitialized();
    return ocrService.extractTextToFile(
      imagePath: imagePath,
      outputName: outputName,
    );
  }

  // ==================== Cleanup ====================

  void dispose() {
    ocrService.dispose();
  }
}

/// Global instance for easy access
final offlineServices = OfflineServiceManager.instance;
