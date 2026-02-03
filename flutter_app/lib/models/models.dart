// Data Models for DocXpress App
import 'package:equatable/equatable.dart';

// ==================== User Model ====================

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, createdAt, updatedAt];
}

// ==================== Auth Models ====================

class AuthResponse {
  final User user;
  final String token;
  final String? message;

  const AuthResponse({
    required this.user,
    required this.token,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthResponse(
      user: User.fromJson(data['user'] ?? {}),
      token: data['token'] ?? '',
      message: json['message'],
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
    };
  }
}

// ==================== Note Model ====================

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.tags = const [],
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      pinned: json['pinned'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'tags': tags,
      'pinned': pinned,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, content, tags, pinned, createdAt, updatedAt];
}

// ==================== File Model ====================

class FileModel extends Equatable {
  final String id;
  final String originalName;
  final String filename;
  final String mimeType;
  final int size;
  final String storagePath;
  final String storageKey;
  final String fileType;
  final String? extension;
  final FileMetadata? metadata;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? sourceJob;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FileModel({
    required this.id,
    required this.originalName,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.storagePath,
    required this.storageKey,
    required this.fileType,
    this.extension,
    this.metadata,
    this.isDeleted = false,
    this.isFavorite = false,
    this.deletedAt,
    this.sourceJob,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['_id'] ?? json['id'] ?? '',
      originalName: json['originalName'] ?? '',
      filename: json['filename'] ?? '',
      mimeType: json['mimeType'] ?? '',
      size: json['size'] ?? 0,
      storagePath: json['storagePath'] ?? '',
      storageKey: json['storageKey'] ?? '',
      fileType: json['fileType'] ?? 'other',
      extension: json['extension'],
      metadata: json['metadata'] != null
          ? FileMetadata.fromJson(json['metadata'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      isFavorite: json['isFavorite'] ?? json['favorite'] ?? false,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      sourceJob: json['sourceJob'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalName': originalName,
      'filename': filename,
      'mimeType': mimeType,
      'size': size,
      'storagePath': storagePath,
      'storageKey': storageKey,
      'fileType': fileType,
      'extension': extension,
      'metadata': metadata?.toJson(),
      'isDeleted': isDeleted,
      'isFavorite': isFavorite,
      'deletedAt': deletedAt?.toIso8601String(),
      'sourceJob': sourceJob,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool get isImage => fileType == 'image';
  bool get isPdf => fileType == 'pdf';
  bool get isVideo => fileType == 'video';
  bool get isDocument => fileType == 'document';

  /// Convenience alias expected by some UI files
  bool get isFavoriteFlag => isFavorite;

  @override
  List<Object?> get props => [
        id,
        originalName,
        filename,
        mimeType,
        size,
        fileType,
        isDeleted,
        isFavorite,
        createdAt
      ];
}

class FileMetadata {
  final int? width;
  final int? height;
  final double? duration;
  final int? pages;

  const FileMetadata({
    this.width,
    this.height,
    this.duration,
    this.pages,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      width: json['width'],
      height: json['height'],
      duration: json['duration']?.toDouble(),
      pages: json['pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'duration': duration,
      'pages': pages,
    };
  }
}

// ==================== Job Model ====================

class Job extends Equatable {
  final String id;
  final String userId;
  final String type;
  final JobStatus status;
  final List<FileModel> inputFiles;
  final List<FileModel> outputFiles;
  final Map<String, dynamic> options;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Job({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.inputFiles = const [],
    this.outputFiles = const [],
    this.options = const {},
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is String
          ? json['userId']
          : (json['userId']?['_id'] ?? ''),
      type: json['type'] ?? '',
      status: JobStatus.fromString(json['status'] ?? 'PENDING'),
      inputFiles: json['inputFiles'] != null
          ? (json['inputFiles'] as List)
              .where(
                  (f) => f != null) // Filter out null entries (deleted files)
              .map((f) => f is Map<String, dynamic>
                  ? FileModel.fromJson(f)
                  : FileModel(
                      id: f.toString(),
                      originalName: '',
                      filename: '',
                      mimeType: '',
                      size: 0,
                      storagePath: '',
                      storageKey: '',
                      fileType: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ))
              .toList()
          : const [],
      outputFiles: json['outputFiles'] != null
          ? (json['outputFiles'] as List)
              .where(
                  (f) => f != null) // Filter out null entries (deleted files)
              .map((f) => f is Map<String, dynamic>
                  ? FileModel.fromJson(f)
                  : FileModel(
                      id: f.toString(),
                      originalName: '',
                      filename: '',
                      mimeType: '',
                      size: 0,
                      storagePath: '',
                      storageKey: '',
                      fileType: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ))
              .toList()
          : const [],
      options: json['options'] ?? const {},
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'status': status.value,
      'inputFiles': inputFiles.map((f) => f.toJson()).toList(),
      'outputFiles': outputFiles.map((f) => f.toJson()).toList(),
      'options': options,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  String get typeLabel {
    final labels = {
      'IMAGE_TO_PDF': 'Images to PDF',
      'IMAGE_TO_PPTX': 'Images to PPTX',
      'IMAGE_TO_DOCX': 'Images to DOCX',
      'IMAGE_TO_TXT': 'Image OCR',
      'IMAGE_FORMAT_CONVERT': 'Image Format',
      'IMAGE_TRANSFORM': 'Image Transform',
      'IMAGE_MERGE': 'Merge Images',
      'PDF_TO_PPTX': 'PDF to PPTX',
      'PDF_TO_DOCX': 'PDF to DOCX',
      'PDF_TO_TXT': 'PDF to Text',
      'PPTX_TO_PDF': 'PPTX to PDF',
      'DOCX_TO_PDF': 'DOCX to PDF',
      'PDF_MERGE': 'Merge PDFs',
      'PDF_SPLIT': 'Split PDF',
      'PDF_REORDER': 'Reorder PDF',
      'PDF_EXTRACT_IMAGES': 'Extract Images',
      'PDF_EXTRACT_TEXT': 'Extract Text',
      'COMPRESS_IMAGE': 'Compress Image',
      'COMPRESS_VIDEO': 'Compress Video',
      'COMPRESS_PDF': 'Compress PDF',
    };
    return labels[type] ?? type;
  }

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  /// Compatibility getters used by some UI screens
  List<String> get inputs => inputFiles
      .map((f) => f.originalName.isNotEmpty ? f.originalName : f.filename)
      .toList();

  List<String> get outputs => outputFiles
      .map((f) => f.originalName.isNotEmpty ? f.originalName : f.filename)
      .toList();

  double? get progress {
    final val = options['progress'];
    if (val == null) return null;
    if (val is num) return val.toDouble();
    try {
      return double.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  String? get error => errorMessage;

  String get statusString => status.value;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        status,
        inputFiles,
        outputFiles,
        options,
        errorMessage,
        createdAt,
        completedAt
      ];
}

enum JobStatus {
  pending('PENDING'),
  running('RUNNING'),
  completed('COMPLETED'),
  failed('FAILED');

  final String value;
  const JobStatus(this.value);

  factory JobStatus.fromString(String value) {
    return JobStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => JobStatus.pending,
    );
  }

  bool get isPending => this == JobStatus.pending;
  bool get isRunning => this == JobStatus.running;
  bool get isCompleted => this == JobStatus.completed;
  bool get isFailed => this == JobStatus.failed;
  bool get isInProgress => isPending || isRunning;
}

// ==================== API Response Models ====================

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJson,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : json['data'],
      message: json['message'],
      error: json['error'] != null ? ApiError.fromJson(json['error']) : null,
    );
  }
}

class ApiError {
  final String message;
  final String? code;

  const ApiError({
    required this.message,
    this.code,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error',
      code: json['code'],
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationInfo pagination;

  const PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final dataList = json['data'] as List? ?? [];
    return PaginatedResponse(
      data: dataList.map((item) => fromJson(item)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationInfo({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

// ==================== Request Models ====================

class ConversionRequest {
  final List<String> fileIds;
  final String? targetFormat;
  final int? quality;
  final String? pageSize;
  final Map<String, dynamic>? additionalOptions;

  const ConversionRequest({
    required this.fileIds,
    this.targetFormat,
    this.quality,
    this.pageSize,
    this.additionalOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      if (fileIds.length == 1) 'fileId': fileIds.first,
      if (fileIds.length > 1) 'fileIds': fileIds,
      if (targetFormat != null) 'targetFormat': targetFormat,
      if (quality != null) 'quality': quality,
      if (pageSize != null) 'pageSize': pageSize,
      ...?additionalOptions,
    };
  }
}

class ImageTransformRequest {
  final String fileId;
  final List<TransformOperation> operations;
  final String format;
  final int quality;

  const ImageTransformRequest({
    required this.fileId,
    required this.operations,
    this.format = 'jpeg',
    this.quality = 80,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'operations': operations.map((o) => o.toJson()).toList(),
      'format': format,
      'quality': quality,
    };
  }
}

class TransformOperation {
  final String type;
  final Map<String, dynamic>? options;

  const TransformOperation({
    required this.type,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (options != null) 'options': options,
    };
  }
}

class CompressionRequest {
  final String fileId;
  final int? quality;
  final int? maxWidth;
  final int? maxHeight;
  final String? format;
  final String? preset;
  final String? resolution;

  const CompressionRequest({
    required this.fileId,
    this.quality,
    this.maxWidth,
    this.maxHeight,
    this.format,
    this.preset,
    this.resolution,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      if (quality != null) 'quality': quality,
      if (maxWidth != null) 'maxWidth': maxWidth,
      if (maxHeight != null) 'maxHeight': maxHeight,
      if (format != null) 'format': format,
      if (preset != null) 'preset': preset,
      if (resolution != null) 'resolution': resolution,
    };
  }
}

class PdfMergeRequest {
  final List<String> fileIds;

  const PdfMergeRequest({required this.fileIds});

  Map<String, dynamic> toJson() => {'fileIds': fileIds};
}

class PdfSplitRequest {
  final String fileId;
  final List<PageRange> ranges;

  const PdfSplitRequest({
    required this.fileId,
    required this.ranges,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'ranges': ranges.map((r) => r.toJson()).toList(),
    };
  }
}

class PageRange {
  final int start;
  final int end;

  const PageRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class PdfReorderRequest {
  final String fileId;
  final List<int> pageOrder;

  const PdfReorderRequest({
    required this.fileId,
    required this.pageOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'pageOrder': pageOrder,
    };
  }
}

// ==================== Stats Models ====================

class FileStats {
  final Map<String, TypeStats> byType;
  final int totalFiles;
  final int totalSize;

  const FileStats({
    required this.byType,
    required this.totalFiles,
    required this.totalSize,
  });

  factory FileStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? json;
    final byTypeJson = stats['byType'] as Map<String, dynamic>? ?? {};
    return FileStats(
      byType: byTypeJson.map(
        (key, value) => MapEntry(key, TypeStats.fromJson(value)),
      ),
      totalFiles: stats['totalFiles'] ?? 0,
      totalSize: stats['totalSize'] ?? 0,
    );
  }

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class TypeStats {
  final int count;
  final int size;

  const TypeStats({required this.count, required this.size});

  factory TypeStats.fromJson(Map<String, dynamic> json) {
    return TypeStats(
      count: json['count'] ?? 0,
      size: json['size'] ?? json['totalSize'] ?? 0,
    );
  }
}

class JobStats {
  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> byType;

  const JobStats({
    required this.total,
    required this.byStatus,
    required this.byType,
  });

  factory JobStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? json;
    return JobStats(
      total: stats['total'] ?? 0,
      byStatus: Map<String, int>.from(stats['byStatus'] ?? {}),
      byType: Map<String, int>.from(stats['byType'] ?? {}),
    );
  }
}

// ==================== Settings Model ====================

class AppSettings {
  final ThemeModeSetting themeMode;
  final int defaultImageQuality;
  final String defaultOutputFormat;
  final String baseUrl;
  final bool onboardingCompleted;
  final bool notificationsEnabled;
  final bool autoDeleteCompleted;
  final String storageLocation;

  const AppSettings({
    this.themeMode = ThemeModeSetting.system,
    this.defaultImageQuality = 80,
    this.defaultOutputFormat = 'pdf',
    this.baseUrl = 'http://localhost:3000/api',
    this.onboardingCompleted = false,
    this.notificationsEnabled = true,
    this.autoDeleteCompleted = false,
    this.storageLocation = 'internal',
  });

  AppSettings copyWith({
    ThemeModeSetting? themeMode,
    int? defaultImageQuality,
    String? defaultOutputFormat,
    String? baseUrl,
    bool? onboardingCompleted,
    bool? notificationsEnabled,
    bool? autoDeleteCompleted,
    String? storageLocation,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
      defaultOutputFormat: defaultOutputFormat ?? this.defaultOutputFormat,
      baseUrl: baseUrl ?? this.baseUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoDeleteCompleted: autoDeleteCompleted ?? this.autoDeleteCompleted,
      storageLocation: storageLocation ?? this.storageLocation,
    );
  }
}

enum ThemeModeSetting {
  light,
  dark,
  system;

  String get label {
    switch (this) {
      case ThemeModeSetting.light:
        return 'Light';
      case ThemeModeSetting.dark:
        return 'Dark';
      case ThemeModeSetting.system:
        return 'System';
    }
  }
}
