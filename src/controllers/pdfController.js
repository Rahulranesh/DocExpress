/**
 * PDF Controller - handles PDF manipulation operations
 */

const pdfService = require('../services/pdfService');
const fileService = require('../services/fileService');
const jobService = require('../services/jobService');
const storageService = require('../services/storageService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');
const { JOB_TYPES } = require('../utils/constants');
const AppError = require('../utils/AppError');
const path = require('path');
const fs = require('fs').promises;

/**
 * Merge multiple PDFs
 * POST /api/pdf/merge
 */
const mergePdfs = catchAsync(async (req, res) => {
  const { fileIds } = req.body;

  if (!fileIds || fileIds.length < 2) {
    throw AppError.badRequest('At least 2 PDF files required for merge');
  }

  // Verify files exist and belong to user
  const files = await fileService.getFilesByIds(fileIds, req.userId);

  // Verify all files are PDFs
  for (const file of files) {
    if (file.fileType !== 'pdf') {
      throw AppError.badRequest(`File ${file.originalName} is not a PDF`);
    }
  }

  // Execute job
  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_MERGE,
      inputFileIds: fileIds,
      options: { fileCount: files.length },
    },
    async () => {
      const inputPaths = files.map((f) => fileService.getFullPath(f));
      const outputPath = storageService.getTempPath('.pdf');

      const result = await pdfService.mergePdfs(inputPaths, outputPath);

      // Create output file record
      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: 'merged.pdf',
          mimeType: 'application/pdf',
        },
        req.userId,
        null
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PDFs merged successfully', 201);
});

/**
 * Split PDF by page ranges
 * POST /api/pdf/split
 */
const splitPdf = catchAsync(async (req, res) => {
  const { fileId, ranges } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  if (!ranges || !Array.isArray(ranges) || ranges.length === 0) {
    throw AppError.badRequest('At least one page range required');
  }

  // Verify file exists and belongs to user
  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  // Execute job
  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_SPLIT,
      inputFileIds: [fileId],
      options: { ranges },
    },
    async () => {
      const inputPath = fileService.getFullPath(file);
      const outputDir = path.dirname(storageService.getTempPath('.pdf'));

      // Ensure output directory exists
      await fs.mkdir(outputDir, { recursive: true });

      const results = await pdfService.splitPdf(inputPath, ranges, outputDir);

      // Create output file records
      const outputFileIds = [];
      for (const result of results) {
        const outputFile = await fileService.createOutputFile(
          {
            filePath: result.path,
            originalName: `split_${result.range}.pdf`,
            mimeType: 'application/pdf',
          },
          req.userId,
          null
        );
        outputFileIds.push(outputFile._id);
      }

      return outputFileIds;
    }
  );

  successResponse(res, { job }, 'PDF split successfully', 201);
});

/**
 * Reorder PDF pages
 * POST /api/pdf/reorder
 */
const reorderPages = catchAsync(async (req, res) => {
  const { fileId, pageOrder } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  if (!pageOrder || !Array.isArray(pageOrder) || pageOrder.length === 0) {
    throw AppError.badRequest('Page order array is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_REORDER,
      inputFileIds: [fileId],
      options: { pageOrder },
    },
    async () => {
      const inputPath = fileService.getFullPath(file);
      const outputPath = storageService.getTempPath('.pdf');

      await pdfService.reorderPages(inputPath, pageOrder, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: `reordered_${file.originalName}`,
          mimeType: 'application/pdf',
        },
        req.userId,
        null
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PDF pages reordered successfully', 201);
});

/**
 * Extract text from PDF
 * POST /api/pdf/extract-text
 */
const extractText = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_EXTRACT_TEXT,
      inputFileIds: [fileId],
      options: {},
    },
    async () => {
      const inputPath = fileService.getFullPath(file);
      const outputPath = storageService.getTempPath('.txt');

      const result = await pdfService.extractText(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(file.originalName, '.pdf')}.txt`,
          mimeType: 'text/plain',
        },
        req.userId,
        null
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Text extracted successfully', 201);
});

/**
 * Extract images from PDF
 * POST /api/pdf/extract-images
 */
const extractImages = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_EXTRACT_IMAGES,
      inputFileIds: [fileId],
      options: {},
    },
    async () => {
      const inputPath = fileService.getFullPath(file);
      const outputDir = path.dirname(storageService.getTempPath('.png'));

      await fs.mkdir(outputDir, { recursive: true });

      const results = await pdfService.extractImages(inputPath, outputDir);

      const outputFileIds = [];
      for (const result of results) {
        const outputFile = await fileService.createOutputFile(
          {
            filePath: result.path,
            originalName: `page_${result.page}.png`,
            mimeType: 'image/png',
          },
          req.userId,
          null
        );
        outputFileIds.push(outputFile._id);
      }

      return outputFileIds;
    }
  );

  successResponse(res, { job }, 'Images extracted successfully', 201);
});

/**
 * Compress PDF
 * POST /api/pdf/compress
 */
const compressPdf = catchAsync(async (req, res) => {
  const { fileId, quality = 'medium' } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
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
    async () => {
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
        null
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
 * Get PDF info/metadata
 * GET /api/pdf/:id/info
 */
const getPdfInfo = catchAsync(async (req, res) => {
  const file = await fileService.getFileById(req.params.id, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const inputPath = fileService.getFullPath(file);
  const info = await pdfService.getPdfInfo(inputPath);

  successResponse(res, { info });
});

/**
 * Add watermark to PDF
 * POST /api/pdf/watermark
 */
const addWatermark = catchAsync(async (req, res) => {
  const { fileId, text, opacity = 0.3, fontSize = 50 } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  if (!text) {
    throw AppError.badRequest('Watermark text is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const inputPath = fileService.getFullPath(file);
  const outputPath = storageService.getTempPath('.pdf');

  await pdfService.addWatermark(inputPath, text, outputPath, { opacity, fontSize });

  const outputFile = await fileService.createOutputFile(
    {
      filePath: outputPath,
      originalName: `watermarked_${file.originalName}`,
      mimeType: 'application/pdf',
    },
    req.userId,
    null
  );

  successResponse(res, { file: outputFile }, 'Watermark added successfully', 201);
});

/**
 * Remove pages from PDF
 * POST /api/pdf/remove-pages
 */
const removePages = catchAsync(async (req, res) => {
  const { fileId, pages } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  if (!pages || !Array.isArray(pages) || pages.length === 0) {
    throw AppError.badRequest('Pages to remove array is required');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const inputPath = fileService.getFullPath(file);
  const outputPath = storageService.getTempPath('.pdf');

  const result = await pdfService.removePages(inputPath, pages, outputPath);

  const outputFile = await fileService.createOutputFile(
    {
      filePath: result.path,
      originalName: `modified_${file.originalName}`,
      mimeType: 'application/pdf',
    },
    req.userId,
    null
  );

  successResponse(res, { file: outputFile, removedPages: result.removedPages }, 'Pages removed successfully', 201);
});

/**
 * Rotate pages in PDF
 * POST /api/pdf/rotate-pages
 */
const rotatePages = catchAsync(async (req, res) => {
  const { fileId, rotations } = req.body;

  if (!fileId) {
    throw AppError.badRequest('File ID is required');
  }

  if (!rotations || typeof rotations !== 'object') {
    throw AppError.badRequest('Rotations object is required (pageNumber: degrees)');
  }

  const file = await fileService.getFileById(fileId, req.userId);

  if (file.fileType !== 'pdf') {
    throw AppError.badRequest('File must be a PDF');
  }

  const inputPath = fileService.getFullPath(file);
  const outputPath = storageService.getTempPath('.pdf');

  await pdfService.rotatePages(inputPath, rotations, outputPath);

  const outputFile = await fileService.createOutputFile(
    {
      filePath: outputPath,
      originalName: `rotated_${file.originalName}`,
      mimeType: 'application/pdf',
    },
    req.userId,
    null
  );

  successResponse(res, { file: outputFile }, 'Pages rotated successfully', 201);
});

module.exports = {
  mergePdfs,
  splitPdf,
  reorderPages,
  extractText,
  extractImages,
  compressPdf,
  getPdfInfo,
  addWatermark,
  removePages,
  rotatePages,
};
