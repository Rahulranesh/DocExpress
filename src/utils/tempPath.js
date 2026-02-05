/**
 * Simple temp path generator
 * Replaces the storageService for simple conversions
 */

const path = require('path');
const { v4: uuidv4 } = require('uuid');

/**
 * Get a temporary file path
 * @param {string} extension - File extension (e.g., '.pdf', '.docx')
 * @returns {string} - Full path to temp file
 */
function getTempPath(extension) {
  const tempDir = 'uploads/temp';
  const filename = `temp-${Date.now()}-${uuidv4()}${extension}`;
  return path.join(tempDir, filename);
}

module.exports = { getTempPath };
