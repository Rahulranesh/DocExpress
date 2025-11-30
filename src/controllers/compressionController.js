/**
 * Compression Controller - handles image, video, and PDF compression
 */

const imageService = require('../services/imageService');
const videoService = require('../services/videoService');
const pdfService = require('../services/pdfService');
const fileService = require('../services/fileService');
const jobService = require('../services/jobService');
const storageService = require('../services/storageService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');
const { JOB_TYPES, IMAGE_QUALITY, VIDEO_PRESETS } = require('../utils/constants');
const AppError = require('../utils/AppError');
const path = require('path');

/**
 * Compress image
 * POST /api/compress/image
 */
const compressImage = catchAsync(async (req, res) => {
  const { fileId, quality = IMAGE_QUALITY.MEDIUM, maxWidth, maxHeight, format } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Image file ID is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'image') {
    throw AppError.badRequest('File must be an image');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.COMPRESS_IMAGE,
      inputFileIds: [fileId],
      options: { quality, maxWidth, maxHeight, format },
    },
    async (job) => {
      const inputPath = fileService.getFullPath(file);

      const result = await imageService.compress(inputPath, {
        quality,
        maxWidth,
        maxHeight,
        format,
      });

      // Determine output format
      const outputFormat = format || path.extname(file.originalName).slice(1) || 'jpg';
      const mimeTypes = {
        jpeg: 'image/jpeg',
        jpg: 'image/jpeg',
        png: 'image/png',
        webp: 'image/webp',
      };

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `compressed_${path.basename(file.originalName, path.extname(file.originalName))}.${outputFormat}`,
          mimeType: mimeTypes[outputFormat] || 'image/jpeg',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  // Get compression stats from job
  const outputFile = job.outputFiles[0];

  successResponse(
    res,
    {
      job,
      compressionStats: {
        originalSize: file.size,
        quality,
      },
    },
    'Image compressed successfully',
    201
  );
});

/**
 * Compress multiple images
 * POST /api/compress/images
 */
const compressImages = catchAsync(async (req, res) => {
  const { fileIds, quality = IMAGE_QUALITY.MEDIUM, maxWidth, maxHeight, format } = req.body;

  if (!fileIds || fileIds.length === 0) {
    throw AppError.badRequest('At least one image file ID is required');
  }

  const files = await fileService.getFilesByIds(fileIds, req.userId);

  // Verify all files are images
  for (const file of files) {
    if (file.fileType !== 'image') {
      throw AppError.badRequest(`File ${file.originalName} is not an image`);
    }
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.COMPRESS_IMAGE,
      inputFileIds: fileIds,
      options: { quality, maxWidth, maxHeight, format, batch: true },
    },
    async (job) => {
      const outputFileIds = [];

      for (const file of files) {
        const inputPath = fileService.getFullPath(file);

        const result = await imageService.compress(inputPath, {
          quality,
          maxWidth,
          maxHeight,
          format,
        });

        const outputFormat = format || path.extname(file.originalName).slice(1) || 'jpg';
        const mimeTypes = {
          jpeg: 'image/jpeg',
          jpg: 'image/jpeg',
          png: 'image/png',
          webp: 'image/webp',
        };

        const outputFile = await fileService.createOutputFile(
          {
            filePath: result.path,
            originalName: `compressed_${file.originalName}`,
            mimeType: mimeTypes[outputFormat] || 'image/jpeg',
          },
          req.userId,
          job._id
        );

        outputFileIds.push(outputFile._id);
      }

      return outputFileIds;
    }
  );

  successResponse(
    res,
    { job, processedCount: files.length },
    'Images compressed successfully',
    201
  );
});

/**
 * Compress video with preset
 * POST /api/compress/video
 */
const compressVideo = catchAsync(async (req, res) => {
  const { fileId, preset = 'medium', resolution, customBitrate } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Video file ID is required');
  }

  // Validate preset
  const validPresets = ['low', 'medium', 'high'];
  if (preset && !validPresets.includes(preset.toLowerCase())) {
    throw AppError.badRequest(`Invalid preset. Valid options: ${validPresets.join(', ')}`);
  }

  // Validate resolution if provided
  const validResolutions = ['480p', '720p', '1080p'];
  if (resolution && !validResolutions.includes(resolution)) {
    throw AppError.badRequest(`Invalid resolution. Valid options: ${validResolutions.join(', ')}`);
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'video') {
    throw AppError.badRequest('File must be a video');
  }

  // Check if ffmpeg is available
  const ffmpegAvailable = await videoService.isAvailable();
  if (!ffmpegAvailable) {
    throw AppError.internal('Video compression is not available. FFmpeg is not installed.');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.COMPRESS_VIDEO,
      inputFileIds: [fileId],
      options: { preset, resolution, customBitrate },
    },
    async (job) => {
      const inputPath = fileService.getFullPath(file);

      const result = await videoService.compress(inputPath, {
        preset,
        resolution,
        customBitrate,
      });

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `compressed_${path.basename(file.originalName, path.extname(file.originalName))}.mp4`,
          mimeType: 'video/mp4',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(
    res,
    { job },
    'Video compressed successfully',
    201
  );
});

/**
 * Compress video to specific resolution
 * POST /api/compress/video/resolution
 */
const compressVideoToResolution = catchAsync(async (req, res) => {
  const { fileId, resolution } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Video file ID is required');
  }

  if (!resolution) {
    throw AppError.badRequest('Target resolution is required');
  }

  const validResolutions = ['480p', '720p', '1080p'];
  if (!validResolutions.includes(resolution)) {
    throw AppError.badRequest(`Invalid resolution. Valid options: ${validResolutions.join(', ')}`);
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'video') {
    throw AppError.badRequest('File must be a video');
  }

  const ffmpegAvailable = await videoService.isAvailable();
  if (!ffmpegAvailable) {
    throw AppError.internal('Video compression is not available. FFmpeg is not installed.');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.COMPRESS_VIDEO,
      inputFileIds: [fileId],
      options: { resolution },
    },
    async (job) => {
      const inputPath = fileService.getFullPath(file);

      const result = await videoService.compressToResolution(inputPath, resolution);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(file.originalName, path.extname(file.originalName))}_${resolution}.mp4`,
          mimeType: 'video/mp4',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(
    res,
    { job },
    `Video compressed to ${resolution} successfully`,
    201
  );
});

/**
 * Get video metadata/info
 * GET /api/compress/video/:id/info
 */
const getVideoInfo = catchAsync(async (req, res) => {
  const file = await fileService.getFileById(req.params.id, req.userId);

  if (file.fileType !== 'video') {
    throw AppError.badRequest('File must be a video');
  }

  const ffmpegAvailable = await videoService.isAvailable();
  if (!ffmpegAvailable) {
    throw AppError.internal('Video info is not available. FFmpeg is not installed.');
  }

  const inputPath = fileService.getFullPath(file);
  const metadata = await videoService.getMetadata(inputPath);

  successResponse(res, {
    file: {
      id: file._id,
      name: file.originalName,
      size: file.size,
    },
    metadata,
  });
});

/**
 * Compress PDF
 * POST /api/compress/pdf
 */
const compressPdf = catchAsync(async (req, res) => {
  const { fileId, quality = 'medium' } = req.body;

  if (!fileId) {
    throw AppError.badRequest('PDF file ID is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.COMPRESS_PDF,
      inputFileIds: [fileId],
      options: { quality },
    },
    async (job) => {
      const inputPath = fileService.getFullPath(file);
      const outputPath = storageService.getTempPath('.pdf');

      const result = await pdfService.compressPdf(inputPath, outputPath, { quality });

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `compressed_${file.originalName}`,
          mimeType: 'application/pdf',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(
    res,
    { job },
    'PDF compressed successfully',
    201
  );
});

/**
 * Get compression presets info
 * GET /api/compress/presets
 */
const getPresets = catchAsync(async (req, res) => {
  const presets = {
    image: {
      qualities: {
        low: IMAGE_QUALITY.LOW,
        medium: IMAGE_QUALITY.MEDIUM,
        high: IMAGE_QUALITY.HIGH,
        original: IMAGE_QUALITY.ORIGINAL,
      },
      formats: ['jpeg', 'png', 'webp'],
    },
    video: {
      presets: VIDEO_PRESETS,
      resolutions: ['480p', '720p', '1080p'],
    },
    pdf: {
      qualities: ['low', 'medium', 'high'],
    },
  };

  successResponse(res, { presets });
});

/**
 * Extract thumbnail from video
 * POST /api/compress/video/thumbnail
 */
const extractVideoThumbnail = catchAsync(async (req, res) => {
  const { fileId, timestamp = '00:00:01', width = 320, height = 240 } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Video file ID is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'video') {
    throw AppError.badRequest('File must be a video');
  }

  const ffmpegAvailable = await videoService.isAvailable();
  if (!ffmpegAvailable) {
    throw AppError.internal('Thumbnail extraction is not available. FFmpeg is not installed.');
  }

  const inputPath = fileService.getFullPath(file);
  const result = await videoService.extractThumbnail(inputPath, { timestamp, width, height });

  const outputFile = await fileService.createOutputFile(
    {
      filePath: result.path,
      originalName: `thumbnail_${path.basename(file.originalName, path.extname(file.originalName))}.jpg`,
      mimeType: 'image/jpeg',
    },
    req.userId,
    null
  );

  successResponse(res, { file: outputFile }, 'Thumbnail extracted successfully', 201);
});

/**
 * Extract audio from video
 * POST /api/compress/video/extract-audio
 */
const extractVideoAudio = catchAsync(async (req, res) => {
  const { fileId, format = 'mp3', bitrate = '192k' } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Video file ID is required');
  }

  const validFormats = ['mp3', 'aac', 'wav'];
  if (!validFormats.includes(format)) {
    throw AppError.badRequest(`Invalid audio format. Valid options: ${validFormats.join(', ')}`);
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'video') {
    throw AppError.badRequest('File must be a video');
  }

  const ffmpegAvailable = await videoService.isAvailable();
  if (!ffmpegAvailable) {
    throw AppError.internal('Audio extraction is not available. FFmpeg is not installed.');
  }

  const inputPath = fileService.getFullPath(file);
  const result = await videoService.extractAudio(inputPath, { format, bitrate });

  const mimeTypes = {
    mp3: 'audio/mpeg',
    aac: 'audio/aac',
    wav: 'audio/wav',
  };

  const outputFile = await fileService.createOutputFile(
    {
      filePath: result.path,
      originalName: `${path.basename(file.originalName, path.extname(file.originalName))}.${format}`,
      mimeType: mimeTypes[format],
    },
    req.userId,
    null
  );

  successResponse(res, { file: outputFile }, 'Audio extracted successfully', 201);
});

module.exports = {
  compressImage,
  compressImages,
  compressVideo,
  compressVideoToResolution,
  getVideoInfo,
  compressPdf,
  getPresets,
  extractVideoThumbnail,
  extractVideoAudio,
};
