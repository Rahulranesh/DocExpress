import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Local Notes Service - manages notes locally using Hive
class LocalNotesService {
  static const _uuid = Uuid();
  static const String _notesBoxName = 'local_notes';
  
  Box<Map>? _notesBox;
  bool _initialized = false;

  /// Initialize the notes service
  Future<void> init() async {
    if (_initialized) return;
    
    _notesBox = await Hive.openBox<Map>(_notesBoxName);
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Create a new note
  Future<LocalNote> createNote({
    required String title,
    String content = '',
    List<String>? tags,
    bool pinned = false,
    String? color,
  }) async {
    await _ensureInitialized();

    final noteId = _uuid.v4();
    final now = DateTime.now();

    final note = LocalNote(
      id: noteId,
      title: title,
      content: content,
      tags: tags ?? [],
      pinned: pinned,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    await _notesBox!.put(noteId, note.toMap());
    return note;
  }

  /// Get all notes
  Future<List<LocalNote>> getAllNotes({
    bool? pinned,
    String? tag,
    String? search,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    await _ensureInitialized();

    var notes = _notesBox!.values
        .map((map) => LocalNote.fromMap(Map<String, dynamic>.from(map)))
        .toList();

    // Filter by pinned status
    if (pinned != null) {
      notes = notes.where((n) => n.pinned == pinned).toList();
    }

    // Filter by tag
    if (tag != null && tag.isNotEmpty) {
      notes = notes.where((n) => n.tags.contains(tag)).toList();
    }

    // Search by title or content
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      notes = notes.where((n) =>
          n.title.toLowerCase().contains(searchLower) ||
          n.content.toLowerCase().contains(searchLower)
      ).toList();
    }

    // Sort
    notes.sort((a, b) {
      // Pinned notes always come first
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }

      int comparison;
      switch (sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
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

    return notes;
  }

  /// Get note by ID
  Future<LocalNote?> getNote(String id) async {
    await _ensureInitialized();

    final map = _notesBox!.get(id);
    if (map == null) return null;
    
    return LocalNote.fromMap(Map<String, dynamic>.from(map));
  }

  /// Update a note
  Future<LocalNote?> updateNote(
    String id, {
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
    String? color,
  }) async {
    await _ensureInitialized();

    final note = await getNote(id);
    if (note == null) return null;

    final updatedNote = note.copyWith(
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
      color: color,
      updatedAt: DateTime.now(),
    );

    await _notesBox!.put(id, updatedNote.toMap());
    return updatedNote;
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    await _ensureInitialized();
    await _notesBox!.delete(id);
  }

  /// Delete multiple notes
  Future<void> deleteNotes(List<String> ids) async {
    for (final id in ids) {
      await deleteNote(id);
    }
  }

  /// Toggle pin status
  Future<LocalNote?> togglePin(String id) async {
    final note = await getNote(id);
    if (note == null) return null;

    return updateNote(id, pinned: !note.pinned);
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    await _ensureInitialized();

    final tags = <String>{};
    for (final map in _notesBox!.values) {
      final note = LocalNote.fromMap(Map<String, dynamic>.from(map));
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  /// Get notes count
  Future<int> getNotesCount() async {
    await _ensureInitialized();
    return _notesBox!.length;
  }

  /// Search notes
  Future<List<LocalNote>> searchNotes(String query) async {
    return getAllNotes(search: query);
  }

  /// Get recent notes
  Future<List<LocalNote>> getRecentNotes({int limit = 10}) async {
    final notes = await getAllNotes(sortBy: 'updatedAt', descending: true);
    return notes.take(limit).toList();
  }

  /// Clear all notes (use with caution)
  Future<void> clearAllNotes() async {
    await _ensureInitialized();
    await _notesBox!.clear();
  }

  /// Export note to text
  String exportNoteToText(LocalNote note) {
    final buffer = StringBuffer();
    buffer.writeln('Title: ${note.title}');
    buffer.writeln('Created: ${note.createdAt.toLocal()}');
    buffer.writeln('Updated: ${note.updatedAt.toLocal()}');
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(', ')}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(note.content);
    return buffer.toString();
  }
}

/// Local note model
class LocalNote {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool pinned;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? attachmentIds;

  LocalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.pinned,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'pinned': pinned,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentIds': attachmentIds,
    };
  }

  factory LocalNote.fromMap(Map<String, dynamic> map) {
    return LocalNote(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      pinned: map['pinned'] as bool? ?? false,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attachmentIds: map['attachmentIds'] != null 
          ? List<String>.from(map['attachmentIds']) 
          : null,
    );
  }

  LocalNote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachmentIds,
  }) {
    return LocalNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  /// Get preview of content (first few characters)
  String get preview {
    if (content.isEmpty) return '';
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /// Check if note has content
  bool get hasContent => content.trim().isNotEmpty;

  /// Get word count
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}
