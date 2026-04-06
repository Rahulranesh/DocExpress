/**
 * Authentication Controller
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');

const googleClient = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

const normalizeEmail = (email = '') => email.trim().toLowerCase();

/**
 * Generate JWT Token
 */
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

const formatUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

/**
 * @desc    Register new user
 * @route   POST /api/auth/register
 * @access  Public
 */
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    const normalizedEmail = normalizeEmail(email);

    // Validation
    if (!name || !normalizedEmail || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email and password',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: normalizedEmail }).collation({
      locale: 'en',
      strength: 2,
    });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message:
          'Email already registered. Please login or use Forgot Password to reset your password.',
        code: 'EMAIL_ALREADY_EXISTS',
      });
    }

    // Validate password strength
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters',
      });
    }

    // Create user
    const user = await User.create({
      name,
      email: normalizedEmail,
      password,
    });

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        token,
        user: formatUser(user),
      },
    });
  } catch (error) {
    console.error('Register error:', error);

    if (error?.code === 11000 && error?.keyPattern?.email) {
      return res.status(409).json({
        success: false,
        message:
          'Email already registered. Please login or use Forgot Password to reset your password.',
        code: 'EMAIL_ALREADY_EXISTS',
      });
    }

    res.status(500).json({
      success: false,
      message: error.message || 'Registration failed',
    });
  }
};

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = normalizeEmail(email);

    // Validation
    if (!normalizedEmail || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    // Find user and include password
    const user = await User.findOne({ email: normalizedEmail })
      .sort({ createdAt: -1 })
      .select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account has been deactivated',
      });
    }

    // Check password
    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Generate token
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: formatUser(user),
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
    });
  }
};

/**
 * @desc    Login or register user with Google
 * @route   POST /api/auth/google
 * @access  Public
 */
exports.googleLogin = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Google ID token is required',
      });
    }

    if (!process.env.GOOGLE_WEB_CLIENT_ID) {
      return res.status(500).json({
        success: false,
        message: 'Google login is not configured on server',
      });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_WEB_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    if (!payload || !payload.email || !payload.sub) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Google token payload',
      });
    }

    if (payload.email_verified === false) {
      return res.status(401).json({
        success: false,
        message: 'Google account email is not verified',
      });
    }

    const email = normalizeEmail(payload.email);
    let user = await User.findOne({ email });

    if (user) {
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Account has been deactivated',
        });
      }

      const updates = {};
      if (user.authProvider !== 'google') {
        updates.authProvider = 'google';
      }
      if (user.googleId !== payload.sub) {
        updates.googleId = payload.sub;
      }
      if (payload.name && payload.name !== user.name) {
        updates.name = payload.name;
      }

      if (Object.keys(updates).length > 0) {
        user = await User.findByIdAndUpdate(user._id, updates, {
          new: true,
          runValidators: true,
        });
      }
    } else {
      user = await User.create({
        name: payload.name || email.split('@')[0],
        email,
        authProvider: 'google',
        googleId: payload.sub,
        password: crypto.randomBytes(32).toString('hex'),
      });
    }

    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: 'Google login successful',
      data: {
        token,
        user: formatUser(user),
      },
    });
  } catch (error) {
    console.error('Google login error:', error);

    if (error?.code === 11000 && error?.keyPattern?.email) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered',
      });
    }

    res.status(401).json({
      success: false,
      message: 'Google authentication failed',
    });
  }
};

/**
 * @desc    Get current user
 * @route   GET /api/auth/me
 * @access  Private
 */
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        user: formatUser(user),
      },
    });
  } catch (error) {
    console.error('Get me error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user data',
    });
  }
};

/**
 * @desc    Update user profile
 * @route   PUT /api/auth/profile
 * @access  Private
 */
exports.updateProfile = async (req, res) => {
  try {
    const { name, email } = req.body;
    const normalizedEmail = email ? normalizeEmail(email) : null;

    const fieldsToUpdate = {};
    if (name) fieldsToUpdate.name = name;
    if (normalizedEmail) fieldsToUpdate.email = normalizedEmail;

    // Check if email is already taken
    if (normalizedEmail) {
      const existingUser = await User.findOne({
        email: normalizedEmail,
        _id: { $ne: req.user.id },
      });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'Email already in use',
        });
      }
    }

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: formatUser(user),
      },
    });
  } catch (error) {
    console.error('Update profile error:', error);

    if (error?.code === 11000 && error?.keyPattern?.email) {
      return res.status(409).json({
        success: false,
        message: 'Email already in use',
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
    });
  }
};

/**
 * @desc    Forgot password (reset by email)
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
exports.forgotPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    const normalizedEmail = normalizeEmail(email);

    if (!normalizedEmail || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and new password',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters',
      });
    }

    const user = await User.findOne({ email: normalizedEmail })
      .sort({ createdAt: -1 })
      .select('+password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No account found for this email',
      });
    }

    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account has been deactivated',
      });
    }

    user.password = newPassword;
    user.passwordResetToken = null;
    user.passwordResetExpires = null;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password reset successful. Please login with your new password.',
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reset password',
    });
  }
};

/**
 * @desc    Change password
 * @route   PUT /api/auth/change-password
 * @access  Private
 */
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide current and new password',
      });
    }

    // Get user with password
    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    const isPasswordMatch = await user.comparePassword(currentPassword);
    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password',
    });
  }
};

/**
 * @desc    Delete user account
 * @route   DELETE /api/auth/account
 * @access  Private
 */
exports.deleteAccount = async (req, res) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide your password to confirm account deletion',
      });
    }

    // Get user with password
    const user = await User.findById(req.user.id).select('+password');

    // Verify password
    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password',
      });
    }

    // Delete user
    await User.findByIdAndDelete(req.user.id);

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete account',
    });
  }
};

/**
 * @desc    Rate the app
 * @route   POST /api/auth/rate-app
 * @access  Private
 */
exports.rateApp = async (req, res) => {
  try {
    const { rating } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5',
      });
    }

    // Update user rating
    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        appRating: rating,
        appRatingDate: new Date(),
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Thank you for rating DocXpress!',
      data: {
        rating: user.appRating,
        ratedAt: user.appRatingDate,
      },
    });
  } catch (error) {
    console.error('Rate app error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save rating',
    });
  }
};

/**
 * @desc    Get average app rating
 * @route   GET /api/auth/average-rating
 * @access  Public
 */
exports.getAverageRating = async (req, res) => {
  try {
    const stats = await User.aggregate([
      {
        $match: { appRating: { $ne: null } },
      },
      {
        $group: {
          _id: null,
          averageRating: { $avg: '$appRating' },
          totalRatings: { $sum: 1 },
        },
      },
    ]);

    const result = stats[0] || { averageRating: 0, totalRatings: 0 };

    res.status(200).json({
      success: true,
      data: {
        averageRating: Math.round(result.averageRating * 10) / 10, // Round to 1 decimal
        totalRatings: result.totalRatings,
      },
    });
  } catch (error) {
    console.error('Get average rating error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get average rating',
    });
  }
};
