import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/notes/notes_screen.dart';
import '../../screens/notes/note_editor_screen.dart';
import '../../screens/files/files_screen.dart';
import '../../screens/files/file_picker_screen.dart';
import '../../screens/convert/convert_hub_screen.dart';
import '../../screens/convert/image_to_pdf_screen.dart';
import '../../screens/convert/image_format_screen.dart';
import '../../screens/convert/image_transform_screen.dart';
import '../../screens/convert/pdf_merge_screen.dart';
import '../../screens/convert/pdf_split_screen.dart';
import '../../screens/convert/pdf_reorder_screen.dart';
import '../../screens/convert/document_convert_screen.dart';
import '../../screens/compress/compress_hub_screen.dart';
import '../../screens/compress/image_compress_screen.dart';
import '../../screens/compress/video_compress_screen.dart';
import '../../screens/compress/pdf_compress_screen.dart';
import '../../screens/jobs/jobs_screen.dart';
import '../../screens/jobs/job_detail_screen.dart';
import '../../screens/scan/scan_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/profile_screen.dart';
import '../../providers/providers.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main app routes
  static const String home = '/home';
  static const String notes = '/notes';
  static const String noteEditor = '/notes/editor';
  static const String files = '/files';
  static const String filePicker = '/files/picker';
  static const String convert = '/convert';
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs/:id';
  static const String settings = '/settings';
  static const String profile = '/settings/profile';

  // Conversion routes
  static const String imageToPdf = '/convert/image-to-pdf';
  static const String imageFormat = '/convert/image-format';
  static const String imageTransform = '/convert/image-transform';
  static const String imageToPptx = '/convert/image-to-pptx';
  static const String imageToDocx = '/convert/image-to-docx';
  static const String imageOcr = '/convert/image-ocr';
  static const String mergeImages = '/convert/merge-images';
  static const String pdfMerge = '/convert/pdf-merge';
  static const String pdfSplit = '/convert/pdf-split';
  static const String pdfReorder = '/convert/pdf-reorder';
  static const String pdfExtractText = '/convert/pdf-extract-text';
  static const String pdfExtractImages = '/convert/pdf-extract-images';
  static const String documentConvert = '/convert/document';

  // Compression routes
  static const String compress = '/compress';
  static const String compressImage = '/compress/image';
  static const String compressVideo = '/compress/video';
  static const String compressPdf = '/compress/pdf';

  // Scan route
  static const String scan = '/scan';
}

/// Navigation keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // Allow splash screen always
      if (isSplash) return null;

      // If still loading, stay on splash
      if (isLoading) return AppRoutes.splash;

      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If logged in and on auth route, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // Notes
          GoRoute(
            path: AppRoutes.notes,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesScreen(),
            ),
          ),

          // Files
          GoRoute(
            path: AppRoutes.files,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FilesScreen(),
            ),
          ),

          // Convert hub
          GoRoute(
            path: AppRoutes.convert,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConvertHubScreen(),
            ),
          ),

          // Jobs/History
          GoRoute(
            path: AppRoutes.jobs,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JobsScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Note editor (full screen)
      GoRoute(
        path: AppRoutes.noteEditor,
        builder: (context, state) {
          final noteId = state.uri.queryParameters['id'];
          return NoteEditorScreen(noteId: noteId);
        },
      ),

      // File picker (full screen)
      GoRoute(
        path: AppRoutes.filePicker,
        builder: (context, state) {
          final allowedTypes = state.uri.queryParameters['types']?.split(',');
          final multiple = state.uri.queryParameters['multiple'] == 'true';
          return FilePickerScreen(
            allowedTypes: allowedTypes,
            allowMultiple: multiple,
          );
        },
      ),

      // Job detail
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return JobDetailScreen(jobId: jobId);
        },
      ),

      // Profile
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Conversion routes
      GoRoute(
        path: AppRoutes.imageToPdf,
        builder: (context, state) => const ImageToPdfScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageFormat,
        builder: (context, state) => const ImageFormatScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageTransform,
        builder: (context, state) => const ImageTransformScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageToPptx,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'IMAGE_TO_PPTX',
          title: 'Images to PPTX',
        ),
      ),
      GoRoute(
        path: AppRoutes.imageToDocx,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'IMAGE_TO_DOCX',
          title: 'Images to DOCX',
        ),
      ),
      GoRoute(
        path: AppRoutes.imageOcr,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'IMAGE_TO_TXT',
          title: 'Image OCR',
        ),
      ),
      GoRoute(
        path: AppRoutes.mergeImages,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'IMAGE_MERGE',
          title: 'Merge Images',
        ),
      ),
      GoRoute(
        path: AppRoutes.pdfMerge,
        builder: (context, state) => const PdfMergeScreen(),
      ),
      GoRoute(
        path: AppRoutes.pdfSplit,
        builder: (context, state) => const PdfSplitScreen(),
      ),
      GoRoute(
        path: AppRoutes.pdfReorder,
        builder: (context, state) => const PdfReorderScreen(),
      ),
      GoRoute(
        path: AppRoutes.pdfExtractText,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'PDF_TO_TXT',
          title: 'Extract Text',
        ),
      ),
      GoRoute(
        path: AppRoutes.pdfExtractImages,
        builder: (context, state) => const DocumentConvertScreen(
          conversionType: 'PDF_EXTRACT_IMAGES',
          title: 'Extract Images',
        ),
      ),
      GoRoute(
        path: AppRoutes.documentConvert,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Convert';
          return DocumentConvertScreen(
            conversionType: type,
            title: title,
          );
        },
      ),

      // Compression routes
      GoRoute(
        path: AppRoutes.compress,
        builder: (context, state) => const CompressHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.compressImage,
        builder: (context, state) => const ImageCompressScreen(),
      ),
      GoRoute(
        path: AppRoutes.compressVideo,
        builder: (context, state) => const VideoCompressScreen(),
      ),
      GoRoute(
        path: AppRoutes.compressPdf,
        builder: (context, state) => const PdfCompressScreen(),
      ),

      // Scan route
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const ScanScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension for easier navigation
extension GoRouterExtension on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToHome() => go(AppRoutes.home);
  void goToNotes() => go(AppRoutes.notes);
  void goToFiles() => go(AppRoutes.files);
  void goToConvert() => go(AppRoutes.convert);
  void goToJobs() => go(AppRoutes.jobs);
  void goToSettings() => go(AppRoutes.settings);

  void openNoteEditor({String? noteId}) {
    if (noteId != null) {
      push('${AppRoutes.noteEditor}?id=$noteId');
    } else {
      push(AppRoutes.noteEditor);
    }
  }

  void openFilePicker({List<String>? types, bool multiple = false}) {
    final params = <String>[];
    if (types != null) params.add('types=${types.join(',')}');
    if (multiple) params.add('multiple=true');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    push('${AppRoutes.filePicker}$query');
  }

  void openJobDetail(String jobId) => push('/jobs/$jobId');
  void openProfile() => push(AppRoutes.profile);

  // Conversion navigations
  void openImageToPdf() => push(AppRoutes.imageToPdf);
  void openImageFormat() => push(AppRoutes.imageFormat);
  void openImageTransform() => push(AppRoutes.imageTransform);
  void openImageToPptx() => push(AppRoutes.imageToPptx);
  void openImageToDocx() => push(AppRoutes.imageToDocx);
  void openImageOcr() => push(AppRoutes.imageOcr);
  void openMergeImages() => push(AppRoutes.mergeImages);
  void openPdfMerge() => push(AppRoutes.pdfMerge);
  void openPdfSplit() => push(AppRoutes.pdfSplit);
  void openPdfReorder() => push(AppRoutes.pdfReorder);
  void openPdfExtractText() => push(AppRoutes.pdfExtractText);
  void openPdfExtractImages() => push(AppRoutes.pdfExtractImages);

  void openDocumentConvert({required String type, required String title}) {
    push('${AppRoutes.documentConvert}?type=$type&title=$title');
  }

  // Compression navigations
  void openCompressHub() => push(AppRoutes.compress);
  void openCompressImage() => push(AppRoutes.compressImage);
  void openCompressVideo() => push(AppRoutes.compressVideo);
  void openCompressPdf() => push(AppRoutes.compressPdf);

  // Scan navigation
  void openScan() => push(AppRoutes.scan);
}
