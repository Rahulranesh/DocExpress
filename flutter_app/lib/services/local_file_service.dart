import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';

/// Local File Service - manages files locally using Hive for metadata
class LocalFileService {
  static const _uuid = Uuid();
  static const String _filesBoxName = 'local_files';

  Box<Map>? _filesBox;
  bool _initialized = false;

  /// Initialize the file service
  Future<void> init() async {
    if (_initialized) return;

    _filesBox = await Hive.openBox<Map>(_filesBoxName);
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Get the app's documents directory for storing files
  Future<Directory> _getFilesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final filesDir = Directory(path.join(dir.path, 'docxpress_files'));
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  /// Copy a file to app storage and track it
  Future<LocalFile> saveFile(File sourceFile, {String? category}) async {
    await _ensureInitialized();

    final filesDir = await _getFilesDir();
    final fileId = _uuid.v4();
    final fileName = path.basename(sourceFile.path);
    final extension = path.extension(fileName).toLowerCase();

    // Determine file type
    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';
    final fileType = _getFileType(mimeType);

    // Create subdirectory for file type
    final typeDir = Directory(path.join(filesDir.path, fileType));
    if (!await typeDir.exists()) {
      await typeDir.create(recursive: true);
    }

    // Copy file to app storage
    final destPath = path.join(typeDir.path, '$fileId$extension');
    await sourceFile.copy(destPath);

    // Get file stats
    final destFile = File(destPath);
    final stat = await destFile.stat();

    // Create file record
    final localFile = LocalFile(
      id: fileId,
      name: fileName,
      path: destPath,
      mimeType: mimeType,
      fileType: fileType,
      size: stat.size,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive
    await _filesBox!.put(fileId, localFile.toMap());

    return localFile;
  }

  /// Save file from bytes
  Future<LocalFile> saveFileFromBytes({
    required List<int> bytes,
    required String fileName,
    String? category,
  }) async {
    await _ensureInitialized();

    final filesDir = await _getFilesDir();
    final fileId = _uuid.v4();
    final extension = path.extension(fileName).toLowerCase();

    // Determine file type
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final fileType = _getFileType(mimeType);

    // Create subdirectory for file type
    final typeDir = Directory(path.join(filesDir.path, fileType));
    if (!await typeDir.exists()) {
      await typeDir.create(recursive: true);
    }

    // Write file
    final destPath = path.join(typeDir.path, '$fileId$extension');
    final destFile = File(destPath);
    await destFile.writeAsBytes(bytes);

    // Create file record
    final localFile = LocalFile(
      id: fileId,
      name: fileName,
      path: destPath,
      mimeType: mimeType,
      fileType: fileType,
      size: bytes.length,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive
    await _filesBox!.put(fileId, localFile.toMap());

    return localFile;
  }

  /// Get all files
  Future<List<LocalFile>> getAllFiles({
    String? fileType,
    String? category,
    String? search,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    await _ensureInitialized();

    var files = _filesBox!.values
        .map((map) => LocalFile.fromMap(Map<String, dynamic>.from(map)))
        .toList();

    // Filter by file type
    if (fileType != null && fileType.isNotEmpty) {
      files = files.where((f) => f.fileType == fileType).toList();
    }

    // Filter by category
    if (category != null && category.isNotEmpty) {
      files = files.where((f) => f.category == category).toList();
    }

    // Search by name
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      files = files
          .where((f) => f.name.toLowerCase().contains(searchLower))
          .toList();
    }

    // Sort
    files.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'size':
          comparison = a.size.compareTo(b.size);
          break;
        case 'updatedAt':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return descending ? -comparison : comparison;
    });

    return files;
  }

  /// Get file by ID
  Future<LocalFile?> getFile(String id) async {
    await _ensureInitialized();

    final map = _filesBox!.get(id);
    if (map == null) return null;

    return LocalFile.fromMap(Map<String, dynamic>.from(map));
  }

  /// Get files by IDs
  Future<List<LocalFile>> getFilesByIds(List<String> ids) async {
    await _ensureInitialized();

    final files = <LocalFile>[];
    for (final id in ids) {
      final file = await getFile(id);
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }

  /// Delete file
  Future<void> deleteFile(String id) async {
    await _ensureInitialized();

    final file = await getFile(id);
    if (file != null) {
      // Delete actual file
      final actualFile = File(file.path);
      if (await actualFile.exists()) {
        await actualFile.delete();
      }

      // Remove from Hive
      await _filesBox!.delete(id);
    }
  }

  /// Delete multiple files
  Future<void> deleteFiles(List<String> ids) async {
    for (final id in ids) {
      await deleteFile(id);
    }
  }

  /// Update file metadata
  Future<LocalFile?> updateFile(String id,
      {String? name, String? category}) async {
    await _ensureInitialized();

    final file = await getFile(id);
    if (file == null) return null;

    final updatedFile = file.copyWith(
      name: name,
      category: category,
      updatedAt: DateTime.now(),
    );

    await _filesBox!.put(id, updatedFile.toMap());
    return updatedFile;
  }

  /// Toggle favorite status
  Future<LocalFile?> toggleFavorite(String id) async {
    await _ensureInitialized();

    final file = await getFile(id);
    if (file == null) return null;

    final updatedFile = file.copyWith(
      isFavorite: !file.isFavorite,
      updatedAt: DateTime.now(),
    );

    await _filesBox!.put(id, updatedFile.toMap());
    return updatedFile;
  }

  /// Check if file exists
  Future<bool> fileExists(String id) async {
    await _ensureInitialized();
    return _filesBox!.containsKey(id);
  }

  /// Get total storage used
  Future<int> getTotalStorageUsed() async {
    await _ensureInitialized();

    int total = 0;
    for (final map in _filesBox!.values) {
      final file = LocalFile.fromMap(Map<String, dynamic>.from(map));
      total += file.size;
    }
    return total;
  }

  /// Get file count
  Future<int> getFileCount({String? fileType}) async {
    await _ensureInitialized();

    if (fileType == null) {
      return _filesBox!.length;
    }

    return _filesBox!.values
        .map((map) => LocalFile.fromMap(Map<String, dynamic>.from(map)))
        .where((f) => f.fileType == fileType)
        .length;
  }

  /// Determine file type from MIME type
  String _getFileType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType == 'application/pdf') return 'pdf';
    if (mimeType.contains('document') ||
        mimeType.contains('word') ||
        mimeType.contains('text')) {
      return 'document';
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return 'presentation';
    }
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return 'spreadsheet';
    }
    return 'other';
  }

  /// Clear all files (use with caution)
  Future<void> clearAllFiles() async {
    await _ensureInitialized();

    // Delete all actual files
    final filesDir = await _getFilesDir();
    if (await filesDir.exists()) {
      await filesDir.delete(recursive: true);
    }

    // Clear Hive box
    await _filesBox!.clear();
  }
}

/// Local file model
class LocalFile {
  final String id;
  final String name;
  final String path;
  final String mimeType;
  final String fileType;
  final int size;
  final String? category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  LocalFile({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.fileType,
    required this.size,
    this.category,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'mimeType': mimeType,
      'fileType': fileType,
      'size': size,
      'category': category,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory LocalFile.fromMap(Map<String, dynamic> map) {
    return LocalFile(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      mimeType: map['mimeType'] as String,
      fileType: map['fileType'] as String,
      size: map['size'] as int,
      category: map['category'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  LocalFile copyWith({
    String? id,
    String? name,
    String? path,
    String? mimeType,
    String? fileType,
    int? size,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LocalFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      fileType: fileType ?? this.fileType,
      size: size ?? this.size,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get extension => path.split('.').last.toLowerCase();
}
