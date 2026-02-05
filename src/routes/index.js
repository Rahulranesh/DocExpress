/**
 * Routes Index - Simplified for conversion-only backend
 */

const express = require('express');
const router = express.Router();

// Import only the simple conversion routes
const simpleConversionRoutes = require('./simpleConversionRoutes');

// Root API endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to DocXpress Simple Conversion API',
    version: '2.0.0',
    features: [
      'DOCX → PDF',
      'PPTX → PDF',
      'PDF → DOCX',
      'PDF → PPTX',
      'Extract Images from PDF',
    ],
    documentation: '/api/simple-convert/health',
  });
});

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'DocXpress Simple Conversion API is running',
    timestamp: new Date().toISOString(),
    features: [
      'DOCX → PDF',
      'PPTX → PDF',
      'PDF → DOCX',
      'PDF → PPTX',
      'Extract Images from PDF',
    ],
  });
});

// Mount simple conversion routes (no auth, no MongoDB)
router.use('/simple-convert', simpleConversionRoutes);

module.exports = router;
