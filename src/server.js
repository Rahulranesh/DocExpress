/**
 * DocXpress API Server
 * Backend with MongoDB authentication and document conversions
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

// Import database connection
const connectDB = require('./config/database');

// Import routes
const routes = require('./routes');

// Import error handling middleware
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Create Express app
const app = express();

// Environment configuration
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Security middleware
app.use(helmet());

// CORS configuration - allow all origins for API access with necessary methods
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parsing middleware with larger limits for file uploads
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

// Request logging in development
if (NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
  });
}

// API routes
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
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

// 404 handler for undefined routes
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// Connect to MongoDB and start server
const startServer = async () => {
  try {
    // Connect to MongoDB
    await connectDB();

    // Start server
    app.listen(PORT, () => {
      console.log('🚀 DocXpress API Server');
      console.log(`📍 Server running on port ${PORT}`);
      console.log(`📍 Environment: ${NODE_ENV}`);
      console.log(`📍 API Base URL: http://localhost:${PORT}/api`);
      console.log('\n✅ Available features:');
      console.log('   • User Authentication (Register/Login)');
      console.log('   • Account Management (Update/Delete)');
      console.log('   • DOCX → PDF');
      console.log('   • PPTX → PDF');
      console.log('   • PDF → DOCX');
      console.log('   • PDF → PPTX');
      console.log('   • Extract Images from PDF');
      console.log('\n📋 Auth Endpoints:');
      console.log('   POST /api/auth/register - Register new user');
      console.log('   POST /api/auth/login - Login user');
      console.log('   GET  /api/auth/me - Get current user (protected)');
      console.log('   PUT  /api/auth/profile - Update profile (protected)');
      console.log('   PUT  /api/auth/change-password - Change password (protected)');
      console.log('   DELETE /api/auth/account - Delete account (protected)');
      console.log('   POST /api/auth/rate-app - Rate the app (protected)');
      console.log('   GET  /api/auth/average-rating - Get average app rating (public)');
      console.log('\n📋 Conversion Endpoints:');
      console.log('   GET  /api/health - Health check');
      console.log('   GET  /api/simple-convert/health - Conversion service health');
      console.log('   POST /api/simple-convert/docx-to-pdf - Convert DOCX to PDF');
      console.log('   POST /api/simple-convert/pptx-to-pdf - Convert PPTX to PDF');
      console.log('   POST /api/simple-convert/pdf-to-docx - Convert PDF to DOCX');
      console.log('   POST /api/simple-convert/pdf-to-pptx - Convert PDF to PPTX');
      console.log('   POST /api/simple-convert/pdf-extract-images - Extract images from PDF\n');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  process.exit(0);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  if (NODE_ENV === 'production') {
    gracefulShutdown('UNHANDLED_REJECTION');
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

module.exports = app;
