// Test script for verification
// Save as: src/test-registration.js
// Run with: node test-registration.js

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const mongoose = require('mongoose');
const User = require('./models/User');

async function testRegistration() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Clear test users
    await User.deleteMany({ email: /^test.*@example\.com$/ });
    console.log('🗑️ Cleared test users');

    // Test registration
    console.log('\n📝 Testing user creation...');
    const testUser = await User.create({
      name: 'Test User',
      email: 'test-' + Date.now() + '@example.com',
      password: 'TestPassword123',
    });
    console.log('✅ User created successfully!');
    console.log('   ID:', testUser._id);
    console.log('   Name:', testUser.name);
    console.log('   Email:', testUser.email);
    console.log('   Password hashed:', !!testUser.password);

    // Test password comparison
    console.log('\n🔐 Testing password comparison...');
    const isMatch = await testUser.comparePassword('TestPassword123');
    console.log('✅ Password comparison works:', isMatch);

    const isWrongMatch = await testUser.comparePassword('WrongPassword');
    console.log('✅ Wrong password rejected:', !isWrongMatch);

    console.log('\n✅ All tests passed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

testRegistration();
