/**
 * Document Conversion Service
 * Handles DOCX, PPTX conversions and related operations
 */

const fs = require('fs').promises;
const path = require('path');
const { Document, Packer, Paragraph, TextRun, HeadingLevel } = require('docx');
const PptxGenJS = require('pptxgenjs');
const { PDFDocument } = require('pdf-lib');
const storageService = require('./storageService');
const AppError = require('../utils/AppError');

class DocumentService {
  /**
   * Convert DOCX to PDF
   * NOTE: Full DOCX to PDF requires LibreOffice or similar
   * This is a stub that creates a basic PDF from extracted text
   * @param {string} inputPath - Path to DOCX file
   * @param {string} outputPath - Path for PDF output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async docxToPdf(inputPath, outputPath) {
    try {
      // TODO: Implement proper DOCX to PDF using LibreOffice/unoconv
      // For now, create a placeholder PDF
      // In production, use: child_process.exec('libreoffice --convert-to pdf ...')

      console.warn('DOCX to PDF using stub - implement with LibreOffice for production');

      const pdf = await PDFDocument.create();
      const page = pdf.addPage([595, 842]); // A4 size
      const font = await pdf.embedFont('Helvetica');

      // Add placeholder text
      page.drawText('DOCX to PDF Conversion', {
        x: 50,
        y: 800,
        size: 18,
        font,
      });

      page.drawText(`Source: ${path.basename(inputPath)}`, {
        x: 50,
        y: 770,
        size: 12,
        font,
      });

      page.drawText('[Full conversion requires LibreOffice integration]', {
        x: 50,
        y: 740,
        size: 10,
        font,
      });

      page.drawText('TODO: Implement proper DOCX parsing and rendering', {
        x: 50,
        y: 710,
        size: 10,
        font,
      });

      const pdfBytes = await pdf.save();
      await fs.writeFile(outputPath, pdfBytes);

      return {
        path: outputPath,
        pageCount: 1,
        stub: true,
      };
    } catch (error) {
      throw AppError.internal(`DOCX to PDF conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert PDF to DOCX
   * NOTE: Full PDF to DOCX requires complex parsing
   * This creates a basic DOCX with extracted structure
   * @param {string} inputPath - Path to PDF file
   * @param {string} outputPath - Path for DOCX output
   * @returns {Promise<{path: string}>}
   */
  async pdfToDocx(inputPath, outputPath) {
    try {
      // TODO: Implement proper PDF to DOCX using pdf-parse or pdf.js
      // For now, create a placeholder DOCX

      console.warn('PDF to DOCX using stub - implement with pdf-parse for production');

      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const pageCount = pdf.getPageCount();

      const children = [
        new Paragraph({
          text: 'PDF to DOCX Conversion',
          heading: HeadingLevel.HEADING_1,
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: `Source file: ${path.basename(inputPath)}`,
              italics: true,
            }),
          ],
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: `Total pages: ${pageCount}`,
            }),
          ],
        }),
        new Paragraph({ text: '' }),
        new Paragraph({
          children: [
            new TextRun({
              text: '[Note: Full PDF text extraction requires pdf-parse library]',
              color: '888888',
            }),
          ],
        }),
      ];

      // Add page placeholders
      for (let i = 0; i < pageCount; i++) {
        const page = pdf.getPage(i);
        const { width, height } = page.getSize();

        children.push(
          new Paragraph({ text: '' }),
          new Paragraph({
            text: `Page ${i + 1}`,
            heading: HeadingLevel.HEADING_2,
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: `Dimensions: ${Math.round(width)} x ${Math.round(height)} points`,
                size: 20,
              }),
            ],
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: '[Page content would be extracted here]',
                color: '999999',
                italics: true,
              }),
            ],
          })
        );
      }

      const doc = new Document({
        sections: [{ children }],
      });

      const buffer = await Packer.toBuffer(doc);
      await fs.writeFile(outputPath, buffer);

      return {
        path: outputPath,
        pageCount,
        stub: true,
      };
    } catch (error) {
      throw AppError.internal(`PDF to DOCX conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert PDF to PPTX
   * Each page becomes a slide
   * @param {string} inputPath - Path to PDF file
   * @param {string} outputPath - Path for PPTX output
   * @returns {Promise<{path: string, slideCount: number}>}
   */
  async pdfToPptx(inputPath, outputPath) {
    try {
      // TODO: Implement proper PDF to PPTX with page rendering
      // Would need pdf-poppler or similar to render pages as images

      console.warn('PDF to PPTX using stub - implement with pdf-poppler for production');

      const pdfBytes = await fs.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const pageCount = pdf.getPageCount();

      const pptx = new PptxGenJS();
      pptx.layout = 'LAYOUT_WIDE';
      pptx.title = path.basename(inputPath, '.pdf');

      // Title slide
      const titleSlide = pptx.addSlide();
      titleSlide.addText('PDF to PPTX Conversion', {
        x: 0.5,
        y: 2,
        w: '90%',
        h: 1.5,
        fontSize: 36,
        bold: true,
        align: 'center',
      });
      titleSlide.addText(`Source: ${path.basename(inputPath)}`, {
        x: 0.5,
        y: 4,
        w: '90%',
        h: 0.5,
        fontSize: 18,
        align: 'center',
        color: '666666',
      });
      titleSlide.addText(`${pageCount} pages`, {
        x: 0.5,
        y: 4.7,
        w: '90%',
        h: 0.5,
        fontSize: 14,
        align: 'center',
        color: '888888',
      });

      // Create a slide for each page
      for (let i = 0; i < pageCount; i++) {
        const page = pdf.getPage(i);
        const { width, height } = page.getSize();

        const slide = pptx.addSlide();

        slide.addText(`Page ${i + 1}`, {
          x: 0.3,
          y: 0.2,
          w: 3,
          h: 0.4,
          fontSize: 14,
          color: '666666',
        });

        // Placeholder for page content
        slide.addShape('rect', {
          x: 0.5,
          y: 0.8,
          w: 12.3,
          h: 6.2,
          fill: { color: 'F5F5F5' },
          line: { color: 'CCCCCC', width: 1 },
        });

        slide.addText(`[PDF Page ${i + 1} - ${Math.round(width)}x${Math.round(height)}]`, {
          x: 0.5,
          y: 3.5,
          w: 12.3,
          h: 0.5,
          fontSize: 14,
          align: 'center',
          color: '999999',
        });

        slide.addText('[Full rendering requires pdf-poppler integration]', {
          x: 0.5,
          y: 4.2,
          w: 12.3,
          h: 0.4,
          fontSize: 11,
          align: 'center',
          color: 'AAAAAA',
          italic: true,
        });
      }

      await pptx.writeFile({ fileName: outputPath });

      return {
        path: outputPath,
        slideCount: pageCount + 1, // Including title slide
        stub: true,
      };
    } catch (error) {
      throw AppError.internal(`PDF to PPTX conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert PPTX to PDF
   * NOTE: Full PPTX to PDF requires LibreOffice or similar
   * @param {string} inputPath - Path to PPTX file
   * @param {string} outputPath - Path for PDF output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async pptxToPdf(inputPath, outputPath) {
    try {
      // TODO: Implement proper PPTX to PDF using LibreOffice
      // For now, create a placeholder PDF

      console.warn('PPTX to PDF using stub - implement with LibreOffice for production');

      const pdf = await PDFDocument.create();

      // Create landscape page (typical slide dimensions)
      const page = pdf.addPage([842, 595]); // A4 landscape
      const font = await pdf.embedFont('Helvetica');

      page.drawText('PPTX to PDF Conversion', {
        x: 50,
        y: 550,
        size: 24,
        font,
      });

      page.drawText(`Source: ${path.basename(inputPath)}`, {
        x: 50,
        y: 510,
        size: 14,
        font,
      });

      page.drawText('[Full PPTX to PDF conversion requires LibreOffice integration]', {
        x: 50,
        y: 470,
        size: 12,
        font,
      });

      page.drawText('TODO: Implement proper PPTX parsing and rendering', {
        x: 50,
        y: 440,
        size: 10,
        font,
      });

      // Add border to simulate slide
      page.drawRectangle({
        x: 30,
        y: 30,
        width: 782,
        height: 535,
        borderColor: { red: 0.8, green: 0.8, blue: 0.8 },
        borderWidth: 1,
      });

      const pdfBytes = await pdf.save();
      await fs.writeFile(outputPath, pdfBytes);

      return {
        path: outputPath,
        pageCount: 1,
        stub: true,
      };
    } catch (error) {
      throw AppError.internal(`PPTX to PDF conversion failed: ${error.message}`);
    }
  }

  /**
   * Create DOCX from text content
   * @param {string} text - Text content
   * @param {string} outputPath - Path for DOCX output
   * @param {Object} options - Formatting options
   * @returns {Promise<{path: string}>}
   */
  async createDocxFromText(text, outputPath, options = {}) {
    try {
      const { title = 'Document', fontSize = 24 } = options;

      const paragraphs = text.split('\n').map(
        (line) =>
          new Paragraph({
            children: [
              new TextRun({
                text: line,
                size: fontSize,
              }),
            ],
          })
      );

      const doc = new Document({
        sections: [
          {
            properties: {},
            children: [
              new Paragraph({
                text: title,
                heading: HeadingLevel.HEADING_1,
              }),
              ...paragraphs,
            ],
          },
        ],
      });

      const buffer = await Packer.toBuffer(doc);
      await fs.writeFile(outputPath, buffer);

      return { path: outputPath };
    } catch (error) {
      throw AppError.internal(`DOCX creation failed: ${error.message}`);
    }
  }

  /**
   * Create PPTX from text slides
   * @param {Array<{title: string, content: string}>} slides - Slide data
   * @param {string} outputPath - Path for PPTX output
   * @returns {Promise<{path: string, slideCount: number}>}
   */
  async createPptxFromSlides(slides, outputPath, options = {}) {
    try {
      const { presentationTitle = 'Presentation' } = options;

      const pptx = new PptxGenJS();
      pptx.layout = 'LAYOUT_WIDE';
      pptx.title = presentationTitle;

      for (const slideData of slides) {
        const slide = pptx.addSlide();

        if (slideData.title) {
          slide.addText(slideData.title, {
            x: 0.5,
            y: 0.5,
            w: '90%',
            h: 1,
            fontSize: 28,
            bold: true,
          });
        }

        if (slideData.content) {
          slide.addText(slideData.content, {
            x: 0.5,
            y: 1.8,
            w: '90%',
            h: 5,
            fontSize: 18,
            valign: 'top',
          });
        }

        if (slideData.bullets) {
          slide.addText(
            slideData.bullets.map((bullet) => ({
              text: bullet,
              options: { bullet: true },
            })),
            {
              x: 0.5,
              y: 1.8,
              w: '90%',
              h: 5,
              fontSize: 16,
            }
          );
        }
      }

      await pptx.writeFile({ fileName: outputPath });

      return {
        path: outputPath,
        slideCount: slides.length,
      };
    } catch (error) {
      throw AppError.internal(`PPTX creation failed: ${error.message}`);
    }
  }

  /**
   * Extract text from DOCX
   * @param {string} inputPath - Path to DOCX file
   * @param {string} outputPath - Path for TXT output
   * @returns {Promise<{path: string, text: string}>}
   */
  async extractTextFromDocx(inputPath, outputPath) {
    try {
      // TODO: Implement proper DOCX text extraction using mammoth or similar
      // For now, return a stub

      console.warn('DOCX text extraction using stub - implement with mammoth for production');

      const text = `[DOCX Text Extraction Stub]\n\nSource: ${path.basename(inputPath)}\n\n[Full text extraction requires mammoth.js or similar library]\n\nTODO: Implement proper DOCX parsing`;

      await fs.writeFile(outputPath, text, 'utf8');

      return {
        path: outputPath,
        text,
        stub: true,
      };
    } catch (error) {
      throw AppError.internal(`DOCX text extraction failed: ${error.message}`);
    }
  }

  /**
   * Get document info/metadata
   * @param {string} inputPath - Path to document
   * @param {string} type - Document type ('docx' or 'pptx')
   * @returns {Promise<Object>}
   */
  async getDocumentInfo(inputPath, type) {
    try {
      const stats = await fs.stat(inputPath);

      return {
        type,
        filename: path.basename(inputPath),
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime,
        // TODO: Extract actual document metadata (title, author, etc.)
        metadata: {
          note: 'Full metadata extraction requires additional libraries',
        },
      };
    } catch (error) {
      throw AppError.internal(`Failed to get document info: ${error.message}`);
    }
  }
}

module.exports = new DocumentService();
