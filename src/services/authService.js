const User = require('../models/User');
const AppError = require('../utils/AppError');
const { generateToken } = require('../middleware/auth');
const { USER_ROLES } = require('../utils/constants');

/**
 * Register a new user
 */
const register = async ({ name, email, password, role = USER_ROLES.USER }) => {
  // Check if user already exists
  const existingUser = await User.findOne({ email: email.toLowerCase() });
  if (existingUser) {
    throw AppError.conflict('Email already registered');
  }

  // Create new user (password hashing happens in pre-save hook)
  const user = new User({
    name,
    email: email.toLowerCase(),
    passwordHash: password,
    role,
  });

  await user.save();

  // Generate token
  const token = generateToken(user._id);

  return {
    user: user.toJSON(),
    token,
  };
};

/**
 * Login user with email and password
 */
const login = async ({ email, password }) => {
  // Find user with password field
  const user = await User.findByEmailWithPassword(email.toLowerCase());

  if (!user) {
    throw AppError.unauthorized('Invalid email or password');
  }

  // Check password
  const isPasswordValid = await user.comparePassword(password);
  if (!isPasswordValid) {
    throw AppError.unauthorized('Invalid email or password');
  }

  // Generate token
  const token = generateToken(user._id);

  return {
    user: user.toJSON(),
    token,
  };
};

/**
 * Get user by ID
 */
const getUserById = async (userId) => {
  const user = await User.findById(userId);
  if (!user) {
    throw AppError.notFound('User not found');
  }
  return user;
};

/**
 * Get user by email
 */
const getUserByEmail = async (email) => {
  const user = await User.findOne({ email: email.toLowerCase() });
  if (!user) {
    throw AppError.notFound('User not found');
  }
  return user;
};

/**
 * Update user profile
 */
const updateProfile = async (userId, updates) => {
  const allowedUpdates = ['name'];
  const updateData = {};

  // Filter to allowed fields only
  for (const key of allowedUpdates) {
    if (updates[key] !== undefined) {
      updateData[key] = updates[key];
    }
  }

  if (Object.keys(updateData).length === 0) {
    throw AppError.badRequest('No valid fields to update');
  }

  const user = await User.findByIdAndUpdate(userId, updateData, {
    new: true,
    runValidators: true,
  });

  if (!user) {
    throw AppError.notFound('User not found');
  }

  return user;
};

/**
 * Change user password
 */
const changePassword = async (userId, { currentPassword, newPassword }) => {
  const user = await User.findById(userId).select('+passwordHash');

  if (!user) {
    throw AppError.notFound('User not found');
  }

  // Verify current password
  const isPasswordValid = await user.comparePassword(currentPassword);
  if (!isPasswordValid) {
    throw AppError.unauthorized('Current password is incorrect');
  }

  // Update password
  user.passwordHash = newPassword;
  await user.save();

  // Generate new token after password change
  const token = generateToken(user._id);

  return { user: user.toJSON(), token };
};

/**
 * Get all users (admin only)
 */
const getAllUsers = async ({ page = 1, limit = 20 }) => {
  const skip = (page - 1) * limit;

  const [users, total] = await Promise.all([
    User.find()
      .select('name email role createdAt')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    User.countDocuments(),
  ]);

  return { users, total, page, limit };
};

/**
 * Delete user (admin only)
 */
const deleteUser = async (userId) => {
  const user = await User.findByIdAndDelete(userId);
  if (!user) {
    throw AppError.notFound('User not found');
  }
  return user;
};

module.exports = {
  register,
  login,
  getUserById,
  getUserByEmail,
  updateProfile,
  changePassword,
  getAllUsers,
  deleteUser,
};
