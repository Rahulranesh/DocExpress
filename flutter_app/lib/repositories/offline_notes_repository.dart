import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/local_notes_service.dart';
import '../services/offline_service_manager.dart';

/// Offline Notes Repository - replaces API-based notes repository
/// Uses local Hive storage instead of MongoDB
class OfflineNotesRepository {
  final LocalNotesService _notesService;

  OfflineNotesRepository({LocalNotesService? notesService})
      : _notesService = notesService ?? offlineServices.notesService;

  /// Get all notes for current user with pagination (local)
  Future<PaginatedResponse<Note>> getNotes({
    int page = 1,
    int limit = 20,
    bool? pinned,
    String? tag,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    debugPrint('📝 [LOCAL STORAGE] Notes: Fetching notes from Hive (page: $page)');
    final localNotes = await _notesService.getAllNotes(
      pinned: pinned,
      tag: tag,
      search: search,
      sortBy: sortBy,
      descending: sortOrder == 'desc',
    );

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final paginatedNotes = localNotes.skip(startIndex).take(limit).toList();

    // Convert LocalNote to Note model
    final notes = paginatedNotes.map((ln) => _convertToNote(ln)).toList();
    debugPrint('✅ [LOCAL STORAGE] Notes: Found ${localNotes.length} total notes, returning ${notes.length} for page $page');

    return PaginatedResponse<Note>(
      data: notes,
      pagination: PaginationInfo(
        page: page,
        limit: limit,
        total: localNotes.length,
        totalPages: (localNotes.length / limit).ceil(),
      ),
    );
  }

  /// Get single note by ID
  Future<Note> getNote(String id) async {
    final localNote = await _notesService.getNote(id);
    if (localNote == null) {
      throw Exception('Note not found');
    }
    return _convertToNote(localNote);
  }

  /// Create a new note
  Future<Note> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
    bool pinned = false,
    String? color,
  }) async {
    debugPrint('📝 [LOCAL STORAGE] Notes: Creating note in Hive - "$title"');
    final localNote = await _notesService.createNote(
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
      color: color,
    );
    debugPrint('✅ [LOCAL STORAGE] Notes: Note created with ID: ${localNote.id}');
    return _convertToNote(localNote);
  }

  /// Update a note
  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
    String? color,
  }) async {
    debugPrint('📝 [LOCAL STORAGE] Notes: Updating note in Hive - ID: $id');
    final localNote = await _notesService.updateNote(
      id,
      title: title,
      content: content,
      tags: tags,
      pinned: pinned,
      color: color,
    );
    if (localNote == null) {
      throw Exception('Note not found');
    }
    debugPrint('✅ [LOCAL STORAGE] Notes: Note updated successfully');
    return _convertToNote(localNote);
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    debugPrint('📝 [LOCAL STORAGE] Notes: Deleting note from Hive - ID: $id');
    await _notesService.deleteNote(id);
    debugPrint('✅ [LOCAL STORAGE] Notes: Note deleted successfully');
  }

  /// Delete multiple notes
  Future<void> deleteNotes(List<String> ids) async {
    await _notesService.deleteNotes(ids);
  }

  /// Toggle pin status
  Future<Note> togglePin(String id) async {
    final localNote = await _notesService.togglePin(id);
    if (localNote == null) {
      throw Exception('Note not found');
    }
    return _convertToNote(localNote);
  }

  /// Get all unique tags (named to match original interface)
  Future<List<String>> getTags() async {
    return _notesService.getAllTags();
  }

  /// Get all unique tags (alias)
  Future<List<String>> getAllTags() async {
    return getTags();
  }

  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    final localNotes = await _notesService.searchNotes(query);
    return localNotes.map((ln) => _convertToNote(ln)).toList();
  }

  /// Get recent notes
  Future<List<Note>> getRecentNotes({int limit = 10}) async {
    final localNotes = await _notesService.getRecentNotes(limit: limit);
    return localNotes.map((ln) => _convertToNote(ln)).toList();
  }

  /// Convert LocalNote to Note model (for compatibility with existing UI)
  Note _convertToNote(LocalNote localNote) {
    return Note(
      id: localNote.id,
      title: localNote.title,
      content: localNote.content,
      tags: localNote.tags,
      pinned: localNote.pinned,
      createdAt: localNote.createdAt,
      updatedAt: localNote.updatedAt,
    );
  }
}
