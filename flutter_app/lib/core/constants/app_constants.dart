/// App-wide constants and configuration values
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'DocXpress';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Configuration
  static const String defaultBaseUrl = 'http://localhost:3000/api';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String themeKey = 'theme_mode';
  static const String baseUrlKey = 'base_url';
  static const String defaultQualityKey = 'default_quality';
  static const String defaultFormatKey = 'default_format';
  static const String onboardingKey = 'onboarding_completed';

  // File Size Limits (in bytes)
  static const int maxImageSize = 20 * 1024 * 1024; // 20 MB
  static const int maxVideoSize = 500 * 1024 * 1024; // 500 MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50 MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Image Quality Presets
  static const int lowQuality = 30;
  static const int mediumQuality = 60;
  static const int highQuality = 80;
  static const int maxQuality = 100;

  // Video Compression Presets
  static const String videoLow = '480p';
  static const String videoMedium = '720p';
  static const String videoHigh = '1080p';

  // Supported File Extensions
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
    'tiff'
  ];

  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'txt'
  ];

  static const List<String> videoExtensions = [
    'mp4',
    'mpeg',
    'mov',
    'avi',
    'webm',
    'mkv'
  ];

  // MIME Types
  static const Map<String, String> mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  // Conversion Types
  static const String imageToPdf = 'IMAGE_TO_PDF';
  static const String imageToPptx = 'IMAGE_TO_PPTX';
  static const String imageToDocx = 'IMAGE_TO_DOCX';
  static const String imageToTxt = 'IMAGE_TO_TXT';
  static const String imageFormatConvert = 'IMAGE_FORMAT_CONVERT';
  static const String imageTransform = 'IMAGE_TRANSFORM';
  static const String imageMerge = 'IMAGE_MERGE';
  static const String pdfToPptx = 'PDF_TO_PPTX';
  static const String pdfToDocx = 'PDF_TO_DOCX';
  static const String pdfToTxt = 'PDF_TO_TXT';
  static const String pptxToPdf = 'PPTX_TO_PDF';
  static const String docxToPdf = 'DOCX_TO_PDF';
  static const String pdfMerge = 'PDF_MERGE';
  static const String pdfSplit = 'PDF_SPLIT';
  static const String pdfReorder = 'PDF_REORDER';
  static const String pdfExtractImages = 'PDF_EXTRACT_IMAGES';
  static const String pdfExtractText = 'PDF_EXTRACT_TEXT';
  static const String compressImage = 'COMPRESS_IMAGE';
  static const String compressVideo = 'COMPRESS_VIDEO';
  static const String compressPdf = 'COMPRESS_PDF';

  // Job Statuses
  static const String statusPending = 'PENDING';
  static const String statusRunning = 'RUNNING';
  static const String statusCompleted = 'COMPLETED';
  static const String statusFailed = 'FAILED';

  // File Types
  static const String fileTypeImage = 'image';
  static const String fileTypePdf = 'pdf';
  static const String fileTypeVideo = 'video';
  static const String fileTypeDocument = 'document';
  static const String fileTypeText = 'text';
  static const String fileTypeOther = 'other';

  // Output Formats
  static const List<String> imageOutputFormats = [
    'jpeg',
    'png',
    'webp',
    'tiff',
    'gif'
  ];

  static const List<String> documentOutputFormats = ['pdf', 'docx', 'pptx', 'txt'];

  // PDF Page Sizes
  static const List<String> pdfPageSizes = ['A4', 'Letter', 'Legal', 'A3'];

  // Cache Duration
  static const Duration cacheValidDuration = Duration(hours: 24);

  // Debounce Duration
  static const Duration searchDebounce = Duration(milliseconds: 500);
}

/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/me';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String refreshToken = '/auth/refresh';
  static const String deleteAccount = '/auth/delete-account';

  // Notes
  static const String notes = '/notes';
  static String note(String id) => '/notes/$id';
  static String togglePin(String id) => '/notes/$id/pin';
  static const String noteTags = '/notes/tags';
  static const String noteSearch = '/notes/search';

  // Files
  static const String files = '/files';
  static const String uploadFile = '/files/upload';
  static const String uploadMultiple = '/files/upload-multiple';
  static String file(String id) => '/files/$id';
  static String downloadFile(String id) => '/files/$id/download';
  static const String fileStats = '/files/stats';
  static const String fileBatch = '/files/batch';

  // Conversions
  static const String imagesToPdf = '/convert/images-to-pdf';
  static const String imagesToPptx = '/convert/images-to-pptx';
  static const String imagesToDocx = '/convert/images-to-docx';
  static const String imageToText = '/convert/image-to-text';
  static const String imageFormat = '/convert/image-format';
  static const String imageTransform = '/convert/image-transform';
  static const String mergeImages = '/convert/merge-images';
  static const String pdfToDocx = '/convert/pdf-to-docx';
  static const String pdfToPptx = '/convert/pdf-to-pptx';
  static const String pdfToText = '/convert/pdf-to-text';
  static const String docxToPdf = '/convert/docx-to-pdf';
  static const String pptxToPdf = '/convert/pptx-to-pdf';

  // PDF Operations
  static const String pdfMerge = '/pdf/merge';
  static const String pdfSplit = '/pdf/split';
  static const String pdfReorder = '/pdf/reorder';
  static const String pdfExtractText = '/pdf/extract-text';
  static const String pdfExtractImages = '/pdf/extract-images';
  static const String pdfCompress = '/pdf/compress';
  static String pdfInfo(String id) => '/pdf/$id/info';
  static const String pdfWatermark = '/pdf/watermark';
  static const String pdfRemovePages = '/pdf/remove-pages';
  static const String pdfRotatePages = '/pdf/rotate-pages';

  // Compression
  static const String compressPresets = '/compress/presets';
  static const String compressImage = '/compress/image';
  static const String compressImages = '/compress/images';
  static const String compressVideo = '/compress/video';
  static const String compressVideoResolution = '/compress/video/resolution';
  static String videoInfo(String id) => '/compress/video/$id/info';
  static const String videoThumbnail = '/compress/video/thumbnail';
  static const String videoExtractAudio = '/compress/video/extract-audio';
  static const String compressPdf = '/compress/pdf';

  // Jobs
  static const String jobs = '/jobs';
  static String job(String id) => '/jobs/$id';
  static const String jobTypes = '/jobs/types';
  static const String recentJobs = '/jobs/recent';
  static const String jobStats = '/jobs/stats';
  static const String pendingCount = '/jobs/pending-count';
  static const String checkLimit = '/jobs/check-limit';
  static String cancelJob(String id) => '/jobs/$id/cancel';
  static String retryJob(String id) => '/jobs/$id/retry';
}
