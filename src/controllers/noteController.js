/**
 * Notes Controller
 * Handles note CRUD operations
 */

const noteService = require('../services/noteService');
const { successResponse, paginatedResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * Create a new note
 * POST /api/notes
 */
const createNote = catchAsync(async (req, res) => {
  const note = await noteService.createNote(req.userId, req.body);
  successResponse(res, note, 'Note created successfully', 201);
});

/**
 * Get all notes for current user
 * GET /api/notes
 */
const getNotes = catchAsync(async (req, res) => {
  const { page, limit, pinned, tag, search, sortBy, sortOrder } = req.query;

  const options = {
    page: parseInt(page, 10) || 1,
    limit: parseInt(limit, 10) || 20,
    sortBy: sortBy || 'createdAt',
    sortOrder: sortOrder === 'asc' ? 1 : -1,
  };

  // Handle boolean pinned filter
  if (pinned !== undefined) {
    options.pinned = pinned === 'true';
  }

  if (tag) options.tag = tag;
  if (search) options.search = search;

  const { notes, pagination } = await noteService.getNotesByUser(req.userId, options);
  paginatedResponse(res, notes, pagination);
});

/**
 * Get a single note by ID
 * GET /api/notes/:id
 */
const getNote = catchAsync(async (req, res) => {
  const note = await noteService.getNoteById(req.params.id, req.userId);
  successResponse(res, note);
});

/**
 * Update a note
 * PUT /api/notes/:id
 */
const updateNote = catchAsync(async (req, res) => {
  const note = await noteService.updateNote(req.params.id, req.userId, req.body);
  successResponse(res, note, 'Note updated successfully');
});

/**
 * Delete a note
 * DELETE /api/notes/:id
 */
const deleteNote = catchAsync(async (req, res) => {
  await noteService.deleteNote(req.params.id, req.userId);
  successResponse(res, null, 'Note deleted successfully');
});

/**
 * Toggle note pin status
 * PATCH /api/notes/:id/pin
 */
const togglePin = catchAsync(async (req, res) => {
  const note = await noteService.togglePin(req.params.id, req.userId);
  successResponse(res, note, `Note ${note.pinned ? 'pinned' : 'unpinned'}`);
});

/**
 * Get all unique tags for current user
 * GET /api/notes/tags
 */
const getTags = catchAsync(async (req, res) => {
  const tags = await noteService.getUserTags(req.userId);
  successResponse(res, { tags });
});

/**
 * Search notes
 * GET /api/notes/search
 */
const searchNotes = catchAsync(async (req, res) => {
  const { q, page, limit } = req.query;

  if (!q || q.trim().length === 0) {
    return successResponse(res, { notes: [], pagination: { page: 1, limit: 20, total: 0 } });
  }

  const options = {
    page: parseInt(page, 10) || 1,
    limit: parseInt(limit, 10) || 20,
  };

  const { notes, pagination } = await noteService.searchNotes(req.userId, q, options);
  paginatedResponse(res, notes, pagination);
});

module.exports = {
  createNote,
  getNotes,
  getNote,
  updateNote,
  deleteNote,
  togglePin,
  getTags,
  searchNotes,
};
