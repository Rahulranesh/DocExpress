/**
 * Authentication Controller
 */

const authService = require('../services/authService');
const { successResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * Register new user
 * POST /api/auth/register
 */
const register = catchAsync(async (req, res) => {
  const { name, email, password } = req.body;

  const result = await authService.register({ name, email, password });

  successResponse(res, result, 'Registration successful', 201);
});

/**
 * Login user
 * POST /api/auth/login
 */
const login = catchAsync(async (req, res) => {
  const { email, password } = req.body;

  const result = await authService.login({ email, password });

  successResponse(res, result, 'Login successful');
});

/**
 * Get current user profile
 * GET /api/auth/me
 */
const getProfile = catchAsync(async (req, res) => {
  const user = await authService.getUserById(req.userId);

  successResponse(res, { user });
});

/**
 * Update current user profile
 * PATCH /api/auth/me
 */
const updateProfile = catchAsync(async (req, res) => {
  const updates = req.body;

  const user = await authService.updateProfile(req.userId, updates);

  successResponse(res, { user }, 'Profile updated successfully');
});

/**
 * Change password
 * POST /api/auth/change-password
 */
const changePassword = catchAsync(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  const result = await authService.changePassword(req.userId, {
    currentPassword,
    newPassword,
  });

  successResponse(res, { token: result.token }, 'Password changed successfully');
});

/**
 * Logout (client-side token removal, optional server-side handling)
 * POST /api/auth/logout
 */
const logout = catchAsync(async (req, res) => {
  // For stateless JWT, logout is primarily client-side
  // Could implement token blacklist here if needed
  // TODO: Implement token blacklist for enhanced security

  successResponse(res, null, 'Logged out successfully');
});

/**
 * Refresh token (optional)
 * POST /api/auth/refresh
 */
const refreshToken = catchAsync(async (req, res) => {
  const { generateToken } = require('../middleware/auth');

  // Generate new token for current user
  const token = generateToken(req.userId);

  successResponse(res, { token }, 'Token refreshed');
});

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
  logout,
  refreshToken,
};
