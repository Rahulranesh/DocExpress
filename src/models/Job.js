const mongoose = require('mongoose');
const { JOB_TYPES, JOB_STATUS } = require('../utils/constants');

const jobSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      enum: Object.values(JOB_TYPES),
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(JOB_STATUS),
      default: JOB_STATUS.PENDING,
      index: true,
    },
    inputFiles: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'File',
      },
    ],
    outputFiles: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'File',
      },
    ],
    options: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    errorMessage: {
      type: String,
      default: null,
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for common queries
jobSchema.index({ userId: 1, createdAt: -1 });
jobSchema.index({ userId: 1, status: 1 });
jobSchema.index({ userId: 1, type: 1 });

// Mark job as running
jobSchema.methods.markRunning = async function () {
  this.status = JOB_STATUS.RUNNING;
  return this.save();
};

// Mark job as completed
jobSchema.methods.markCompleted = async function (outputFileIds = []) {
  this.status = JOB_STATUS.COMPLETED;
  this.outputFiles = outputFileIds;
  this.completedAt = new Date();
  return this.save();
};

// Mark job as failed
jobSchema.methods.markFailed = async function (errorMessage) {
  this.status = JOB_STATUS.FAILED;
  this.errorMessage = errorMessage;
  this.completedAt = new Date();
  return this.save();
};

// Static method to find jobs by user with pagination
jobSchema.statics.findByUser = async function (userId, options = {}) {
  const { page = 1, limit = 20, type, status, sortBy = 'createdAt', sortOrder = -1 } = options;

  const query = { userId };
  if (type) query.type = type;
  if (status) query.status = status;

  const skip = (page - 1) * limit;

  const [jobs, total] = await Promise.all([
    this.find(query)
      .sort({ [sortBy]: sortOrder })
      .skip(skip)
      .limit(limit)
      .populate('inputFiles', 'originalName mimeType size')
      .populate('outputFiles', 'originalName mimeType size storagePath'),
    this.countDocuments(query),
  ]);

  return { jobs, total, page, limit };
};

// Virtual for duration calculation
jobSchema.virtual('duration').get(function () {
  if (!this.completedAt) return null;
  return this.completedAt.getTime() - this.createdAt.getTime();
});

// Ensure virtuals are serialized
jobSchema.set('toJSON', { virtuals: true });
jobSchema.set('toObject', { virtuals: true });

const Job = mongoose.model('Job', jobSchema);

module.exports = Job;
