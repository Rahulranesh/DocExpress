/**
 * PDF Service - handles PDF manipulation operations
 * Uses pdf-lib for most operations
 */

const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const fs = require('fs').promises;
const path = require('path');
const sharp = require('sharp');
const storageService = require('./storageService');
const AppError = require('../utils/AppError');

class PdfService {
  /**
   * Merge multiple PDFs into one
   * @param {string[]} inputPaths - Array of paths to PDF files
   * @param {string} outputPath - Path for merged output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async mergePdfs(inputPaths, outputPath) {
    try {
      const mergedPdf = await PDFDocument.create();

      for (const inputPath of inputPaths) {
        const pdfBytes = await fs.readFile(inputPath);
        const pdf = await PDFDocument.load(pdfBytes);
        const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
        copiedPages.forEach((page) => mergedPdf.addPage(page));
      }

      const mergedPdfBytes = await mergedPdf.save();
      await fs.writeFile(outputPath, mergedPdfBytes);

      return {
        path: outputPath,
        pageCount: mergedPdf.getPageCount(),
      };
    } catch (error) {
      throw AppError.internal(`PDF merge failed: ${error.message}`);
    }
  }

  /**
   * Split PDF by page ranges
   * @param {string} inputPath - Path to source PDF
   * @param {Array<{start: number, end: number}>} ranges - Page ranges (1-indexed)
   * @param {string} outputDir - Directory for output files
   * @returns {Promise<Array<{path: string, range: string, pageCount: number}>>}
   */
  async splitPdf(inputPath, ranges, outputDir) {
    try {
      const pdfBytes = await fs.readFile(inputPath);
      const sourcePdf = await PDFDocument.load(pdfBytes);
      const totalPages = sourcePdf.getPageCount();
      const outputs = [];

      for (let i = 0; i < ranges.length; i++) {
        const { start, end } = ranges[i];

        // Validate range
        if (start < 1 || end > totalPages || start > end) {
          throw AppError.badRequest(`Invalid page range: ${start}-${end}`);
        }

        const newPdf = await PDFDocument.create();
        // Convert to 0-indexed
        const pageIndices = [];
        for (let p = start - 1; p < end; p++) {
          pageIndices.push(p);
        }

        const copiedPages = await newPdf.copyPages(sourcePdf, pageIndices);
        copiedPages.forEach((page) => newPdf.addPage(page));

        const outputPath = path.join(outputDir, `split_${start}-${end}.pdf`);
        const newPdfBytes = await newPdf.save();
        await fs.writeFile(outputPath, newPdfBytes);

        outputs.push({
          path: outputPath,
          range: `${start}-${end}`,
          pageCount: copiedPages.length,
        });
      }

      return outputs;
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw AppError.internal(`PDF split failed: ${error.message}`);
    }
  }

  /**
   * Reorder PDF pages
   * @param {string} inputPath - Path to source PDF
   * @param {number[]} pageOrder - New page order (1-indexed)
   * @param {string} outputPath - Path for output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async reorderPages(inputPath, pageOrder, outputPath) {
    try {
      const pdfBytes = await fs.readFile(inputPath);
      const sourcePdf = await PDFDocument.load(pdfBytes);
      const totalPages = sourcePdf.getPageCount();

      // Validate page order
      const uniquePages = new Set(pageOrder);
      if (uniquePages.size !== pageOrder.length) {
        throw AppError.badRequest('Duplicate pages in order array');
      }

      for (const pageNum of pageOrder) {
        if (pageNum < 1 || pageNum > totalPages) {
          throw AppError.badRequest(`Invalid page number: ${pageNum}`);
        }
      }

      const newPdf = await PDFDocument.create();
      // Convert to 0-indexed
      const zeroIndexedOrder = pageOrder.map((p) => p - 1);
      const copiedPages = await newPdf.copyPages(sourcePdf, zeroIndexedOrder);
      copiedPages.forEach((page) => newPdf.addPage(page));

      const newPdfBytes = await newPdf.save();
      await fs.writeFile(outputPath, newPdfBytes);

      return {
        path: outputPath,
        pageCount: newPdf.getPageCount(),
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw AppError.internal(`PDF reorder failed: ${error.message}`);
    }
  }

  /**
   * Extract text from PDF
   * @param {string} inputPath - Path to PDF
   * @param {string} outputPath - Path for TXT output
   * @returns {Promise<{path: string, text: string}>}
   */
  async extractText(inputPath, outputPath) {
    try {
      // NOTE: pdf-lib doesn't support text extraction
      // This is a stub implementation that returns page info
      // For full text extraction, consider using pdf-parse or similar
      // TODO: Implement proper text extraction with pdf-parse library

      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const pageCount = pdf.getPageCount();

      // Stub: Generate placeholder text
      let extractedText = `PDF Text Extraction\n`;
      extractedText += `===================\n`;
      extractedText += `Total Pages: ${pageCount}\n\n`;
      extractedText += `[Note: Full text extraction requires pdf-parse library]\n`;
      extractedText += `[TODO: Implement proper OCR/text extraction]\n`;

      // For each page, add placeholder
      for (let i = 0; i < pageCount; i++) {
        const page = pdf.getPage(i);
        const { width, height } = page.getSize();
        extractedText += `\n--- Page ${i + 1} (${Math.round(width)}x${Math.round(height)}) ---\n`;
        extractedText += `[Page content placeholder]\n`;
      }

      await fs.writeFile(outputPath, extractedText, 'utf8');

      return {
        path: outputPath,
        text: extractedText,
        pageCount,
      };
    } catch (error) {
      throw AppError.internal(`PDF text extraction failed: ${error.message}`);
    }
  }

  /**
   * Extract images from PDF
   * @param {string} inputPath - Path to PDF
   * @param {string} outputDir - Directory for extracted images
   * @returns {Promise<Array<{path: string, page: number}>>}
   */
  async extractImages(inputPath, outputDir) {
    try {
      // NOTE: Extracting embedded images from PDF is complex
      // pdf-lib doesn't directly support this
      // TODO: Implement proper image extraction using pdf.js or similar

      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const pageCount = pdf.getPageCount();

      // Stub: Create placeholder images for each page (page thumbnails)
      const outputs = [];

      // For now, we'll render pages as images using a placeholder approach
      // In production, use pdf2pic, pdf-poppler, or ghostscript
      console.warn('PDF image extraction using placeholder - implement with pdf-poppler for production');

      for (let i = 0; i < pageCount; i++) {
        const page = pdf.getPage(i);
        const { width, height } = page.getSize();

        // Create a placeholder image with sharp
        const imgWidth = Math.min(Math.round(width), 800);
        const imgHeight = Math.min(Math.round(height), 1200);

        const placeholderImg = await sharp({
          create: {
            width: imgWidth,
            height: imgHeight,
            channels: 3,
            background: { r: 240, g: 240, b: 240 },
          },
        })
          .png()
          .toBuffer();

        const outputPath = path.join(outputDir, `page_${i + 1}.png`);
        await fs.writeFile(outputPath, placeholderImg);

        outputs.push({
          path: outputPath,
          page: i + 1,
          width: imgWidth,
          height: imgHeight,
        });
      }

      return outputs;
    } catch (error) {
      throw AppError.internal(`PDF image extraction failed: ${error.message}`);
    }
  }

  /**
   * Create PDF from images
   * @param {string[]} imagePaths - Paths to images
   * @param {string} outputPath - Output PDF path
   * @param {Object} options - Options (pageSize, fit)
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async createPdfFromImages(imagePaths, outputPath, options = {}) {
    try {
      const { pageSize = 'A4', fit = 'contain' } = options;

      const pdf = await PDFDocument.create();

      // Page dimensions (A4 in points: 595 x 842)
      const pageSizes = {
        A4: { width: 595, height: 842 },
        Letter: { width: 612, height: 792 },
        A3: { width: 842, height: 1191 },
      };

      const { width: pageWidth, height: pageHeight } = pageSizes[pageSize] || pageSizes.A4;

      for (const imagePath of imagePaths) {
        const imageBuffer = await fs.readFile(imagePath);
        const ext = path.extname(imagePath).toLowerCase();

        let image;
        if (ext === '.png') {
          image = await pdf.embedPng(imageBuffer);
        } else if (ext === '.jpg' || ext === '.jpeg') {
          image = await pdf.embedJpg(imageBuffer);
        } else {
          // Convert to PNG using sharp for other formats
          const pngBuffer = await sharp(imageBuffer).png().toBuffer();
          image = await pdf.embedPng(pngBuffer);
        }

        const imgWidth = image.width;
        const imgHeight = image.height;

        // Calculate dimensions to fit on page
        let drawWidth, drawHeight, x, y;

        if (fit === 'contain') {
          const widthRatio = pageWidth / imgWidth;
          const heightRatio = pageHeight / imgHeight;
          const ratio = Math.min(widthRatio, heightRatio);
          drawWidth = imgWidth * ratio;
          drawHeight = imgHeight * ratio;
          x = (pageWidth - drawWidth) / 2;
          y = (pageHeight - drawHeight) / 2;
        } else if (fit === 'cover') {
          const widthRatio = pageWidth / imgWidth;
          const heightRatio = pageHeight / imgHeight;
          const ratio = Math.max(widthRatio, heightRatio);
          drawWidth = imgWidth * ratio;
          drawHeight = imgHeight * ratio;
          x = (pageWidth - drawWidth) / 2;
          y = (pageHeight - drawHeight) / 2;
        } else {
          // fit === 'stretch' or default
          drawWidth = pageWidth;
          drawHeight = pageHeight;
          x = 0;
          y = 0;
        }

        const page = pdf.addPage([pageWidth, pageHeight]);
        page.drawImage(image, {
          x,
          y,
          width: drawWidth,
          height: drawHeight,
        });
      }

      const pdfBytes = await pdf.save();
      await fs.writeFile(outputPath, pdfBytes);

      return {
        path: outputPath,
        pageCount: pdf.getPageCount(),
      };
    } catch (error) {
      throw AppError.internal(`PDF creation from images failed: ${error.message}`);
    }
  }

  /**
   * Compress PDF (reduce file size)
   * @param {string} inputPath - Path to PDF
   * @param {string} outputPath - Output path
   * @param {Object} options - Compression options
   * @returns {Promise<{path: string, originalSize: number, compressedSize: number}>}
   */
  async compressPdf(inputPath, outputPath, options = {}) {
    try {
      const { quality = 'medium' } = options;

      const originalStats = await fs.stat(inputPath);
      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);

      // pdf-lib doesn't have direct compression options
      // We save with default settings which may slightly reduce size
      // TODO: For better compression, use ghostscript or similar

      // Save with options
      const compressedBytes = await pdf.save({
        useObjectStreams: true, // Reduces size slightly
      });

      await fs.writeFile(outputPath, compressedBytes);
      const compressedStats = await fs.stat(outputPath);

      return {
        path: outputPath,
        originalSize: originalStats.size,
        compressedSize: compressedStats.size,
        reduction: Math.round((1 - compressedStats.size / originalStats.size) * 100),
      };
    } catch (error) {
      throw AppError.internal(`PDF compression failed: ${error.message}`);
    }
  }

  /**
   * Get PDF info/metadata
   * @param {string} inputPath - Path to PDF
   * @returns {Promise<Object>}
   */
  async getPdfInfo(inputPath) {
    try {
      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);

      const pages = [];
      for (let i = 0; i < pdf.getPageCount(); i++) {
        const page = pdf.getPage(i);
        const { width, height } = page.getSize();
        pages.push({ page: i + 1, width, height });
      }

      return {
        pageCount: pdf.getPageCount(),
        title: pdf.getTitle() || null,
        author: pdf.getAuthor() || null,
        subject: pdf.getSubject() || null,
        creator: pdf.getCreator() || null,
        producer: pdf.getProducer() || null,
        creationDate: pdf.getCreationDate() || null,
        modificationDate: pdf.getModificationDate() || null,
        pages,
      };
    } catch (error) {
      throw AppError.internal(`Failed to get PDF info: ${error.message}`);
    }
  }

  /**
   * Add watermark to PDF
   * @param {string} inputPath - Path to PDF
   * @param {string} watermarkText - Watermark text
   * @param {string} outputPath - Output path
   * @returns {Promise<{path: string}>}
   */
  async addWatermark(inputPath, watermarkText, outputPath, options = {}) {
    try {
      const { opacity = 0.3, fontSize = 50, angle = -45 } = options;

      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const font = await pdf.embedFont(StandardFonts.Helvetica);

      const pages = pdf.getPages();
      for (const page of pages) {
        const { width, height } = page.getSize();

        page.drawText(watermarkText, {
          x: width / 4,
          y: height / 2,
          size: fontSize,
          font,
          color: rgb(0.5, 0.5, 0.5),
          opacity,
          rotate: { type: 'degrees', angle },
        });
      }

      const outputBytes = await pdf.save();
      await fs.writeFile(outputPath, outputBytes);

      return { path: outputPath };
    } catch (error) {
      throw AppError.internal(`Failed to add watermark: ${error.message}`);
    }
  }

  /**
   * Remove specific pages from PDF
   * @param {string} inputPath - Path to PDF
   * @param {number[]} pagesToRemove - Pages to remove (1-indexed)
   * @param {string} outputPath - Output path
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async removePages(inputPath, pagesToRemove, outputPath) {
    try {
      const pdfBytes = await fs.readFile(inputPath);
      const sourcePdf = await PDFDocument.load(pdfBytes);
      const totalPages = sourcePdf.getPageCount();

      // Get pages to keep (0-indexed)
      const pagesToKeep = [];
      for (let i = 0; i < totalPages; i++) {
        if (!pagesToRemove.includes(i + 1)) {
          pagesToKeep.push(i);
        }
      }

      if (pagesToKeep.length === 0) {
        throw AppError.badRequest('Cannot remove all pages from PDF');
      }

      const newPdf = await PDFDocument.create();
      const copiedPages = await newPdf.copyPages(sourcePdf, pagesToKeep);
      copiedPages.forEach((page) => newPdf.addPage(page));

      const newPdfBytes = await newPdf.save();
      await fs.writeFile(outputPath, newPdfBytes);

      return {
        path: outputPath,
        pageCount: newPdf.getPageCount(),
        removedPages: pagesToRemove.length,
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw AppError.internal(`Failed to remove pages: ${error.message}`);
    }
  }

  /**
   * Rotate pages in PDF
   * @param {string} inputPath - Path to PDF
   * @param {Object} rotations - Map of page numbers to rotation degrees
   * @param {string} outputPath - Output path
   * @returns {Promise<{path: string}>}
   */
  async rotatePages(inputPath, rotations, outputPath) {
    try {
      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);

      for (const [pageNum, degrees] of Object.entries(rotations)) {
        const pageIndex = parseInt(pageNum, 10) - 1;
        if (pageIndex >= 0 && pageIndex < pdf.getPageCount()) {
          const page = pdf.getPage(pageIndex);
          const currentRotation = page.getRotation().angle;
          page.setRotation({ type: 'degrees', angle: currentRotation + degrees });
        }
      }

      const outputBytes = await pdf.save();
      await fs.writeFile(outputPath, outputBytes);

      return { path: outputPath };
    } catch (error) {
      throw AppError.internal(`Failed to rotate pages: ${error.message}`);
    }
  }
}

module.exports = new PdfService();
