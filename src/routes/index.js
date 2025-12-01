/**
 * Routes Index - combines all route modules
 */

const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./authRoutes');
const noteRoutes = require('./noteRoutes');
const fileRoutes = require('./fileRoutes');
const conversionRoutes = require('./conversionRoutes');
const pdfRoutes = require('./pdfRoutes');
const compressionRoutes = require('./compressionRoutes');
const jobRoutes = require('./jobRoutes');
const adminRoutes = require('./adminRoutes');

// Root API endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to DocXpress API',
    version: '1.0.0',
    documentation: '/api/health',
  });
});

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'DocXpress API is running',
    timestamp: new Date().toISOString(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/notes', noteRoutes);
router.use('/files', fileRoutes);
router.use('/convert', conversionRoutes);
router.use('/pdf', pdfRoutes);
router.use('/compress', compressionRoutes);
router.use('/jobs', jobRoutes);
router.use('/admin', adminRoutes);

module.exports = router;
