/**
 * Notes Routes
 */

const express = require('express');
const router = express.Router();
const noteController = require('../controllers/noteController');
const { authenticate } = require('../middleware/auth');
const { validateCreateNote, validateUpdateNote, validateMongoId, validatePagination } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

// Get user's tags (must be before /:id to avoid conflict)
router.get('/tags', noteController.getTags);

// Search notes
router.get('/search', noteController.searchNotes);

// CRUD operations
router.route('/')
  .get(validatePagination, noteController.getNotes)
  .post(validateCreateNote, noteController.createNote);

router.route('/:id')
  .get(validateMongoId('id'), noteController.getNote)
  .put(validateUpdateNote, noteController.updateNote)
  .delete(validateMongoId('id'), noteController.deleteNote);

// Toggle pin status
router.patch('/:id/pin', validateMongoId('id'), noteController.togglePin);

module.exports = router;
