/**
 * Document Conversion Service
 * Handles DOCX, PPTX conversions and related operations
 */

const fs = require('fs').promises;
const path = require('path');
const { Document, Packer, Paragraph, TextRun, HeadingLevel, PageBreak } = require('docx');
const PptxGenJS = require('pptxgenjs');
const { PDFDocument, StandardFonts, rgb } = require('pdf-lib');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');
const JSZip = require('jszip');
const storageService = require('./storageService');
const AppError = require('../utils/AppError');

class DocumentService {
  /**
   * Convert DOCX to PDF
   * Extracts content from DOCX and creates a properly formatted PDF
   * @param {string} inputPath - Path to DOCX file
   * @param {string} outputPath - Path for PDF output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async docxToPdf(inputPath, outputPath) {
    try {
      const buffer = await fs.readFile(inputPath);
      
      // Extract text from DOCX using mammoth
      const result = await mammoth.extractRawText({ buffer });
      const text = result.value;
      const lines = text.split('\n');

      const pdf = await PDFDocument.create();
      const font = await pdf.embedFont(StandardFonts.Helvetica);
      const boldFont = await pdf.embedFont(StandardFonts.HelveticaBold);
      
      const fontSize = 11;
      const lineHeight = fontSize * 1.4;
      const margin = 50;
      const pageWidth = 595; // A4
      const pageHeight = 842;
      const contentWidth = pageWidth - (margin * 2);
      const linesPerPage = Math.floor((pageHeight - (margin * 2)) / lineHeight);

      let pageCount = 0;
      let currentPage = null;
      let currentY = pageHeight - margin;
      let lineIndex = 0;

      const addPage = () => {
        currentPage = pdf.addPage([pageWidth, pageHeight]);
        currentY = pageHeight - margin;
        pageCount++;
        return currentPage;
      };

      // Create first page
      addPage();

      // Add title
      const title = path.basename(inputPath, '.docx');
      currentPage.drawText(title, {
        x: margin,
        y: currentY,
        size: 18,
        font: boldFont,
        color: rgb(0.1, 0.1, 0.1),
      });
      currentY -= 30;

      // Process lines
      for (const line of lines) {
        if (!line.trim()) {
          currentY -= lineHeight / 2;
          continue;
        }

        // Word wrap
        const words = line.split(' ');
        let currentLine = '';
        
        for (const word of words) {
          const testLine = currentLine ? `${currentLine} ${word}` : word;
          const textWidth = font.widthOfTextAtSize(testLine, fontSize);
          
          if (textWidth > contentWidth && currentLine) {
            // Draw current line and start new one
            if (currentY < margin + lineHeight) {
              addPage();
            }
            
            currentPage.drawText(currentLine, {
              x: margin,
              y: currentY,
              size: fontSize,
              font,
              color: rgb(0, 0, 0),
            });
            currentY -= lineHeight;
            currentLine = word;
          } else {
            currentLine = testLine;
          }
        }
        
        // Draw remaining text
        if (currentLine) {
          if (currentY < margin + lineHeight) {
            addPage();
          }
          
          currentPage.drawText(currentLine, {
            x: margin,
            y: currentY,
            size: fontSize,
            font,
            color: rgb(0, 0, 0),
          });
          currentY -= lineHeight;
        }
      }

      const pdfBytes = await pdf.save();
      await fs.writeFile(outputPath, pdfBytes);

      return {
        path: outputPath,
        pageCount,
      };
    } catch (error) {
      throw AppError.internal(`DOCX to PDF conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert PDF to DOCX
   * Extracts text from PDF and creates a properly formatted DOCX
   * @param {string} inputPath - Path to PDF file
   * @param {string} outputPath - Path for DOCX output
   * @returns {Promise<{path: string}>}
   */
  async pdfToDocx(inputPath, outputPath) {
    try {
      const pdfBuffer = await fs.readFile(inputPath);
      
      // Extract text from PDF using pdf-parse
      const pdfData = await pdfParse(pdfBuffer);
      const extractedText = pdfData.text || '';
      const pageCount = pdfData.numpages || 1;
      const metadata = pdfData.info || {};

      // Split text into paragraphs
      const textLines = extractedText.split('\n').filter(line => line.trim());
      
      const children = [
        new Paragraph({
          text: metadata.Title || path.basename(inputPath, '.pdf'),
          heading: HeadingLevel.HEADING_1,
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: `Converted from PDF - ${pageCount} pages`,
              italics: true,
              size: 20,
              color: '666666',
            }),
          ],
        }),
        new Paragraph({ text: '' }),
      ];

      // Add content paragraphs
      for (const line of textLines) {
        children.push(
          new Paragraph({
            children: [
              new TextRun({
                text: line,
                size: 24,
              }),
            ],
          })
        );
      }

      const doc = new Document({
        sections: [{
          properties: {},
          children,
        }],
      });

      const buffer = await Packer.toBuffer(doc);
      await fs.writeFile(outputPath, buffer);

      return {
        path: outputPath,
        pageCount,
        textLength: extractedText.length,
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
   * Extracts text content from PPTX slides and creates a PDF
   * @param {string} inputPath - Path to PPTX file
   * @param {string} outputPath - Path for PDF output
   * @returns {Promise<{path: string, pageCount: number}>}
   */
  async pptxToPdf(inputPath, outputPath) {
    try {
      const pptxBuffer = await fs.readFile(inputPath);
      const zip = await JSZip.loadAsync(pptxBuffer);
      
      // Extract slide content from PPTX
      const slides = [];
      const slideFiles = Object.keys(zip.files)
        .filter(name => name.match(/ppt\/slides\/slide\d+\.xml/))
        .sort((a, b) => {
          const numA = parseInt(a.match(/slide(\d+)\.xml/)[1]);
          const numB = parseInt(b.match(/slide(\d+)\.xml/)[1]);
          return numA - numB;
        });

      for (const slideFile of slideFiles) {
        const content = await zip.file(slideFile).async('string');
        // Extract text from XML
        const textMatches = content.match(/<a:t>([^<]*)<\/a:t>/g) || [];
        const slideText = textMatches
          .map(match => match.replace(/<a:t>|<\/a:t>/g, ''))
          .filter(text => text.trim())
          .join('\n');
        slides.push(slideText);
      }

      // Create PDF with slide content
      const pdf = await PDFDocument.create();
      const font = await pdf.embedFont(StandardFonts.Helvetica);
      const boldFont = await pdf.embedFont(StandardFonts.HelveticaBold);

      const pageWidth = 842; // A4 landscape
      const pageHeight = 595;
      const margin = 50;
      const contentWidth = pageWidth - (margin * 2);
      const fontSize = 12;
      const titleFontSize = 20;
      const lineHeight = fontSize * 1.5;

      // Title page
      const titlePage = pdf.addPage([pageWidth, pageHeight]);
      const title = path.basename(inputPath, path.extname(inputPath));
      titlePage.drawText(title, {
        x: margin,
        y: pageHeight - 100,
        size: 28,
        font: boldFont,
        color: rgb(0.1, 0.1, 0.1),
      });
      titlePage.drawText(`${slides.length} slides`, {
        x: margin,
        y: pageHeight - 140,
        size: 16,
        font,
        color: rgb(0.5, 0.5, 0.5),
      });
      titlePage.drawText('Converted from PowerPoint', {
        x: margin,
        y: pageHeight - 170,
        size: 12,
        font,
        color: rgb(0.5, 0.5, 0.5),
      });

      // Create a page for each slide
      for (let i = 0; i < slides.length; i++) {
        const page = pdf.addPage([pageWidth, pageHeight]);
        const slideText = slides[i];
        
        // Draw slide number
        page.drawText(`Slide ${i + 1}`, {
          x: margin,
          y: pageHeight - margin,
          size: titleFontSize,
          font: boldFont,
          color: rgb(0.2, 0.2, 0.2),
        });

        // Draw slide border
        page.drawRectangle({
          x: margin - 10,
          y: 30,
          width: contentWidth + 20,
          height: pageHeight - 80,
          borderColor: rgb(0.85, 0.85, 0.85),
          borderWidth: 1,
        });

        // Draw slide content
        if (slideText) {
          const lines = slideText.split('\n');
          let currentY = pageHeight - margin - 40;

          for (const line of lines) {
            if (currentY < margin + lineHeight) break;

            // Word wrap long lines
            const words = line.split(' ');
            let currentLine = '';

            for (const word of words) {
              const testLine = currentLine ? `${currentLine} ${word}` : word;
              const textWidth = font.widthOfTextAtSize(testLine, fontSize);

              if (textWidth > contentWidth && currentLine) {
                page.drawText(currentLine, {
                  x: margin,
                  y: currentY,
                  size: fontSize,
                  font,
                  color: rgb(0, 0, 0),
                });
                currentY -= lineHeight;
                currentLine = word;
              } else {
                currentLine = testLine;
              }
            }

            if (currentLine) {
              page.drawText(currentLine, {
                x: margin,
                y: currentY,
                size: fontSize,
                font,
                color: rgb(0, 0, 0),
              });
              currentY -= lineHeight;
            }
          }
        } else {
          page.drawText('[No text content on this slide]', {
            x: margin,
            y: pageHeight / 2,
            size: fontSize,
            font,
            color: rgb(0.6, 0.6, 0.6),
          });
        }
      }

      const pdfBytes = await pdf.save();
      await fs.writeFile(outputPath, pdfBytes);

      return {
        path: outputPath,
        pageCount: slides.length + 1, // Including title page
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
      const buffer = await fs.readFile(inputPath);
      
      // Use mammoth to extract text from DOCX
      const result = await mammoth.extractRawText({ buffer });
      const text = result.value;
      const warnings = result.messages;

      if (warnings.length > 0) {
        console.log('DOCX extraction warnings:', warnings);
      }

      await fs.writeFile(outputPath, text, 'utf8');

      return {
        path: outputPath,
        text,
        charCount: text.length,
        wordCount: text.split(/\s+/).filter(w => w).length,
      };
    } catch (error) {
      throw AppError.internal(`DOCX text extraction failed: ${error.message}`);
    }
  }

  /**
   * Convert DOCX to HTML
   * @param {string} inputPath - Path to DOCX file
   * @param {string} outputPath - Path for HTML output
   * @returns {Promise<{path: string, html: string}>}
   */
  async docxToHtml(inputPath, outputPath) {
    try {
      const buffer = await fs.readFile(inputPath);
      
      // Use mammoth to convert DOCX to HTML
      const result = await mammoth.convertToHtml({ buffer });
      const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${path.basename(inputPath, '.docx')}</title>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1, h2, h3 { color: #333; }
    p { margin: 1em 0; }
  </style>
</head>
<body>
${result.value}
</body>
</html>`;

      await fs.writeFile(outputPath, html, 'utf8');

      return {
        path: outputPath,
        html: result.value,
      };
    } catch (error) {
      throw AppError.internal(`DOCX to HTML conversion failed: ${error.message}`);
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
