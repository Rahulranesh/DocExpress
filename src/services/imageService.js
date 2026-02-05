/**
 * Image Processing Service
 * Uses Sharp for image manipulation and conversions
 */

const sharp = require('sharp');
const fs = require('fs').promises;
const path = require('path');
const { PDFDocument } = require('pdf-lib');
const PptxGenJS = require('pptxgenjs');
const { Document, Packer, Paragraph, ImageRun } = require('docx');
const { getTempPath } = require('../utils/tempPath');
const { IMAGE_FORMATS, IMAGE_QUALITY } = require('../utils/constants');
const AppError = require('../utils/AppError');

class ImageService {
  /**
   * Convert image to different format
   * @param {string} inputPath - Source image path
   * @param {string} targetFormat - Target format (jpeg, png, webp, etc.)
   * @param {Object} options - Conversion options
   * @returns {Promise<string>} - Output file path
   */
  async convertFormat(inputPath, targetFormat, options = {}) {
    const { quality = IMAGE_QUALITY.HIGH } = options;
    const outputPath = getTempPath(`.${targetFormat}`);

    let pipeline = sharp(inputPath);

    switch (targetFormat.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        pipeline = pipeline.jpeg({ quality, mozjpeg: true });
        break;
      case 'png':
        pipeline = pipeline.png({ compressionLevel: Math.floor((100 - quality) / 10) });
        break;
      case 'webp':
        pipeline = pipeline.webp({ quality });
        break;
      case 'tiff':
        pipeline = pipeline.tiff({ quality });
        break;
      case 'gif':
        pipeline = pipeline.gif();
        break;
      case 'heif':
      case 'heic':
        // HEIC/HEIF requires libheif support in sharp
        pipeline = pipeline.heif({ quality });
        break;
      default:
        throw AppError.badRequest(`Unsupported target format: ${targetFormat}`);
    }

    await pipeline.toFile(outputPath);
    return outputPath;
  }

  /**
   * Resize image
   * @param {string} inputPath - Source image path
   * @param {Object} options - Resize options (width, height, fit)
   * @returns {Promise<string>} - Output file path
   */
  async resize(inputPath, options = {}) {
    const { width, height, fit = 'inside', format = 'jpeg', quality = IMAGE_QUALITY.HIGH } = options;

    if (!width && !height) {
      throw AppError.badRequest('Width or height required for resize');
    }

    const outputPath = getTempPath(`.${format}`);

    await sharp(inputPath)
      .resize({
        width: width || null,
        height: height || null,
        fit,
        withoutEnlargement: true,
      })
      .toFormat(format, { quality })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Crop image
   * @param {string} inputPath - Source image path
   * @param {Object} options - Crop region (left, top, width, height)
   * @returns {Promise<string>} - Output file path
   */
  async crop(inputPath, options = {}) {
    const { left, top, width, height, format = 'jpeg', quality = IMAGE_QUALITY.HIGH } = options;

    if (!width || !height) {
      throw AppError.badRequest('Width and height required for crop');
    }

    const outputPath = getTempPath(`.${format}`);

    await sharp(inputPath)
      .extract({
        left: left || 0,
        top: top || 0,
        width,
        height,
      })
      .toFormat(format, { quality })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Rotate image
   * @param {string} inputPath - Source image path
   * @param {number} angle - Rotation angle (90, 180, 270 or any angle)
   * @param {Object} options - Additional options
   * @returns {Promise<string>} - Output file path
   */
  async rotate(inputPath, angle, options = {}) {
    const { format = 'jpeg', quality = IMAGE_QUALITY.HIGH, background = { r: 255, g: 255, b: 255, alpha: 1 } } = options;
    const outputPath = getTempPath(`.${format}`);

    await sharp(inputPath)
      .rotate(angle, { background })
      .toFormat(format, { quality })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Convert image to grayscale
   * @param {string} inputPath - Source image path
   * @param {Object} options - Additional options
   * @returns {Promise<string>} - Output file path
   */
  async grayscale(inputPath, options = {}) {
    const { format = 'jpeg', quality = IMAGE_QUALITY.HIGH } = options;
    const outputPath = getTempPath(`.${format}`);

    await sharp(inputPath)
      .grayscale()
      .toFormat(format, { quality })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Apply multiple transforms to an image
   * @param {string} inputPath - Source image path
   * @param {Array} operations - Array of operations [{type, options}]
   * @returns {Promise<string>} - Output file path
   */
  async applyTransforms(inputPath, operations, outputOptions = {}) {
    const { format = 'jpeg', quality = IMAGE_QUALITY.HIGH } = outputOptions;
    const outputPath = getTempPath(`.${format}`);

    let pipeline = sharp(inputPath);

    for (const op of operations) {
      switch (op.type) {
        case 'resize':
          pipeline = pipeline.resize({
            width: op.options?.width || null,
            height: op.options?.height || null,
            fit: op.options?.fit || 'inside',
          });
          break;
        case 'rotate':
          pipeline = pipeline.rotate(op.options?.angle || 0);
          break;
        case 'crop':
          pipeline = pipeline.extract({
            left: op.options?.left || 0,
            top: op.options?.top || 0,
            width: op.options?.width,
            height: op.options?.height,
          });
          break;
        case 'grayscale':
          pipeline = pipeline.grayscale();
          break;
        case 'flip':
          pipeline = pipeline.flip();
          break;
        case 'flop':
          pipeline = pipeline.flop();
          break;
        case 'blur':
          pipeline = pipeline.blur(op.options?.sigma || 3);
          break;
        case 'sharpen':
          pipeline = pipeline.sharpen();
          break;
        case 'negate':
          pipeline = pipeline.negate();
          break;
        default:
          console.warn(`Unknown operation: ${op.type}`);
      }
    }

    await pipeline.toFormat(format, { quality }).toFile(outputPath);
    return outputPath;
  }

  /**
   * Compress image
   * @param {string} inputPath - Source image path
   * @param {Object} options - Compression options
   * @returns {Promise<{path: string, originalSize: number, compressedSize: number}>}
   */
  async compress(inputPath, options = {}) {
    const {
      quality = IMAGE_QUALITY.MEDIUM,
      maxWidth,
      maxHeight,
      format,
    } = options;

    // Get original file info
    const metadata = await sharp(inputPath).metadata();
    const originalStats = await fs.stat(inputPath);

    // Determine output format
    const outputFormat = format || this.getFormatFromMime(metadata.format) || 'jpeg';
    const outputPath = getTempPath(`.${outputFormat}`);

    let pipeline = sharp(inputPath);

    // Resize if max dimensions specified
    if (maxWidth || maxHeight) {
      pipeline = pipeline.resize({
        width: maxWidth,
        height: maxHeight,
        fit: 'inside',
        withoutEnlargement: true,
      });
    }

    // Apply format-specific compression
    switch (outputFormat) {
      case 'jpeg':
      case 'jpg':
        pipeline = pipeline.jpeg({ quality, mozjpeg: true });
        break;
      case 'png':
        pipeline = pipeline.png({
          compressionLevel: 9,
          palette: true,
          quality,
        });
        break;
      case 'webp':
        pipeline = pipeline.webp({ quality });
        break;
      default:
        pipeline = pipeline.toFormat(outputFormat, { quality });
    }

    await pipeline.toFile(outputPath);

    const compressedStats = await fs.stat(outputPath);

    return {
      path: outputPath,
      originalSize: originalStats.size,
      compressedSize: compressedStats.size,
      compressionRatio: ((1 - compressedStats.size / originalStats.size) * 100).toFixed(2),
    };
  }

  /**
   * Convert multiple images to PDF
   * @param {string[]} inputPaths - Array of image paths
   * @param {Object} options - PDF options
   * @returns {Promise<string>} - Output PDF path
   */
  async imagesToPdf(inputPaths, options = {}) {
    const { pageSize = 'A4', margin = 20 } = options;
    const outputPath = getTempPath('.pdf');

    const pdfDoc = await PDFDocument.create();

    // Page size map
    const pageSizes = {
      A4: [595.28, 841.89],
      LETTER: [612, 792],
      LEGAL: [612, 1008],
    };

    const [pageWidth, pageHeight] = pageSizes[pageSize.toUpperCase()] || pageSizes.A4;
    const maxImageWidth = pageWidth - margin * 2;
    const maxImageHeight = pageHeight - margin * 2;

    for (const imagePath of inputPaths) {
      // Convert image to PNG buffer for PDF embedding
      const imageBuffer = await sharp(imagePath)
        .resize({
          width: Math.floor(maxImageWidth),
          height: Math.floor(maxImageHeight),
          fit: 'inside',
          withoutEnlargement: true,
        })
        .png()
        .toBuffer();

      // Get resized dimensions
      const metadata = await sharp(imageBuffer).metadata();

      // Embed image in PDF
      const pdfImage = await pdfDoc.embedPng(imageBuffer);

      // Add page and draw image centered
      const page = pdfDoc.addPage([pageWidth, pageHeight]);
      const x = (pageWidth - metadata.width) / 2;
      const y = (pageHeight - metadata.height) / 2;

      page.drawImage(pdfImage, {
        x,
        y,
        width: metadata.width,
        height: metadata.height,
      });
    }

    const pdfBytes = await pdfDoc.save();
    await fs.writeFile(outputPath, pdfBytes);

    return outputPath;
  }

  /**
   * Convert multiple images to PPTX (each image = one slide)
   * @param {string[]} inputPaths - Array of image paths
   * @param {Object} options - PPTX options
   * @returns {Promise<string>} - Output PPTX path
   */
  async imagesToPptx(inputPaths, options = {}) {
    const { slideWidth = 10, slideHeight = 7.5 } = options;
    const outputPath = getTempPath('.pptx');

    const pptx = new PptxGenJS();
    pptx.layout = 'LAYOUT_WIDE';

    for (const imagePath of inputPaths) {
      // Convert to base64 for embedding
      const imageBuffer = await sharp(imagePath)
        .resize({
          width: 1920,
          height: 1080,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .jpeg({ quality: 90 })
        .toBuffer();

      const base64Image = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;

      // Get dimensions for proper sizing
      const metadata = await sharp(imageBuffer).metadata();
      const aspectRatio = metadata.width / metadata.height;

      // Calculate slide dimensions
      let imgWidth = slideWidth - 1;
      let imgHeight = imgWidth / aspectRatio;

      if (imgHeight > slideHeight - 1) {
        imgHeight = slideHeight - 1;
        imgWidth = imgHeight * aspectRatio;
      }

      const slide = pptx.addSlide();
      slide.addImage({
        data: base64Image,
        x: (slideWidth - imgWidth) / 2,
        y: (slideHeight - imgHeight) / 2,
        w: imgWidth,
        h: imgHeight,
      });
    }

    await pptx.writeFile({ fileName: outputPath });
    return outputPath;
  }

  /**
   * Convert images to DOCX (images embedded)
   * @param {string[]} inputPaths - Array of image paths
   * @param {Object} options - DOCX options
   * @returns {Promise<string>} - Output DOCX path
   */
  async imagesToDocx(inputPaths, options = {}) {
    const { title = 'Image Document', maxWidth = 600 } = options;
    const outputPath = getTempPath('.docx');

    const children = [
      new Paragraph({
        text: title,
        heading: 'Heading1',
      }),
    ];

    for (const imagePath of inputPaths) {
      // Resize and convert to buffer
      const imageBuffer = await sharp(imagePath)
        .resize({ width: maxWidth, withoutEnlargement: true })
        .png()
        .toBuffer();

      const metadata = await sharp(imageBuffer).metadata();

      children.push(
        new Paragraph({
          children: [
            new ImageRun({
              data: imageBuffer,
              transformation: {
                width: metadata.width,
                height: metadata.height,
              },
            }),
          ],
        }),
        new Paragraph({ text: '' }) // Spacer
      );
    }

    const doc = new Document({
      sections: [{ children }],
    });

    const buffer = await Packer.toBuffer(doc);
    await fs.writeFile(outputPath, buffer);

    return outputPath;
  }

  /**
   * Extract text from image using OCR
   * @param {string} inputPath - Source image path
   * @returns {Promise<{path: string, text: string}>}
   */
  async imageToText(inputPath) {
    const outputPath = getTempPath('.txt');

    // Preprocess image for better OCR results
    const processedBuffer = await sharp(inputPath)
      .grayscale()
      .normalize()
      .sharpen()
      .toBuffer();

    let text = '';

    try {
      // Try to use Tesseract.js
      const Tesseract = require('tesseract.js');
      const result = await Tesseract.recognize(processedBuffer, 'eng', {
        logger: () => {}, // Suppress progress logs
      });
      text = result.data.text;
    } catch (err) {
      // Tesseract not available or failed
      // TODO: Implement fallback OCR or return stub
      console.warn('OCR failed, returning stub text:', err.message);
      text = `[OCR STUB] Unable to extract text from image.\nFile: ${path.basename(inputPath)}\nPlease ensure Tesseract.js is properly installed.`;
    }

    await fs.writeFile(outputPath, text, 'utf8');

    return {
      path: outputPath,
      text,
    };
  }

  /**
   * Merge multiple images into one (horizontally or vertically)
   * @param {string[]} inputPaths - Array of image paths
   * @param {Object} options - Merge options
   * @returns {Promise<string>} - Output image path
   */
  async mergeImages(inputPaths, options = {}) {
    const {
      direction = 'vertical',
      gap = 0,
      background = { r: 255, g: 255, b: 255, alpha: 1 },
      format = 'jpeg',
      quality = IMAGE_QUALITY.HIGH,
    } = options;

    const outputPath = getTempPath(`.${format}`);

    // Get metadata for all images
    const metadataList = await Promise.all(
      inputPaths.map(async (p) => {
        const meta = await sharp(p).metadata();
        return { path: p, width: meta.width, height: meta.height };
      })
    );

    let totalWidth, totalHeight;
    const compositeOperations = [];

    if (direction === 'horizontal') {
      totalWidth = metadataList.reduce((sum, m) => sum + m.width, 0) + gap * (metadataList.length - 1);
      totalHeight = Math.max(...metadataList.map((m) => m.height));

      let currentX = 0;
      for (const meta of metadataList) {
        const imageBuffer = await sharp(meta.path).toBuffer();
        compositeOperations.push({
          input: imageBuffer,
          left: currentX,
          top: Math.floor((totalHeight - meta.height) / 2),
        });
        currentX += meta.width + gap;
      }
    } else {
      totalWidth = Math.max(...metadataList.map((m) => m.width));
      totalHeight = metadataList.reduce((sum, m) => sum + m.height, 0) + gap * (metadataList.length - 1);

      let currentY = 0;
      for (const meta of metadataList) {
        const imageBuffer = await sharp(meta.path).toBuffer();
        compositeOperations.push({
          input: imageBuffer,
          left: Math.floor((totalWidth - meta.width) / 2),
          top: currentY,
        });
        currentY += meta.height + gap;
      }
    }

    // Create canvas and composite images
    await sharp({
      create: {
        width: totalWidth,
        height: totalHeight,
        channels: 4,
        background,
      },
    })
      .composite(compositeOperations)
      .toFormat(format, { quality })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Get image metadata
   * @param {string} inputPath - Image path
   * @returns {Promise<Object>} - Image metadata
   */
  async getMetadata(inputPath) {
    const metadata = await sharp(inputPath).metadata();
    const stats = await fs.stat(inputPath);

    return {
      width: metadata.width,
      height: metadata.height,
      format: metadata.format,
      channels: metadata.channels,
      hasAlpha: metadata.hasAlpha,
      orientation: metadata.orientation,
      size: stats.size,
    };
  }

  /**
   * Generate thumbnail
   * @param {string} inputPath - Source image path
   * @param {Object} options - Thumbnail options
   * @returns {Promise<string>} - Thumbnail path
   */
  async generateThumbnail(inputPath, options = {}) {
    const { width = 200, height = 200, fit = 'cover' } = options;
    const outputPath = getTempPath('.jpg');

    await sharp(inputPath)
      .resize(width, height, { fit, position: 'center' })
      .jpeg({ quality: 80 })
      .toFile(outputPath);

    return outputPath;
  }

  /**
   * Helper: Get format string from MIME type
   */
  getFormatFromMime(format) {
    const formatMap = {
      jpeg: 'jpeg',
      jpg: 'jpeg',
      png: 'png',
      webp: 'webp',
      gif: 'gif',
      tiff: 'tiff',
      heif: 'heif',
      heic: 'heif',
    };
    return formatMap[format] || 'jpeg';
  }

  /**
   * Validate image file
   * @param {string} inputPath - Image path to validate
   * @returns {Promise<boolean>}
   */
  async validateImage(inputPath) {
    try {
      const metadata = await sharp(inputPath).metadata();
      return !!(metadata.width && metadata.height);
    } catch {
      return false;
    }
  }
}

module.exports = new ImageService();

