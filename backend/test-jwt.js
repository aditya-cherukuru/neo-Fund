require('dotenv').config();
const { generateToken, verifyToken } = require('./utils/jwt');

console.log('🧪 Testing JWT Token Generation and Verification...\n');

// Check if JWT_SECRET is loaded
console.log('JWT_SECRET loaded:', process.env.JWT_SECRET ? 'Yes' : 'No');
console.log('JWT_SECRET preview:', process.env.JWT_SECRET ? process.env.JWT_SECRET.substring(0, 20) + '...' : 'Not set');

// Test token generation
console.log('\n1. Generating test token...');
const testUserId = '507f1f77bcf86cd799439011';
const token = generateToken(testUserId);
console.log('Token generated:', token ? 'Yes' : 'No');
console.log('Token preview:', token.substring(0, 50) + '...');

// Test token verification
console.log('\n2. Verifying test token...');
try {
  const decoded = verifyToken(token);
  console.log('Token verified successfully!');
  console.log('Decoded payload:', decoded);
  console.log('User ID from token:', decoded.id);
  console.log('User ID matches:', decoded.id === testUserId);
} catch (error) {
  console.log('❌ Token verification failed:', error.message);
}

console.log('\n✅ JWT test completed!'); 