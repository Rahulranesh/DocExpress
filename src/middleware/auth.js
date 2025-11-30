const jwt = require('jsonwebtoken');
const User = require('../models/User');
const AppError = require('../utils/AppError');

/**
 * Extract token from Authorization header
 */
const extractToken = (req) => {
  if (req.headers.authorization?.startsWith('Bearer ')) {
    return req.headers.authorization.split(' ')[1];
  }
  return null;
};

/**
 * Authenticate user via JWT
 */
const authenticate = async (req, res, next) => {
  try {
    const token = extractToken(req);

    if (!token) {
      return next(AppError.unauthorized('No token provided'));
    }

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return next(AppError.unauthorized('Token has expired'));
      }
      if (err.name === 'JsonWebTokenError') {
        return next(AppError.unauthorized('Invalid token'));
      }
      return next(AppError.unauthorized('Token verification failed'));
    }

    // Check if user still exists
    const user = await User.findById(decoded.userId);
    if (!user) {
      return next(AppError.unauthorized('User no longer exists'));
    }

    // Attach user to request
    req.user = user;
    req.userId = user._id;

    next();
  } catch (error) {
    next(AppError.unauthorized('Authentication failed'));
  }
};

/**
 * Optional authentication - attaches user if token present, continues otherwise
 */
const optionalAuth = async (req, res, next) => {
  try {
    const token = extractToken(req);

    if (!token) {
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);

    if (user) {
      req.user = user;
      req.userId = user._id;
    }

    next();
  } catch (error) {
    // Token invalid but optional, continue without user
    next();
  }
};

/**
 * Require admin role
 */
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return next(AppError.unauthorized('Authentication required'));
  }

  if (req.user.role !== 'admin') {
    return next(AppError.forbidden('Admin access required'));
  }

  next();
};

/**
 * Require specific roles
 */
const requireRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(AppError.unauthorized('Authentication required'));
    }

    if (!roles.includes(req.user.role)) {
      return next(AppError.forbidden(`Required roles: ${roles.join(', ')}`));
    }

    next();
  };
};

/**
 * Generate JWT token for user
 */
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

/**
 * Decode token without verification (for inspection)
 */
const decodeToken = (token) => {
  try {
    return jwt.decode(token);
  } catch {
    return null;
  }
};

module.exports = {
  authenticate,
  optionalAuth,
  requireAdmin,
  requireRoles,
  generateToken,
  decodeToken,
  extractToken,
};
