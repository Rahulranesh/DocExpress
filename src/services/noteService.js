const Note = require('../models/Note');
const AppError = require('../utils/AppError');
const { PAGINATION } = require('../utils/constants');

/**
 * Create a new note
 */
const createNote = async (userId, data) => {
  const note = await Note.create({
    user: userId,
    title: data.title,
    content: data.content || '',
    tags: data.tags || [],
    pinned: data.pinned || false,
  });

  return note;
};

/**
 * Get all notes for a user with pagination and filters
 */
const getNotesByUser = async (userId, options = {}) => {
  const {
    page = PAGINATION.DEFAULT_PAGE,
    limit = PAGINATION.DEFAULT_LIMIT,
    pinned,
    tag,
    search,
    sortBy = 'createdAt',
    sortOrder = -1,
  } = options;

  const query = { user: userId };

  // Filter by pinned status
  if (typeof pinned === 'boolean') {
    query.pinned = pinned;
  }

  // Filter by tag
  if (tag) {
    query.tags = tag;
  }

  // Text search
  if (search) {
    query.$text = { $search: search };
  }

  const skip = (page - 1) * Math.min(limit, PAGINATION.MAX_LIMIT);
  const actualLimit = Math.min(limit, PAGINATION.MAX_LIMIT);

  const [notes, total] = await Promise.all([
    Note.find(query)
      .sort({ pinned: -1, [sortBy]: sortOrder })
      .skip(skip)
      .limit(actualLimit)
      .lean(),
    Note.countDocuments(query),
  ]);

  return {
    notes,
    pagination: {
      page,
      limit: actualLimit,
      total,
    },
  };
};

/**
 * Get a single note by ID
 */
const getNoteById = async (noteId, userId) => {
  const note = await Note.findOne({ _id: noteId, user: userId });

  if (!note) {
    throw AppError.notFound('Note not found');
  }

  return note;
};

/**
 * Update a note
 */
const updateNote = async (noteId, userId, updates) => {
  const allowedUpdates = ['title', 'content', 'tags', 'pinned'];
  const updateData = {};

  // Filter only allowed fields
  for (const key of allowedUpdates) {
    if (updates[key] !== undefined) {
      updateData[key] = updates[key];
    }
  }

  const note = await Note.findOneAndUpdate(
    { _id: noteId, user: userId },
    { $set: updateData },
    { new: true, runValidators: true }
  );

  if (!note) {
    throw AppError.notFound('Note not found');
  }

  return note;
};

/**
 * Delete a note
 */
const deleteNote = async (noteId, userId) => {
  const note = await Note.findOneAndDelete({ _id: noteId, user: userId });

  if (!note) {
    throw AppError.notFound('Note not found');
  }

  return note;
};

/**
 * Toggle pin status
 */
const togglePin = async (noteId, userId) => {
  const note = await Note.findOne({ _id: noteId, user: userId });

  if (!note) {
    throw AppError.notFound('Note not found');
  }

  note.pinned = !note.pinned;
  await note.save();

  return note;
};

/**
 * Get all unique tags for a user
 */
const getUserTags = async (userId) => {
  const tags = await Note.distinct('tags', { user: userId });
  return tags.sort();
};

/**
 * Search notes by text
 */
const searchNotes = async (userId, searchTerm, options = {}) => {
  const { page = 1, limit = 20 } = options;
  const skip = (page - 1) * limit;

  const query = {
    user: userId,
    $text: { $search: searchTerm },
  };

  const [notes, total] = await Promise.all([
    Note.find(query, { score: { $meta: 'textScore' } })
      .sort({ score: { $meta: 'textScore' } })
      .skip(skip)
      .limit(limit)
      .lean(),
    Note.countDocuments(query),
  ]);

  return {
    notes,
    pagination: { page, limit, total },
  };
};

/**
 * Admin: Get all notes (read-only)
 */
const getAllNotes = async (options = {}) => {
  const { page = 1, limit = 20, userId } = options;
  const skip = (page - 1) * limit;

  const query = userId ? { user: userId } : {};

  const [notes, total] = await Promise.all([
    Note.find(query)
      .populate('user', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Note.countDocuments(query),
  ]);

  return {
    notes,
    pagination: { page, limit, total },
  };
};

module.exports = {
  createNote,
  getNotesByUser,
  getNoteById,
  updateNote,
  deleteNote,
  togglePin,
  getUserTags,
  searchNotes,
  getAllNotes,
};
