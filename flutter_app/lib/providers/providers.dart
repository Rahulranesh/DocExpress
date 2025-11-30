import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notes_repository.dart';
import '../repositories/files_repository.dart';
import '../repositories/jobs_repository.dart';
import '../repositories/conversion_repository.dart';
import '../repositories/compression_repository.dart';

// ==================== Core Services ====================

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(secureStorage: ref.watch(secureStorageProvider));
});

/// API service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    baseUrl: AppConstants.defaultBaseUrl,
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ==================== Repositories ====================

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiService: ref.watch(apiServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

/// Notes repository provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(apiService: ref.watch(apiServiceProvider));
});

/// Files repository provider
final filesRepositoryProvider = Provider<FilesRepository>((ref) {
  return FilesRepository(apiService: ref.watch(apiServiceProvider));
});

/// Jobs repository provider
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(apiService: ref.watch(apiServiceProvider));
});

/// Conversion repository provider
final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ConversionRepository(apiService: ref.watch(apiServiceProvider));
});

/// Compression repository provider
final compressionRepositoryProvider = Provider<CompressionRepository>((ref) {
  return CompressionRepository(apiService: ref.watch(apiServiceProvider));
});

// ==================== Auth State ====================

/// Auth state class
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }

  factory AuthState.initial() => const AuthState();
  factory AuthState.loading() => const AuthState(isLoading: true);
  factory AuthState.authenticated(User user) => AuthState(
        user: user,
        isAuthenticated: true,
      );
  factory AuthState.unauthenticated() => const AuthState();
  factory AuthState.error(String message) => AuthState(error: message);
}

/// Auth state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  AuthStateNotifier(this._authRepository, this._storageService)
      : super(AuthState.initial());

  /// Initialize auth state - check for existing token
  Future<void> initialize() async {
    state = AuthState.loading();

    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final isValid = await _authRepository.validateToken();
        if (isValid) {
          final user = await _authRepository.getStoredUser();
          if (user != null) {
            state = AuthState.authenticated(user);
            return;
          }
        }
      }
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  /// Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.logout();
    } catch (_) {
      // Ignore errors
    }
    state = AuthState.unauthenticated();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (_) {
      // Keep current state
    }
  }

  /// Update profile
  Future<bool> updateProfile({String? name}) async {
    try {
      final user = await _authRepository.updateProfile(name: name);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(storageServiceProvider),
  );
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

// ==================== Notes State ====================

/// Notes list state
class NotesListState {
  final List<Note> notes;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final PaginationInfo pagination;
  final String? searchQuery;
  final String? selectedTag;

  const NotesListState({
    this.notes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.pagination = const PaginationInfo(),
    this.searchQuery,
    this.selectedTag,
  });

  NotesListState copyWith({
    List<Note>? notes,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    PaginationInfo? pagination,
    String? searchQuery,
    String? selectedTag,
  }) {
    return NotesListState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      pagination: pagination ?? this.pagination,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag ?? this.selectedTag,
    );
  }
}

/// Notes list notifier
class NotesListNotifier extends StateNotifier<NotesListState> {
  final NotesRepository _repository;

  NotesListNotifier(this._repository) : super(const NotesListState());

  /// Load notes
  Future<void> loadNotes({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      notes: refresh ? [] : state.notes,
    );

    try {
      final result = await _repository.getNotes(
        page: 1,
        search: state.searchQuery,
        tag: state.selectedTag,
      );

      state = state.copyWith(
        notes: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more notes
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasNextPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getNotes(
        page: state.pagination.page + 1,
        search: state.searchQuery,
        tag: state.selectedTag,
      );

      state = state.copyWith(
        notes: [...state.notes, ...result.data],
        pagination: result.pagination,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Search notes
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
    await loadNotes(refresh: true);
  }

  /// Filter by tag
  Future<void> filterByTag(String? tag) async {
    state = state.copyWith(selectedTag: tag);
    await loadNotes(refresh: true);
  }

  /// Create note
  Future<Note?> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
    bool pinned = false,
  }) async {
    try {
      final note = await _repository.createNote(
        title: title,
        content: content,
        tags: tags,
        pinned: pinned,
      );
      state = state.copyWith(notes: [note, ...state.notes]);
      return note;
    } catch (e) {
      return null;
    }
  }

  /// Update note
  Future<Note?> updateNote({
    required String id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
  }) async {
    try {
      final note = await _repository.updateNote(
        id: id,
        title: title,
        content: content,
        tags: tags,
        pinned: pinned,
      );

      final index = state.notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final updatedNotes = [...state.notes];
        updatedNotes[index] = note;
        state = state.copyWith(notes: updatedNotes);
      }

      return note;
    } catch (e) {
      return null;
    }
  }

  /// Delete note
  Future<bool> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle pin
  Future<void> togglePin(String id) async {
    try {
      final note = await _repository.togglePin(id);
      final index = state.notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final updatedNotes = [...state.notes];
        updatedNotes[index] = note;
        state = state.copyWith(notes: updatedNotes);
      }
    } catch (_) {}
  }
}

/// Notes list provider
final notesListProvider =
    StateNotifierProvider<NotesListNotifier, NotesListState>((ref) {
  return NotesListNotifier(ref.watch(notesRepositoryProvider));
});

/// Note tags provider
final noteTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.getTags();
});

// ==================== Files State ====================

/// Files list state
class FilesListState {
  final List<FileModel> files;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final PaginationInfo pagination;
  final String? fileTypeFilter;

  const FilesListState({
    this.files = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
    this.pagination = const PaginationInfo(),
    this.fileTypeFilter,
  });

  FilesListState copyWith({
    List<FileModel>? files,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    PaginationInfo? pagination,
    String? fileTypeFilter,
  }) {
    return FilesListState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      pagination: pagination ?? this.pagination,
      fileTypeFilter: fileTypeFilter ?? this.fileTypeFilter,
    );
  }
}

/// Files list notifier
class FilesListNotifier extends StateNotifier<FilesListState> {
  final FilesRepository _repository;

  FilesListNotifier(this._repository) : super(const FilesListState());

  /// Load files
  Future<void> loadFiles({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      files: refresh ? [] : state.files,
    );

    try {
      final result = await _repository.getFiles(
        page: 1,
        fileType: state.fileTypeFilter,
      );

      state = state.copyWith(
        files: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more files
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasNextPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getFiles(
        page: state.pagination.page + 1,
        fileType: state.fileTypeFilter,
      );

      state = state.copyWith(
        files: [...state.files, ...result.data],
        pagination: result.pagination,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Filter by type
  Future<void> filterByType(String? type) async {
    state = state.copyWith(fileTypeFilter: type);
    await loadFiles(refresh: true);
  }

  /// Upload file
  Future<FileModel?> uploadFile(dynamic file) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0);

    try {
      final result = await _repository.uploadFile(
        file,
        onProgress: (sent, total) {
          state = state.copyWith(uploadProgress: sent / total);
        },
      );

      state = state.copyWith(
        files: [result, ...state.files],
        isUploading: false,
        uploadProgress: 0,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete file
  Future<bool> deleteFile(String id) async {
    try {
      await _repository.deleteFile(id);
      state = state.copyWith(
        files: state.files.where((f) => f.id != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add file to list (after upload elsewhere)
  void addFile(FileModel file) {
    state = state.copyWith(files: [file, ...state.files]);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Files list provider
final filesListProvider =
    StateNotifierProvider<FilesListNotifier, FilesListState>((ref) {
  return FilesListNotifier(ref.watch(filesRepositoryProvider));
});

/// File stats provider
final fileStatsProvider = FutureProvider<FileStats>((ref) async {
  final repository = ref.watch(filesRepositoryProvider);
  return repository.getFileStats();
});

// ==================== Jobs State ====================

/// Jobs list state
class JobsListState {
  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final PaginationInfo pagination;
  final String? typeFilter;
  final String? statusFilter;

  const JobsListState({
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.pagination = const PaginationInfo(),
    this.typeFilter,
    this.statusFilter,
  });

  JobsListState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    PaginationInfo? pagination,
    String? typeFilter,
    String? statusFilter,
  }) {
    return JobsListState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      pagination: pagination ?? this.pagination,
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

/// Jobs list notifier
class JobsListNotifier extends StateNotifier<JobsListState> {
  final JobsRepository _repository;

  JobsListNotifier(this._repository) : super(const JobsListState());

  /// Load jobs
  Future<void> loadJobs({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      jobs: refresh ? [] : state.jobs,
    );

    try {
      final result = await _repository.getJobs(
        page: 1,
        type: state.typeFilter,
        status: state.statusFilter,
      );

      state = state.copyWith(
        jobs: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more jobs
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasNextPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getJobs(
        page: state.pagination.page + 1,
        type: state.typeFilter,
        status: state.statusFilter,
      );

      state = state.copyWith(
        jobs: [...state.jobs, ...result.data],
        pagination: result.pagination,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Filter by type
  Future<void> filterByType(String? type) async {
    state = state.copyWith(typeFilter: type);
    await loadJobs(refresh: true);
  }

  /// Filter by status
  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status);
    await loadJobs(refresh: true);
  }

  /// Add job to list
  void addJob(Job job) {
    state = state.copyWith(jobs: [job, ...state.jobs]);
  }

  /// Update job in list
  void updateJob(Job job) {
    final index = state.jobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      final updatedJobs = [...state.jobs];
      updatedJobs[index] = job;
      state = state.copyWith(jobs: updatedJobs);
    }
  }

  /// Delete a job (cancel/remove from list)
  Future<void> deleteJob(String id) async {
    try {
      await _repository.cancelJob(id);
      state = state.copyWith(jobs: state.jobs.where((j) => j.id != id).toList());
    } catch (_) {
      rethrow;
    }
  }

  /// Retry a failed job
  Future<void> retryJob(String id) async {
    try {
      final job = await _repository.retryJob(id);
      final index = state.jobs.indexWhere((j) => j.id == id);
      if (index != -1) {
        final updated = [...state.jobs];
        updated[index] = job;
        state = state.copyWith(jobs: updated);
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Clear all jobs from local state
  void clearAllJobs() {
    state = state.copyWith(jobs: []);
  }
}

/// Jobs list provider
final jobsListProvider =
    StateNotifierProvider<JobsListNotifier, JobsListState>((ref) {
  return JobsListNotifier(ref.watch(jobsRepositoryProvider));
});

/// Recent jobs provider
final recentJobsProvider = FutureProvider<List<Job>>((ref) async {
  final repository = ref.watch(jobsRepositoryProvider);
  return repository.getRecentJobs(limit: 5);
});

/// Job stats provider
final jobStatsProvider = FutureProvider<JobStats>((ref) async {
  final repository = ref.watch(jobsRepositoryProvider);
  return repository.getJobStats();
});

// ==================== Job Detail Provider ====================

class JobDetailState {
  final Job? job;
  final bool isLoading;
  final String? error;

  const JobDetailState({this.job, this.isLoading = false, this.error});

  JobDetailState copyWith({Job? job, bool? isLoading, String? error}) {
    return JobDetailState(
      job: job ?? this.job,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class JobDetailNotifier extends StateNotifier<JobDetailState> {
  final JobsRepository _repository;
  final String jobId;

  JobDetailNotifier(this._repository, this.jobId) : super(const JobDetailState());

  Future<void> loadJob() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final job = await _repository.getJob(jobId);
      state = state.copyWith(job: job, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> retryJob() async {
    try {
      await _repository.retryJob(jobId);
      await loadJob();
    } catch (e) {
      rethrow;
    }
  }
}

final jobDetailProvider = StateNotifierProvider.family<JobDetailNotifier, JobDetailState, String>((ref, jobId) {
  return JobDetailNotifier(ref.watch(jobsRepositoryProvider), jobId);
});

// ==================== Selected Files for Operations ====================

/// Selected files notifier for conversion/compression operations
class SelectedFilesNotifier extends StateNotifier<List<FileModel>> {
  SelectedFilesNotifier() : super([]);

  /// Add file
  void addFile(FileModel file) {
    if (!state.any((f) => f.id == file.id)) {
      state = [...state, file];
    }
  }

  /// Remove file
  void removeFile(String id) {
    state = state.where((f) => f.id != id).toList();
  }

  /// Clear all
  void clear() {
    state = [];
  }

  /// Set files
  void setFiles(List<FileModel> files) {
    state = files;
  }

  /// Reorder files
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = state[oldIndex];
    final newList = [...state];
    newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
  }

  /// Get file IDs
  List<String> get fileIds => state.map((f) => f.id).toList();
}

/// Selected files provider
final selectedFilesProvider =
    StateNotifierProvider<SelectedFilesNotifier, List<FileModel>>((ref) {
  return SelectedFilesNotifier();
});

// ==================== App Settings ====================

/// App settings provider
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAppSettings();
});

/// Base URL provider
final baseUrlProvider = StateProvider<String>((ref) {
  return AppConstants.defaultBaseUrl;
});

/// Default quality provider
final defaultQualityProvider = StateProvider<int>((ref) {
  return AppConstants.highQuality;
});

/// Default format provider
final defaultFormatProvider = StateProvider<String>((ref) {
  return 'pdf';
});

// ==================== Conversion Controller ====================

/// A simple conversion controller used by screens to start conversions.
/// This is intentionally lightweight — it forwards calls to the
/// `ConversionRepository`. Implement upload and richer state as needed.
class ConversionController extends StateNotifier<void> {
  final ConversionRepository _repository;

  ConversionController(this._repository) : super(null);

  Future<Job> convertImagesToPdf(List<String> pathsOrIds, [Map<String, dynamic>? options]) async {
    // If pathsOrIds look like ids (no path separators), assume they are ids
    final looksLikeId = pathsOrIds.isNotEmpty && !pathsOrIds.first.contains('/');
    if (looksLikeId) {
      return _repository.imagesToPdf(fileIds: pathsOrIds);
    }

    // For local paths, we would need to upload first, but this is handled in the UI layer
    // This method is kept for backwards compatibility
    throw UnimplementedError('Use the UI layer to handle file uploads before conversion');
  }
}

final conversionProvider = StateNotifierProvider<ConversionController, void>((ref) {
  return ConversionController(ref.watch(conversionRepositoryProvider));
});

/// Alias provider for PDF-specific operations (backwards compatibility)
final pdfRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ref.watch(conversionRepositoryProvider);
});

// ==================== Loading States ====================

/// Global loading provider
final globalLoadingProvider = StateProvider<bool>((ref) => false);

/// Loading message provider
final loadingMessageProvider = StateProvider<String?>((ref) => null);
