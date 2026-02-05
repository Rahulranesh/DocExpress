/**
 * Simple Conversion Routes - Direct file upload for conversions
 * No MongoDB, no authentication - just simple conversions
 */

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for file uploads with larger limits
const upload = multer({
  dest: 'uploads/temp/',
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB
  },
});

// Import conversion services
const documentService = require('../services/documentService');
const pdfService = require('../services/pdfService');

/**
 * POST /api/simple-convert/docx-to-pdf
 * Convert DOCX to PDF - accepts file upload directly
 */
router.post('/docx-to-pdf', upload.single('file'), async (req, res) => {
  let inputPath = null;
  let outputPath = null;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' },
      });
    }

    inputPath = req.file.path;
    console.log('📄 Converting DOCX to PDF:', req.file.originalname);

    // Convert DOCX to PDF
    const tempOutput = path.join('uploads/temp', `converted_${Date.now()}.pdf`);
    await documentService.docxToPdf(inputPath, tempOutput);
    outputPath = tempOutput;

    // Send the PDF file
    res.download(outputPath, req.file.originalname.replace(/\.(docx?|DOCX?)$/, '.pdf'), (err) => {
      // Cleanup files after download
      if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
      if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);
      
      if (err) {
        console.error('❌ Download error:', err);
      }
    });
  } catch (error) {
    console.error('❌ DOCX to PDF conversion failed:', error);
    
    // Cleanup on error
    if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
    if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);

    res.status(500).json({
      success: false,
      error: {
        message: error.message || 'DOCX to PDF conversion failed',
        code: 'CONVERSION_ERROR',
      },
    });
  }
});

/**
 * POST /api/simple-convert/pptx-to-pdf
 * Convert PPTX to PDF - accepts file upload directly
 */
router.post('/pptx-to-pdf', upload.single('file'), async (req, res) => {
  let inputPath = null;
  let outputPath = null;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' },
      });
    }

    inputPath = req.file.path;
    console.log('📄 Converting PPTX to PDF:', req.file.originalname);

    // Convert PPTX to PDF
    const tempOutput = path.join('uploads/temp', `converted_${Date.now()}.pdf`);
    await documentService.pptxToPdf(inputPath, tempOutput);
    outputPath = tempOutput;

    // Send the PDF file
    res.download(outputPath, req.file.originalname.replace(/\.(pptx?|PPTX?)$/, '.pdf'), (err) => {
      // Cleanup files after download
      if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
      if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);
      
      if (err) {
        console.error('❌ Download error:', err);
      }
    });
  } catch (error) {
    console.error('❌ PPTX to PDF conversion failed:', error);
    
    // Cleanup on error
    if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
    if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);

    res.status(500).json({
      success: false,
      error: {
        message: error.message || 'PPTX to PDF conversion failed',
        code: 'CONVERSION_ERROR',
      },
    });
  }
});

/**
 * POST /api/simple-convert/pdf-to-docx
 * Convert PDF to DOCX - accepts file upload directly
 */
router.post('/pdf-to-docx', upload.single('file'), async (req, res) => {
  let inputPath = null;
  let outputPath = null;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' },
      });
    }

    inputPath = req.file.path;
    console.log('📄 Converting PDF to DOCX:', req.file.originalname);

    // Convert PDF to DOCX
    const tempOutput = path.join('uploads/temp', `converted_${Date.now()}.docx`);
    await documentService.pdfToDocx(inputPath, tempOutput);
    outputPath = tempOutput;

    // Send the DOCX file
    res.download(outputPath, req.file.originalname.replace(/\.pdf$/i, '.docx'), (err) => {
      // Cleanup files after download
      if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
      if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);
      
      if (err) {
        console.error('❌ Download error:', err);
      }
    });
  } catch (error) {
    console.error('❌ PDF to DOCX conversion failed:', error);
    
    // Cleanup on error
    if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
    if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);

    res.status(500).json({
      success: false,
      error: {
        message: error.message || 'PDF to DOCX conversion failed',
        code: 'CONVERSION_ERROR',
      },
    });
  }
});

/**
 * POST /api/simple-convert/pdf-to-pptx
 * Convert PDF to PPTX - accepts file upload directly
 */
router.post('/pdf-to-pptx', upload.single('file'), async (req, res) => {
  let inputPath = null;
  let outputPath = null;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' },
      });
    }

    inputPath = req.file.path;
    console.log('📄 Converting PDF to PPTX:', req.file.originalname);

    // Convert PDF to PPTX
    const tempOutput = path.join('uploads/temp', `converted_${Date.now()}.pptx`);
    await documentService.pdfToPptx(inputPath, tempOutput);
    outputPath = tempOutput;

    // Send the PPTX file
    res.download(outputPath, req.file.originalname.replace(/\.pdf$/i, '.pptx'), (err) => {
      // Cleanup files after download
      if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
      if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);
      
      if (err) {
        console.error('❌ Download error:', err);
      }
    });
  } catch (error) {
    console.error('❌ PDF to PPTX conversion failed:', error);
    
    // Cleanup on error
    if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
    if (outputPath && fs.existsSync(outputPath)) fs.unlinkSync(outputPath);

    res.status(500).json({
      success: false,
      error: {
        message: error.message || 'PDF to PPTX conversion failed',
        code: 'CONVERSION_ERROR',
      },
    });
  }
});

/**
 * POST /api/simple-convert/pdf-extract-images
 * Extract images from PDF - accepts file upload directly
 */
router.post('/pdf-extract-images', upload.single('file'), async (req, res) => {
  let inputPath = null;
  let imagePaths = [];

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' },
      });
    }

    inputPath = req.file.path;
    console.log('📄 Extracting images from PDF:', req.file.originalname);

    // Extract images from PDF
    const outputDir = 'uploads/temp';
    imagePaths = await pdfService.extractImages(inputPath, outputDir);

    if (imagePaths.length === 0) {
      return res.json({
        success: true,
        data: {
          images: [],
          count: 0,
          message: 'No images found in PDF',
        },
      });
    }

    // Return image paths (in production, you'd return URLs or base64)
    res.json({
      success: true,
      data: {
        images: imagePaths,
        count: imagePaths.length,
        message: `Extracted ${imagePaths.length} images`,
      },
    });

    // Cleanup input file
    if (inputPath && fs.existsSync(inputPath)) {
      setTimeout(() => fs.unlinkSync(inputPath), 5000); // Delay cleanup
    }
  } catch (error) {
    console.error('❌ PDF extract images failed:', error);
    
    // Cleanup on error
    if (inputPath && fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
    imagePaths.forEach(img => {
      if (fs.existsSync(img)) fs.unlinkSync(img);
    });

    res.status(500).json({
      success: false,
      error: {
        message: error.message || 'Failed to extract images from PDF',
        code: 'EXTRACTION_ERROR',
      },
    });
  }
});

/**
 * GET /api/simple-convert/health
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Simple conversion service is running',
    features: [
      'DOCX → PDF',
      'PPTX → PDF',
      'PDF → DOCX',
      'PDF → PPTX',
      'PDF → Extract Images',
    ],
  });
});

module.exports = router;
