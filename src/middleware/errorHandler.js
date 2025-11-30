const AppError = require('../utils/AppError');
const { errorResponse } = require('../utils/response');

// Handle Mongoose CastError (invalid ObjectId)
const handleCastError = (err) => {
  const message = `Invalid ${err.path}: ${err.value}`;
  return AppError.badRequest(message, 'INVALID_ID');
};

// Handle Mongoose duplicate key error
const handleDuplicateKeyError = (err) => {
  const field = Object.keys(err.keyValue)[0];
  const message = `${field} already exists`;
  return AppError.conflict(message, 'DUPLICATE_KEY');
};

// Handle Mongoose validation error
const handleValidationError = (err) => {
  const errors = Object.values(err.errors).map((e) => e.message);
  const message = errors.join('. ');
  return AppError.badRequest(message, 'VALIDATION_ERROR');
};

// Handle JWT errors
const handleJWTError = () => {
  return AppError.unauthorized('Invalid token. Please log in again.', 'INVALID_TOKEN');
};

const handleJWTExpiredError = () => {
  return AppError.unauthorized('Token expired. Please log in again.', 'TOKEN_EXPIRED');
};

// Handle Multer errors
const handleMulterError = (err) => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return AppError.tooLarge('File size exceeds the allowed limit');
  }
  if (err.code === 'LIMIT_FILE_COUNT') {
    return AppError.badRequest('Too many files uploaded', 'TOO_MANY_FILES');
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return AppError.badRequest('Unexpected file field', 'UNEXPECTED_FIELD');
  }
  return AppError.badRequest(err.message, 'UPLOAD_ERROR');
};

// Development error response (include stack trace)
const sendErrorDev = (err, res) => {
  return res.status(err.statusCode).json({
    success: false,
    error: {
      message: err.message,
      code: err.code,
      stack: err.stack,
    },
    status: err.status,
  });
};

// Production error response (hide implementation details)
const sendErrorProd = (err, res) => {
  // Operational/trusted error: send message to client
  if (err.isOperational) {
    return errorResponse(res, err.message, err.statusCode, err.code);
  }

  // Programming/unknown error: don't leak details
  console.error('ERROR:', err);
  return errorResponse(res, 'Something went wrong', 500, 'INTERNAL_ERROR');
};

// Main error handling middleware
const errorHandler = (err, req, res, next) => {
  // Default values
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Log error in development
  if (process.env.NODE_ENV === 'development') {
    console.error('Error:', err);
  }

  // Handle specific error types
  let error = { ...err, message: err.message, name: err.name };

  // Mongoose CastError
  if (err.name === 'CastError') {
    error = handleCastError(err);
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    error = handleDuplicateKeyError(err);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    error = handleValidationError(err);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = handleJWTError();
  }

  if (err.name === 'TokenExpiredError') {
    error = handleJWTExpiredError();
  }

  // Multer errors
  if (err.name === 'MulterError') {
    error = handleMulterError(err);
  }

  // Send response based on environment
  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(error, res);
  } else {
    sendErrorProd(error, res);
  }
};

// Catch async errors wrapper
const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// 404 handler for undefined routes
const notFoundHandler = (req, res, next) => {
  next(AppError.notFound(`Cannot ${req.method} ${req.originalUrl}`));
};

module.exports = {
  errorHandler,
  catchAsync,
  notFoundHandler,
};
