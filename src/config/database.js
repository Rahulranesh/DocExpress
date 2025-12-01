/**
 * Database Configuration
 * MongoDB connection setup and management
 */

const mongoose = require('mongoose');

// Default configuration
const defaultConfig = {
  maxPoolSize: 10,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  family: 4, // Use IPv4
};

/**
 * Connect to MongoDB
 * @param {string} uri - MongoDB connection URI
 * @param {Object} options - Additional mongoose options
 * @returns {Promise<mongoose.Connection>}
 */
const connect = async (uri, options = {}) => {
  const connectionUri = uri || process.env.MONGODB_URI || 'mongodb://localhost:27017/docxpress';
  const connectionOptions = { ...defaultConfig, ...options };

  try {
    await mongoose.connect(connectionUri, connectionOptions);
    console.log('✅ MongoDB connected successfully');
    return mongoose.connection;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    throw error;
  }
};

/**
 * Disconnect from MongoDB
 * @returns {Promise<void>}
 */
const disconnect = async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB disconnected');
  } catch (error) {
    console.error('Error disconnecting from MongoDB:', error.message);
    throw error;
  }
};

/**
 * Get connection status
 * @returns {string}
 */
const getStatus = () => {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };
  return states[mongoose.connection.readyState] || 'unknown';
};

/**
 * Check if connected
 * @returns {boolean}
 */
const isConnected = () => {
  return mongoose.connection.readyState === 1;
};

/**
 * Setup connection event handlers
 */
const setupEventHandlers = () => {
  mongoose.connection.on('connected', () => {
    console.log('Mongoose connected to database');
  });

  mongoose.connection.on('error', (err) => {
    console.error('Mongoose connection error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.log('Mongoose disconnected from database');
  });

  // Handle process termination
  process.on('SIGINT', async () => {
    await disconnect();
    process.exit(0);
  });
};

module.exports = {
  connect,
  disconnect,
  getStatus,
  isConnected,
  setupEventHandlers,
  connection: mongoose.connection,
};
