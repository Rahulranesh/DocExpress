const mongoose = require('mongoose');
const { FILE_TYPES } = require('../utils/constants');

const fileSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    originalName: {
      type: String,
      required: true,
      trim: true,
    },
    filename: {
      type: String,
      required: true,
      unique: true,
    },
    mimeType: {
      type: String,
      required: true,
    },
    size: {
      type: Number,
      required: true,
      min: 0,
    },
    storagePath: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
      unique: true,
    },
    fileType: {
      type: String,
      enum: Object.values(FILE_TYPES),
      required: true,
      index: true,
    },
    extension: {
      type: String,
      lowercase: true,
    },
    // For images: width, height
    metadata: {
      width: Number,
      height: Number,
      duration: Number, // For videos (in seconds)
      pages: Number, // For PDFs/documents
    },
    // Soft delete support
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
    // Reference to job that created this file (if output)
    sourceJob: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Compound indexes for common queries
fileSchema.index({ owner: 1, createdAt: -1 });
fileSchema.index({ owner: 1, fileType: 1 });
fileSchema.index({ owner: 1, isDeleted: 1 });

// Virtual for formatted file size
fileSchema.virtual('formattedSize').get(function () {
  const bytes = this.size;
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
});

// Instance method: soft delete
fileSchema.methods.softDelete = async function () {
  this.isDeleted = true;
  this.deletedAt = new Date();
  return this.save();
};

// Static method: find active files for user
fileSchema.statics.findActiveByUser = function (userId, options = {}) {
  const query = this.find({ owner: userId, isDeleted: false });

  if (options.fileType) {
    query.where('fileType').equals(options.fileType);
  }

  if (options.sort) {
    query.sort(options.sort);
  } else {
    query.sort({ createdAt: -1 });
  }

  if (options.limit) {
    query.limit(options.limit);
  }

  if (options.skip) {
    query.skip(options.skip);
  }

  return query;
};

// Pre-save hook: extract extension from originalName
fileSchema.pre('save', function (next) {
  if (this.isModified('originalName') && this.originalName) {
    const parts = this.originalName.split('.');
    if (parts.length > 1) {
      this.extension = parts.pop().toLowerCase();
    }
  }
  next();
});

const File = mongoose.model('File', fileSchema);

module.exports = File;
