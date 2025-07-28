require('dotenv').config();
const axios = require('axios');

// Test the AI endpoints directly
async function testAIEndpoints() {
  console.log('🧪 Testing AI Endpoints...\n');

  const baseURL = 'http://localhost:3000';
  
  // First, let's test if the server is running
  try {
    console.log('1. Testing server connection...');
    const healthCheck = await axios.get(`${baseURL}/api/health`);
    console.log('✅ Server is running');
  } catch (error) {
    console.log('❌ Server is not running. Please start the backend server first.');
    console.log('Run: cd backend && npm start');
    return;
  }

  // Test the AI endpoints without authentication first to see if they exist
  try {
    console.log('\n2. Testing AI endpoints (without auth)...');
    
    // Test daily tip endpoint
    console.log('Testing /api/ai/daily-tip...');
    const dailyTipResponse = await axios.post(`${baseURL}/api/ai/daily-tip`, {
      userContext: 'test'
    });
    console.log('❌ Should have failed with auth error, but got:', dailyTipResponse.status);
    
  } catch (error) {
    if (error.response?.status === 401) {
      console.log('✅ Daily tip endpoint exists and requires authentication');
    } else {
      console.log('❌ Daily tip endpoint error:', error.response?.status, error.response?.data);
    }
  }

  try {
    console.log('\n3. Testing /api/ai/investment-tips...');
    const tipsResponse = await axios.post(`${baseURL}/api/ai/investment-tips`, {
      context: 'test'
    });
    console.log('❌ Should have failed with auth error, but got:', tipsResponse.status);
    
  } catch (error) {
    if (error.response?.status === 401) {
      console.log('✅ Investment tips endpoint exists and requires authentication');
    } else {
      console.log('❌ Investment tips endpoint error:', error.response?.status, error.response?.data);
    }
  }

  try {
    console.log('\n4. Testing /api/ai/trending-investments...');
    const trendingResponse = await axios.post(`${baseURL}/api/ai/trending-investments`, {
      marketContext: 'test'
    });
    console.log('❌ Should have failed with auth error, but got:', trendingResponse.status);
    
  } catch (error) {
    if (error.response?.status === 401) {
      console.log('✅ Trending investments endpoint exists and requires authentication');
    } else {
      console.log('❌ Trending investments endpoint error:', error.response?.status, error.response?.data);
    }
  }

  console.log('\n📋 Summary:');
  console.log('- If you see "endpoint exists and requires authentication" messages, the endpoints are working');
  console.log('- If you see other errors, there might be an issue with the route registration');
  console.log('- To test with authentication, you need to get a valid JWT token from login');
}

// Test Groq API directly
async function testGroqAPI() {
  console.log('\n🧪 Testing Groq API directly...\n');

  const { queryGroqLLM } = require('./utils/groqClient');
  
  try {
    console.log('Testing Groq API connection...');
    const response = await queryGroqLLM("Hello, please respond with 'Groq API is working' if you can read this.");
    console.log('✅ Groq API Response:', response.substring(0, 100) + '...');
  } catch (error) {
    console.log('❌ Groq API Error:', error.message);
    console.log('Make sure GROQ_API_KEY is set in your .env file');
  }
}

// Run tests
async function runTests() {
  await testAIEndpoints();
  await testGroqAPI();
}

runTests().catch(console.error); 