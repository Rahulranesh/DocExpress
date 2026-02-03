import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Notes Repository - handles note CRUD operations
class NotesRepository {
  final ApiService _apiService;

  NotesRepository({required ApiService apiService}) : _apiService = apiService;

  /// Get all notes for current user with pagination
  Future<PaginatedResponse<Note>> getNotes({
    int page = 1,
    int limit = 20,
    bool? pinned,
    String? tag,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (pinned != null) queryParams['pinned'] = pinned.toString();
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _apiService.get(
      ApiEndpoints.notes,
      queryParameters: queryParams,
    );

    debugPrint('📥 Notes Response status: ${response.statusCode}');
    debugPrint('📦 Notes Response data: ${response.data}');

    if (response.statusCode == 200) {
      final responseData = response.data;

      // Handle different response formats
      List<dynamic> notesList;
      Map<String, dynamic> paginationData;

      if (responseData['data'] is List) {
        // Direct array format
        notesList = responseData['data'] as List;
        paginationData = responseData['pagination'] ?? {};
      } else if (responseData['data'] is Map) {
        // Nested format with 'notes' key
        final dataMap = responseData['data'] as Map<String, dynamic>;
        notesList = dataMap['notes'] as List? ?? [];
        paginationData =
            dataMap['pagination'] ?? responseData['pagination'] ?? {};
      } else {
        notesList = [];
        paginationData = {};
      }

      debugPrint('📊 Parsed ${notesList.length} notes');

      return PaginatedResponse<Note>(
        data: notesList
            .map((json) => Note.fromJson(json as Map<String, dynamic>))
            .toList(),
        pagination: PaginationInfo.fromJson(paginationData),
      );
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch notes',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get single note by ID
  Future<Note> getNote(String id) async {
    final response = await _apiService.get(ApiEndpoints.note(id));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return Note.fromJson(data is Map<String, dynamic> ? data : data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch note',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Create a new note
  Future<Note> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
    bool pinned = false,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.notes,
      data: {
        'title': title,
        'content': content,
        'tags': tags,
        'pinned': pinned,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'] ?? response.data;
      return Note.fromJson(data is Map<String, dynamic> ? data : data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to create note',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Update an existing note
  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
    List<String>? tags,
    bool? pinned,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (tags != null) data['tags'] = tags;
    if (pinned != null) data['pinned'] = pinned;

    final response = await _apiService.put(
      ApiEndpoints.note(id),
      data: data,
    );

    if (response.statusCode == 200) {
      final responseData = response.data['data'] ?? response.data;
      return Note.fromJson(
          responseData is Map<String, dynamic> ? responseData : responseData);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to update note',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    final response = await _apiService.delete(ApiEndpoints.note(id));

    if (response.statusCode == 200) {
      return;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to delete note',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Toggle pin status of a note
  Future<Note> togglePin(String id) async {
    final response = await _apiService.patch(ApiEndpoints.togglePin(id));

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return Note.fromJson(data is Map<String, dynamic> ? data : data);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to toggle pin',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get all unique tags for current user
  Future<List<String>> getTags() async {
    final response = await _apiService.get(ApiEndpoints.noteTags);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final tags = data['tags'] ?? data;
      return List<String>.from(tags ?? []);
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to fetch tags',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Search notes
  Future<PaginatedResponse<Note>> searchNotes({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.isEmpty) {
      return PaginatedResponse<Note>(
        data: [],
        pagination: PaginationInfo(page: page, limit: limit),
      );
    }

    final response = await _apiService.get(
      ApiEndpoints.noteSearch,
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return PaginatedResponse<Note>.fromJson(
        data,
        (json) => Note.fromJson(json),
      );
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to search notes',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get recent notes (helper method)
  Future<List<Note>> getRecentNotes({int limit = 5}) async {
    final result = await getNotes(page: 1, limit: limit, sortBy: 'updatedAt');
    return result.data;
  }

  /// Get pinned notes (helper method)
  Future<List<Note>> getPinnedNotes() async {
    final result = await getNotes(pinned: true, limit: 100);
    return result.data;
  }

  /// Duplicate a note
  Future<Note> duplicateNote(String id) async {
    final originalNote = await getNote(id);
    return createNote(
      title: '${originalNote.title} (Copy)',
      content: originalNote.content,
      tags: originalNote.tags,
      pinned: false,
    );
  }

  /// Batch delete notes
  Future<void> deleteNotes(List<String> ids) async {
    final futures = ids.map((id) => deleteNote(id));
    await Future.wait(futures);
  }

  /// Export note as text
  String exportAsText(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(', ')}');
      buffer.writeln();
    }
    buffer.writeln(note.content);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Created: ${note.createdAt.toIso8601String()}');
    buffer.writeln('Updated: ${note.updatedAt.toIso8601String()}');
    return buffer.toString();
  }
}
