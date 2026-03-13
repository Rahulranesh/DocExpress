/**
 * Routes Index - API routes with authentication
 */

const express = require('express');
const router = express.Router();

// Import routes
const authRoutes = require('./authRoutes');
const simpleConversionRoutes = require('./simpleConversionRoutes');

// Root API endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to DocXpress API',
    version: '2.0.0',
    features: [
      'User Authentication',
      'Account Management',
      'DOCX → PDF',
      'PPTX → PDF',
      'PDF → DOCX',
      'PDF → PPTX',
      'Extract Images from PDF',
    ],
    endpoints: {
      auth: '/api/auth',
      conversions: '/api/simple-convert',
    },
  });
});

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'DocXpress API is running',
    timestamp: new Date().toISOString(),
    database: 'MongoDB Connected',
    features: [
      'User Authentication',
      'Account Management',
      'DOCX → PDF',
      'PPTX → PDF',
      'PDF → DOCX',
      'PDF → PPTX',
      'Extract Images from PDF',
    ],
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/simple-convert', simpleConversionRoutes);

module.exports = router;
