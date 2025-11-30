/**
 * Conversion Controller - handles image and document conversions
 */

const imageService = require('../services/imageService');
const pdfService = require('../services/pdfService');
const documentService = require('../services/documentService');
const fileService = require('../services/fileService');
const jobService = require('../services/jobService');
const storageService = require('../services/storageService');
const { catchAsync } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');
const { JOB_TYPES, getFileTypeFromMime } = require('../utils/constants');
const AppError = require('../utils/AppError');
const path = require('path');

/**
 * Convert images to PDF
 * POST /api/convert/images-to-pdf
 */
const imagesToPdf = catchAsync(async (req, res) => {
  const { fileIds, pageSize = 'A4' } = req.body;

  if (!fileIds || fileIds.length === 0) {
    throw AppError.badRequest('At least one image file is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_TO_PDF,
      inputFileIds: fileIds,
      options: { pageSize },
    },
    async (job) => {
      // Get input files
      const inputFiles = await fileService.getFilesByIds(fileIds, req.userId);

      // Validate all are images
      for (const file of inputFiles) {
        if (file.fileType !== 'image') {
          throw AppError.badRequest(`File ${file.originalName} is not an image`);
        }
      }

      const inputPaths = inputFiles.map((f) => fileService.getFullPath(f));

      // Convert images to PDF
      const outputPath = await imageService.imagesToPdf(inputPaths, { pageSize });

      // Create output file record
      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: 'converted.pdf',
          mimeType: 'application/pdf',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Images converted to PDF successfully');
});

/**
 * Convert images to PPTX
 * POST /api/convert/images-to-pptx
 */
const imagesToPptx = catchAsync(async (req, res) => {
  const { fileIds } = req.body;

  if (!fileIds || fileIds.length === 0) {
    throw AppError.badRequest('At least one image file is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_TO_PPTX,
      inputFileIds: fileIds,
      options: {},
    },
    async (job) => {
      const inputFiles = await fileService.getFilesByIds(fileIds, req.userId);

      for (const file of inputFiles) {
        if (file.fileType !== 'image') {
          throw AppError.badRequest(`File ${file.originalName} is not an image`);
        }
      }

      const inputPaths = inputFiles.map((f) => fileService.getFullPath(f));
      const outputPath = await imageService.imagesToPptx(inputPaths);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: 'presentation.pptx',
          mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Images converted to PPTX successfully');
});

/**
 * Convert images to DOCX
 * POST /api/convert/images-to-docx
 */
const imagesToDocx = catchAsync(async (req, res) => {
  const { fileIds, title = 'Image Document' } = req.body;

  if (!fileIds || fileIds.length === 0) {
    throw AppError.badRequest('At least one image file is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_TO_DOCX,
      inputFileIds: fileIds,
      options: { title },
    },
    async (job) => {
      const inputFiles = await fileService.getFilesByIds(fileIds, req.userId);

      for (const file of inputFiles) {
        if (file.fileType !== 'image') {
          throw AppError.badRequest(`File ${file.originalName} is not an image`);
        }
      }

      const inputPaths = inputFiles.map((f) => fileService.getFullPath(f));
      const outputPath = await imageService.imagesToDocx(inputPaths, { title });

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: 'document.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Images converted to DOCX successfully');
});

/**
 * Convert image to text (OCR)
 * POST /api/convert/image-to-text
 */
const imageToText = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('Image file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_TO_TXT,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'image') {
        throw AppError.badRequest('File must be an image');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const result = await imageService.imageToText(inputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, path.extname(inputFile.originalName))}.txt`,
          mimeType: 'text/plain',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Image converted to text successfully');
});

/**
 * Convert image format
 * POST /api/convert/image-format
 */
const convertImageFormat = catchAsync(async (req, res) => {
  const { fileId, targetFormat, quality = 80 } = req.body;

  if (!fileId || !targetFormat) {
    throw AppError.badRequest('File ID and target format are required');
  }

  const validFormats = ['jpeg', 'jpg', 'png', 'webp', 'tiff', 'gif'];
  if (!validFormats.includes(targetFormat.toLowerCase())) {
    throw AppError.badRequest(`Invalid target format. Supported: ${validFormats.join(', ')}`);
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_FORMAT_CONVERT,
      inputFileIds: [fileId],
      options: { targetFormat, quality },
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'image') {
        throw AppError.badRequest('File must be an image');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = await imageService.convertFormat(inputPath, targetFormat, { quality });

      const mimeTypes = {
        jpeg: 'image/jpeg',
        jpg: 'image/jpeg',
        png: 'image/png',
        webp: 'image/webp',
        tiff: 'image/tiff',
        gif: 'image/gif',
      };

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: `${path.basename(inputFile.originalName, path.extname(inputFile.originalName))}.${targetFormat}`,
          mimeType: mimeTypes[targetFormat.toLowerCase()],
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Image format converted successfully');
});

/**
 * Apply image transforms
 * POST /api/convert/image-transform
 */
const transformImage = catchAsync(async (req, res) => {
  const { fileId, operations, format = 'jpeg', quality = 80 } = req.body;

  if (!fileId || !operations || operations.length === 0) {
    throw AppError.badRequest('File ID and operations array are required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_TRANSFORM,
      inputFileIds: [fileId],
      options: { operations, format, quality },
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'image') {
        throw AppError.badRequest('File must be an image');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = await imageService.applyTransforms(inputPath, operations, { format, quality });

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: `transformed_${inputFile.originalName}`,
          mimeType: `image/${format}`,
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Image transformed successfully');
});

/**
 * Merge images
 * POST /api/convert/merge-images
 */
const mergeImages = catchAsync(async (req, res) => {
  const { fileIds, direction = 'vertical', format = 'jpeg', quality = 80, gap = 0 } = req.body;

  if (!fileIds || fileIds.length < 2) {
    throw AppError.badRequest('At least two images are required for merge');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.IMAGE_MERGE,
      inputFileIds: fileIds,
      options: { direction, format, quality, gap },
    },
    async (job) => {
      const inputFiles = await fileService.getFilesByIds(fileIds, req.userId);

      for (const file of inputFiles) {
        if (file.fileType !== 'image') {
          throw AppError.badRequest(`File ${file.originalName} is not an image`);
        }
      }

      const inputPaths = inputFiles.map((f) => fileService.getFullPath(f));
      const outputPath = await imageService.mergeImages(inputPaths, { direction, format, quality, gap });

      const outputFile = await fileService.createOutputFile(
        {
          filePath: outputPath,
          originalName: `merged.${format}`,
          mimeType: `image/${format}`,
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'Images merged successfully');
});

/**
 * Convert PDF to DOCX
 * POST /api/convert/pdf-to-docx
 */
const pdfToDocx = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('PDF file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_TO_DOCX,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'pdf') {
        throw AppError.badRequest('File must be a PDF');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = storageService.getTempPath('.docx');
      const result = await documentService.pdfToDocx(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, '.pdf')}.docx`,
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PDF converted to DOCX successfully');
});

/**
 * Convert PDF to PPTX
 * POST /api/convert/pdf-to-pptx
 */
const pdfToPptx = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('PDF file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_TO_PPTX,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'pdf') {
        throw AppError.badRequest('File must be a PDF');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = storageService.getTempPath('.pptx');
      const result = await documentService.pdfToPptx(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, '.pdf')}.pptx`,
          mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PDF converted to PPTX successfully');
});

/**
 * Convert PDF to TXT (extract text)
 * POST /api/convert/pdf-to-text
 */
const pdfToText = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('PDF file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PDF_TO_TXT,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'pdf') {
        throw AppError.badRequest('File must be a PDF');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = storageService.getTempPath('.txt');
      const result = await pdfService.extractText(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, '.pdf')}.txt`,
          mimeType: 'text/plain',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PDF text extracted successfully');
});

/**
 * Convert DOCX to PDF
 * POST /api/convert/docx-to-pdf
 */
const docxToPdf = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('DOCX file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.DOCX_TO_PDF,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'document') {
        throw AppError.badRequest('File must be a DOCX document');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = storageService.getTempPath('.pdf');
      const result = await documentService.docxToPdf(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, path.extname(inputFile.originalName))}.pdf`,
          mimeType: 'application/pdf',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'DOCX converted to PDF successfully');
});

/**
 * Convert PPTX to PDF
 * POST /api/convert/pptx-to-pdf
 */
const pptxToPdf = catchAsync(async (req, res) => {
  const { fileId } = req.body;

  if (!fileId) {
    throw AppError.badRequest('PPTX file ID is required');
  }

  const job = await jobService.executeJob(
    {
      userId: req.userId,
      type: JOB_TYPES.PPTX_TO_PDF,
      inputFileIds: [fileId],
      options: {},
    },
    async (job) => {
      const inputFile = await fileService.getFileById(fileId, req.userId);

      if (inputFile.fileType !== 'document') {
        throw AppError.badRequest('File must be a PPTX document');
      }

      const inputPath = fileService.getFullPath(inputFile);
      const outputPath = storageService.getTempPath('.pdf');
      const result = await documentService.pptxToPdf(inputPath, outputPath);

      const outputFile = await fileService.createOutputFile(
        {
          filePath: result.path,
          originalName: `${path.basename(inputFile.originalName, path.extname(inputFile.originalName))}.pdf`,
          mimeType: 'application/pdf',
        },
        req.userId,
        job._id
      );

      return [outputFile._id];
    }
  );

  successResponse(res, { job }, 'PPTX converted to PDF successfully');
});

module.exports = {
  imagesToPdf,
  imagesToPptx,
  imagesToDocx,
  imageToText,
  convertImageFormat,
  transformImage,
  mergeImages,
  pdfToDocx,
  pdfToPptx,
  pdfToText,
  docxToPdf,
  pptxToPdf,
};
