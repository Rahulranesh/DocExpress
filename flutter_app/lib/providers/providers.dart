import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

// Import ONLY offline repositories - MongoDB has been completely removed
import '../repositories/offline_notes_repository.dart';
import '../repositories/offline_auth_repository.dart';
import '../repositories/offline_files_repository.dart';
import '../repositories/offline_conversion_repository.dart';
import '../repositories/offline_jobs_repository.dart';
import '../repositories/offline_compression_repository.dart';

// ==================== FULLY OFFLINE MODE ====================
// This app operates completely offline with local storage
// No backend server or MongoDB required

// ==================== Core Services ====================

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device),
  );
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(secureStorage: ref.watch(secureStorageProvider));
});

/// API service provider (for backend conversions)
final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  debugPrint('🔧 [PROVIDER] API Service: Initialized for backend conversions');
  return ApiService(storageService: storageService);
});

// ==================== Offline Repositories ====================

/// Auth repository provider (fully offline - Hive local storage)
final authRepositoryProvider = Provider<OfflineAuthRepository>((ref) {
  debugPrint('🔧 [PROVIDER] Auth: Using LOCAL storage (Hive)');
  return OfflineAuthRepository();
});

/// Notes repository provider (fully offline - Hive local storage)
final notesRepositoryProvider = Provider<OfflineNotesRepository>((ref) {
  debugPrint('🔧 [PROVIDER] Notes: Using LOCAL storage (Hive)');
  return OfflineNotesRepository();
});

/// Files repository provider (fully offline - Local file system)
final filesRepositoryProvider = Provider<OfflineFilesRepository>((ref) {
  debugPrint('🔧 [PROVIDER] Files: Using LOCAL file system');
  return OfflineFilesRepository();
});

/// Jobs repository provider (fully offline - Hive local storage)
final jobsRepositoryProvider = Provider<OfflineJobsRepository>((ref) {
  debugPrint('🔧 [PROVIDER] Jobs: Using LOCAL storage (Hive)');
  return OfflineJobsRepository();
});

/// Conversion repository provider (fully offline - Local processing)
final conversionRepositoryProvider =
    Provider<OfflineConversionRepository>((ref) {
  debugPrint(
      '🔧 [PROVIDER] Conversion: Using LOCAL processing with BACKEND fallback');
  return OfflineConversionRepository(
    apiService: ref.watch(apiServiceProvider),
  );
});

/// Compression repository provider (fully offline - Local processing)
final compressionRepositoryProvider =
    Provider<OfflineCompressionRepository>((ref) {
  debugPrint('🔧 [PROVIDER] Compression: Using LOCAL processing');
  return OfflineCompressionRepository();
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

/// Auth state notifier (fully offline - local storage only)
class AuthStateNotifier extends StateNotifier<AuthState> {
  final OfflineAuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(AuthState.initial());

  /// Initialize auth state - check for existing local user
  Future<void> initialize() async {
    state = AuthState.loading();

    try {
      debugPrint('🔐 [AUTH] Checking local authentication...');
      final user = await _authRepository.getCurrentUser();
      debugPrint('✅ [AUTH] User found locally: ${user.email}');
      state = AuthState.authenticated(user);
    } catch (e) {
      debugPrint('ℹ️ [AUTH] No local user found or error: $e');
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
      debugPrint('🔐 [AUTH] Logging in locally: $email');
      final response =
          await _authRepository.login(email: email, password: password);
      debugPrint('✅ [AUTH] Login successful');
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Login failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
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
      debugPrint('📝 [AUTH] Registering locally: $email');
      final response = await _authRepository.register(
          name: name, email: email, password: password);
      debugPrint('✅ [AUTH] Registration successful');
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Registration failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('🚪 [AUTH] Logging out locally');
      await _authRepository.logout();
    } catch (_) {}
    state = AuthState.unauthenticated();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  /// Update profile
  Future<bool> updateProfile({String? name}) async {
    try {
      debugPrint('📝 [AUTH] Updating profile locally');
      final user = await _authRepository.updateProfile(name: name);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Profile update failed: $e');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('🔑 [AUTH] Changing password locally');
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Password change failed: $e');
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      debugPrint('🗑️ [AUTH] Deleting account locally');
      await _authRepository.deleteAccount();
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Account deletion failed: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Continue as guest
  Future<bool> continueAsGuest() async {
    try {
      debugPrint('👤 [AUTH] Continuing as guest');
      final response = await _authRepository.continueAsGuest();
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      debugPrint('❌ [AUTH] Guest login failed: $e');
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
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
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

/// Notes list notifier (fully offline - Hive local storage)
class NotesListNotifier extends StateNotifier<NotesListState> {
  final OfflineNotesRepository _repository;

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

/// Files list notifier (fully offline - local file system)
class FilesListNotifier extends StateNotifier<FilesListState> {
  final OfflineFilesRepository _repository;

  FilesListNotifier(this._repository) : super(const FilesListState());

  /// Load files
  Future<void> loadFiles({bool refresh = false}) async {
    // Only skip if already loading the same type of request
    if (state.isLoading && !refresh) {
      debugPrint('📂 FilesListNotifier: Already loading, skipping...');
      return;
    }

    debugPrint('📂 FilesListNotifier: Loading files (refresh: $refresh)...');
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

      debugPrint('📂 FilesListNotifier: Loaded ${result.data.length} files');
      state = state.copyWith(
        files: List<FileModel>.from(result.data),
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('📂 FilesListNotifier: Error loading files: $e');
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
        files: [...state.files, ...List<FileModel>.from(result.data)],
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
      debugPrint('🗑️ Deleting file with id: $id');
      await _repository.deleteFile(id);
      debugPrint('🗑️ File deleted from server, reloading files from server');
      // Reload files from server to get correct pagination
      // This ensures the list stays in sync with the database
      await loadFiles(refresh: true);
      debugPrint('🗑️ Files reloaded, current count: ${state.files.length}');
      return true;
    } catch (e) {
      debugPrint('🗑️ Delete failed: $e');
      return false;
    }
  }

  /// Rename file
  Future<bool> renameFile(String id, String newName) async {
    try {
      final updatedFile = await _repository.renameFile(id, newName);
      state = state.copyWith(
        files: state.files.map((f) => f.id == id ? updatedFile : f).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String id) async {
    try {
      final updatedFile = await _repository.toggleFavorite(id);
      state = state.copyWith(
        files: state.files.map((f) => f.id == id ? updatedFile : f).toList(),
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

/// Jobs list notifier (fully offline - local storage)
class JobsListNotifier extends StateNotifier<JobsListState> {
  final OfflineJobsRepository _repository;

  JobsListNotifier(this._repository) : super(const JobsListState());

  /// Load jobs
  Future<void> loadJobs({bool refresh = false}) async {
    // Only skip if already loading and not a forced refresh
    if (state.isLoading && !refresh) {
      debugPrint('📋 JobsListNotifier: Already loading, skipping...');
      return;
    }

    // Don't clear jobs immediately on refresh - keep showing old data while loading
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      debugPrint('🔄 Loading jobs... refresh=$refresh');
      final result = await _repository.getJobs(
        page: 1,
        type: state.typeFilter,
        status: state.statusFilter,
      );

      debugPrint('✅ Jobs loaded: ${result.data.length} jobs');
      debugPrint(
          '📊 Pagination: page=${result.pagination.page}, total=${result.pagination.total}');

      state = state.copyWith(
        jobs: result.data,
        pagination: result.pagination,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading jobs: $e');
      debugPrint('📍 Stack trace: $stackTrace');
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

  /// Delete a job (remove from database)
  Future<bool> deleteJob(String id) async {
    try {
      debugPrint('🗑️ Deleting job with id: $id');
      await _repository.deleteJob(id);
      debugPrint('🗑️ Job deleted locally, reloading jobs');
      // Reload jobs to get correct pagination
      await loadJobs(refresh: true);
      debugPrint('🗑️ Jobs reloaded, current count: ${state.jobs.length}');
      return true;
    } catch (e) {
      debugPrint('🗑️ Delete job failed: $e');
      return false;
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
  final OfflineJobsRepository _repository;
  final String jobId;

  JobDetailNotifier(this._repository, this.jobId)
      : super(const JobDetailState());

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

final jobDetailProvider =
    StateNotifierProvider.family<JobDetailNotifier, JobDetailState, String>(
        (ref, jobId) {
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

/// App settings notifier for managing settings state
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;

  AppSettingsNotifier(this._storageService) : super(const AppSettings());

  Future<void> loadSettings() async {
    state = await _storageService.getAppSettings();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storageService.saveNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setAutoDeleteCompleted(bool enabled) async {
    await _storageService.saveAutoDeleteCompleted(enabled);
    state = state.copyWith(autoDeleteCompleted: enabled);
  }

  Future<void> setDefaultQuality(int quality) async {
    await _storageService.saveDefaultQuality(quality);
    state = state.copyWith(defaultImageQuality: quality);
  }

  Future<void> setStorageLocation(String location) async {
    await _storageService.saveStorageLocation(location);
    state = state.copyWith(storageLocation: location);
  }
}

/// App settings provider (StateNotifier version for real-time updates)
final appSettingsNotifierProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final notifier = AppSettingsNotifier(storageService);
  // Load settings on creation
  notifier.loadSettings();
  return notifier;
});

/// App settings provider (legacy FutureProvider)
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
/// This is fully offline - all conversions happen locally on device.
class ConversionController extends StateNotifier<void> {
  final OfflineConversionRepository _repository;

  ConversionController(this._repository) : super(null);

  Future<dynamic> convertImagesToPdf(List<String> pathsOrIds,
      [Map<String, dynamic>? options]) async {
    debugPrint('🔄 [CONVERSION] Converting images to PDF locally');
    return _repository.imagesToPdf(
        filePaths: pathsOrIds, title: options?['title']);
  }
}

final conversionProvider =
    StateNotifierProvider<ConversionController, void>((ref) {
  return ConversionController(ref.watch(conversionRepositoryProvider));
});

/// Alias provider for PDF-specific operations (backwards compatibility)
final pdfRepositoryProvider = Provider<dynamic>((ref) {
  return ref.watch(conversionRepositoryProvider);
});

// ==================== Loading States ====================

/// Global loading provider
final globalLoadingProvider = StateProvider<bool>((ref) => false);

/// Loading message provider
final loadingMessageProvider = StateProvider<String?>((ref) => null);
