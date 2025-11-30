/**
 * Storage Service Abstraction
 * Provides file system operations that can be swapped to cloud storage later
 */

const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const { v4: uuidv4 } = require('uuid');
const { getFileTypeFromMime } = require('../utils/constants');

const mkdir = promisify(fs.mkdir);
const unlink = promisify(fs.unlink);
const stat = promisify(fs.stat);
const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);
const copyFile = promisify(fs.copyFile);
const readdir = promisify(fs.readdir);
const rename = promisify(fs.rename);
const access = promisify(fs.access);

class StorageService {
  constructor() {
    this.storageRoot = process.env.STORAGE_ROOT || './uploads';
    this.ensureRootExists();
  }

  // Ensure storage root directory exists
  ensureRootExists() {
    if (!fs.existsSync(this.storageRoot)) {
      fs.mkdirSync(this.storageRoot, { recursive: true });
    }
  }

  // Get full path from storage key
  getFullPath(storageKey) {
    // Security: prevent directory traversal
    const normalizedKey = path.normalize(storageKey).replace(/^(\.\.(\/|\\|$))+/, '');
    return path.join(this.storageRoot, normalizedKey);
  }

  // Generate unique storage key
  generateStorageKey(originalName, mimeType) {
    const ext = path.extname(originalName).toLowerCase();
    const fileType = getFileTypeFromMime(mimeType);
    const uniqueId = uuidv4();
    const timestamp = Date.now();
    const filename = `${timestamp}-${uniqueId}${ext}`;
    return path.join(fileType, filename);
  }

  // Ensure directory for storage key exists
  async ensureDirectory(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    const dir = path.dirname(fullPath);
    await mkdir(dir, { recursive: true });
    return dir;
  }

  /**
   * Save file from buffer
   * @param {Buffer} buffer - File content
   * @param {string} storageKey - Storage key/path
   * @returns {Promise<{storageKey: string, path: string, size: number}>}
   */
  async saveBuffer(buffer, storageKey) {
    await this.ensureDirectory(storageKey);
    const fullPath = this.getFullPath(storageKey);
    await writeFile(fullPath, buffer);

    const stats = await stat(fullPath);
    return {
      storageKey,
      path: fullPath,
      size: stats.size,
    };
  }

  /**
   * Save file from stream
   * @param {ReadStream} stream - File stream
   * @param {string} storageKey - Storage key/path
   * @returns {Promise<{storageKey: string, path: string, size: number}>}
   */
  async saveStream(stream, storageKey) {
    await this.ensureDirectory(storageKey);
    const fullPath = this.getFullPath(storageKey);

    return new Promise((resolve, reject) => {
      const writeStream = fs.createWriteStream(fullPath);

      stream.pipe(writeStream);

      writeStream.on('finish', async () => {
        try {
          const stats = await stat(fullPath);
          resolve({
            storageKey,
            path: fullPath,
            size: stats.size,
          });
        } catch (err) {
          reject(err);
        }
      });

      writeStream.on('error', reject);
      stream.on('error', reject);
    });
  }

  /**
   * Copy existing file to storage
   * @param {string} sourcePath - Source file path
   * @param {string} storageKey - Destination storage key
   * @returns {Promise<{storageKey: string, path: string, size: number}>}
   */
  async copyToStorage(sourcePath, storageKey) {
    await this.ensureDirectory(storageKey);
    const fullPath = this.getFullPath(storageKey);
    await copyFile(sourcePath, fullPath);

    const stats = await stat(fullPath);
    return {
      storageKey,
      path: fullPath,
      size: stats.size,
    };
  }

  /**
   * Move file to storage (useful after multer upload)
   * @param {string} sourcePath - Source file path
   * @param {string} storageKey - Destination storage key
   * @returns {Promise<{storageKey: string, path: string, size: number}>}
   */
  async moveToStorage(sourcePath, storageKey) {
    await this.ensureDirectory(storageKey);
    const fullPath = this.getFullPath(storageKey);

    try {
      // Try rename (fast, same filesystem)
      await rename(sourcePath, fullPath);
    } catch (err) {
      // Fall back to copy + delete (cross-filesystem)
      await copyFile(sourcePath, fullPath);
      await unlink(sourcePath);
    }

    const stats = await stat(fullPath);
    return {
      storageKey,
      path: fullPath,
      size: stats.size,
    };
  }

  /**
   * Read file content
   * @param {string} storageKey - Storage key
   * @returns {Promise<Buffer>}
   */
  async readFile(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    return readFile(fullPath);
  }

  /**
   * Get read stream for file
   * @param {string} storageKey - Storage key
   * @returns {ReadStream}
   */
  getReadStream(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    return fs.createReadStream(fullPath);
  }

  /**
   * Get file stats
   * @param {string} storageKey - Storage key
   * @returns {Promise<fs.Stats>}
   */
  async getStats(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    return stat(fullPath);
  }

  /**
   * Check if file exists
   * @param {string} storageKey - Storage key
   * @returns {Promise<boolean>}
   */
  async exists(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    try {
      await access(fullPath, fs.constants.F_OK);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Delete file
   * @param {string} storageKey - Storage key
   * @returns {Promise<boolean>}
   */
  async delete(storageKey) {
    const fullPath = this.getFullPath(storageKey);
    try {
      await unlink(fullPath);
      return true;
    } catch (err) {
      if (err.code === 'ENOENT') return false;
      throw err;
    }
  }

  /**
   * Delete multiple files
   * @param {string[]} storageKeys - Array of storage keys
   * @returns {Promise<{deleted: number, failed: number}>}
   */
  async deleteMany(storageKeys) {
    const results = await Promise.allSettled(storageKeys.map((key) => this.delete(key)));

    return {
      deleted: results.filter((r) => r.status === 'fulfilled' && r.value).length,
      failed: results.filter((r) => r.status === 'rejected' || !r.value).length,
    };
  }

  /**
   * List files in a directory
   * @param {string} dirKey - Directory storage key
   * @returns {Promise<string[]>}
   */
  async listDirectory(dirKey = '') {
    const fullPath = this.getFullPath(dirKey);
    try {
      const entries = await readdir(fullPath, { withFileTypes: true });
      return entries.map((entry) => ({
        name: entry.name,
        isDirectory: entry.isDirectory(),
        key: path.join(dirKey, entry.name),
      }));
    } catch (err) {
      if (err.code === 'ENOENT') return [];
      throw err;
    }
  }

  /**
   * Get temporary file path for processing
   * @param {string} extension - File extension
   * @returns {string}
   */
  getTempPath(extension = '') {
    const tempDir = path.join(this.storageRoot, 'temp');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }
    const filename = `temp-${Date.now()}-${uuidv4()}${extension}`;
    return path.join(tempDir, filename);
  }

  /**
   * Clean up temporary files older than given age
   * @param {number} maxAgeMs - Max age in milliseconds
   * @returns {Promise<number>} - Number of files deleted
   */
  async cleanupTemp(maxAgeMs = 24 * 60 * 60 * 1000) {
    const tempDir = path.join(this.storageRoot, 'temp');
    if (!fs.existsSync(tempDir)) return 0;

    const entries = await readdir(tempDir);
    const now = Date.now();
    let deleted = 0;

    for (const entry of entries) {
      const filePath = path.join(tempDir, entry);
      try {
        const stats = await stat(filePath);
        if (now - stats.mtimeMs > maxAgeMs) {
          await unlink(filePath);
          deleted++;
        }
      } catch (err) {
        // Ignore errors for individual files
      }
    }

    return deleted;
  }

  /**
   * Get URL for file (for local storage, returns path; cloud would return signed URL)
   * @param {string} storageKey - Storage key
   * @returns {string}
   */
  getUrl(storageKey) {
    // For local storage, return a relative path
    // Cloud implementation would return a signed URL
    return `/api/files/download/${encodeURIComponent(storageKey)}`;
  }

  /**
   * Get storage info
   * @returns {Promise<{type: string, root: string}>}
   */
  async getInfo() {
    return {
      type: 'local',
      root: this.storageRoot,
    };
  }
}

// Export singleton instance
const storageService = new StorageService();

module.exports = storageService;
