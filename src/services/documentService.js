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
const AppError = require('../utils/AppError');

class DocumentService {
  /**
   * Sanitize text for pdf-lib (remove characters it can't encode)
   * @param {string} text - Text to sanitize
   * @returns {string} - Sanitized text
   */
  sanitizeTextForPdf(text) {
    if (!text) return '';
    return text
      .replace(/\t/g, '    ') // Replace tabs with 4 spaces
      .replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F-\x9F]/g, '') // Remove control characters
      .replace(/[^\x20-\x7E\xA0-\xFF\n\r]/g, ''); // Keep only printable characters
  }

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
      const text = this.sanitizeTextForPdf(result.value);
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
      const title = this.sanitizeTextForPdf(path.basename(inputPath, '.docx'));
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
            
            // Sanitize before drawing
            const sanitizedLine = this.sanitizeTextForPdf(currentLine);
            
            currentPage.drawText(sanitizedLine, {
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
          
          // Sanitize before drawing
          const sanitizedLine = this.sanitizeTextForPdf(currentLine);
          
          currentPage.drawText(sanitizedLine, {
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
   * Convert PDF to PPTX (without canvas - text-based conversion)
   * Each page becomes a slide with extracted text
   * @param {string} inputPath - Path to PDF file
   * @param {string} outputPath - Path for PPTX output
   * @returns {Promise<{path: string, slideCount: number}>}
   */
  async pdfToPptx(inputPath, outputPath) {
    try {
      // Try canvas-based approach first (renders pages as images)
      try {
        const pdfjsLib = require('pdfjs-dist/legacy/build/pdf.js');
        const Canvas = require('canvas');
        
        const pdfBytes = await fs.readFile(inputPath);
        
        const loadingTask = pdfjsLib.getDocument({
          data: new Uint8Array(pdfBytes),
          verbosity: 0,
        });
        
        const pdfDocument = await loadingTask.promise;
        const numPages = pdfDocument.numPages;

        const pptx = new PptxGenJS();
        pptx.layout = 'LAYOUT_16x9';
        pptx.title = path.basename(inputPath, '.pdf');

        for (let pageNum = 1; pageNum <= numPages; pageNum++) {
          const page = await pdfDocument.getPage(pageNum);
          
          const scale = 2.0;
          const viewport = page.getViewport({ scale });
          
          const canvas = Canvas.createCanvas(viewport.width, viewport.height);
          const context = canvas.getContext('2d');
          
          const renderContext = {
            canvasContext: context,
            viewport: viewport,
          };
          
          await page.render(renderContext).promise;
          
          const imageBuffer = canvas.toBuffer('image/png');
          const base64Image = `data:image/png;base64,${imageBuffer.toString('base64')}`;
          
          const slide = pptx.addSlide();
          
          const slideWidth = 10;
          const slideHeight = 5.625;
          
          const imgAspectRatio = viewport.width / viewport.height;
          const slideAspectRatio = slideWidth / slideHeight;
          
          let imgWidth, imgHeight, imgX, imgY;
          
          if (imgAspectRatio > slideAspectRatio) {
            imgWidth = slideWidth;
            imgHeight = slideWidth / imgAspectRatio;
            imgX = 0;
            imgY = (slideHeight - imgHeight) / 2;
          } else {
            imgHeight = slideHeight;
            imgWidth = slideHeight * imgAspectRatio;
            imgX = (slideWidth - imgWidth) / 2;
            imgY = 0;
          }
          
          slide.addImage({
            data: base64Image,
            x: imgX,
            y: imgY,
            w: imgWidth,
            h: imgHeight,
          });
        }

        await pptx.writeFile({ fileName: outputPath });

        return {
          path: outputPath,
          slideCount: numPages,
        };
      } catch (canvasError) {
        console.log('⚠️ Canvas not available, using text-based conversion (no page images)');
        
        // Fallback: Text-based conversion (no canvas needed)
        const pdfBuffer = await fs.readFile(inputPath);
        const pdfData = await pdfParse(pdfBuffer);
        const extractedText = pdfData.text || '';
        const pageCount = pdfData.numpages || 1;

        // Split text into pages (approximate)
        const lines = extractedText.split('\n').filter(line => line.trim());
        const linesPerSlide = Math.ceil(lines.length / pageCount) || 10;
        
        const pptx = new PptxGenJS();
        pptx.layout = 'LAYOUT_16x9';
        pptx.title = path.basename(inputPath, '.pdf');

        // Create title slide
        const titleSlide = pptx.addSlide();
        titleSlide.addText(path.basename(inputPath, '.pdf'), {
          x: 0.5,
          y: 2,
          w: '90%',
          h: 1.5,
          fontSize: 32,
          bold: true,
          align: 'center',
          color: '363636',
        });
        titleSlide.addText(`Converted from PDF - ${pageCount} pages`, {
          x: 0.5,
          y: 3.5,
          w: '90%',
          h: 0.5,
          fontSize: 16,
          align: 'center',
          color: '666666',
        });

        // Create content slides
        for (let i = 0; i < pageCount; i++) {
          const slide = pptx.addSlide();
          
          // Add slide number
          slide.addText(`Page ${i + 1}`, {
            x: 0.5,
            y: 0.3,
            w: '90%',
            h: 0.5,
            fontSize: 18,
            bold: true,
            color: '363636',
          });

          // Add content
          const startLine = i * linesPerSlide;
          const endLine = Math.min((i + 1) * linesPerSlide, lines.length);
          const slideText = lines.slice(startLine, endLine).join('\n');

          if (slideText) {
            slide.addText(slideText, {
              x: 0.5,
              y: 1,
              w: '90%',
              h: 4.5,
              fontSize: 12,
              valign: 'top',
              color: '000000',
            });
          } else {
            slide.addText('[No text content on this page]', {
              x: 0.5,
              y: 2.5,
              w: '90%',
              h: 0.5,
              fontSize: 14,
              align: 'center',
              color: '999999',
              italic: true,
            });
          }
        }

        await pptx.writeFile({ fileName: outputPath });

        return {
          path: outputPath,
          slideCount: pageCount + 1, // Including title slide
          note: 'Text-based conversion (canvas not available for page rendering)',
        };
      }
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
