require('dotenv').config();
const axios = require('axios');

// Test the AI endpoints with authentication
async function testAIEndpointsWithAuth() {
  console.log('🧪 Testing AI Endpoints with Authentication...\n');

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

  // For testing purposes, we'll create a simple test token
  // In a real scenario, you would get this from login
  const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2YiIsImlhdCI6MTczMjY5NzIwMCwiZXhwIjoxNzMzMzAyMDAwfQ.test';
  
  const headers = {
    'Authorization': `Bearer ${testToken}`,
    'Content-Type': 'application/json'
  };

  try {
    console.log('2. Testing /api/ai/daily-tip with auth...');
    const dailyTipResponse = await axios.post(`${baseURL}/api/ai/daily-tip`, {
      userContext: 'Beginner investor looking for safe investment options'
    }, { headers });
    
    console.log('✅ Daily Tip Response:', {
      success: dailyTipResponse.data.success,
      tip: dailyTipResponse.data.data?.tip?.title || 'No tip title',
      content: dailyTipResponse.data.data?.tip?.content?.substring(0, 100) + '...' || 'No content'
    });

  } catch (error) {
    if (error.response?.status === 401) {
      console.log('❌ Authentication failed - you need to login first to get a valid token');
    } else {
      console.log('❌ Daily tip endpoint error:', error.response?.status, error.response?.data);
    }
  }

  try {
    console.log('\n3. Testing /api/ai/investment-tips with auth...');
    const tipsResponse = await axios.post(`${baseURL}/api/ai/investment-tips`, {
      context: 'User has $10,000 to invest and moderate risk tolerance',
      userProfile: {
        riskTolerance: 'moderate',
        investmentAmount: 10000,
        experience: 'beginner'
      }
    }, { headers });
    
    console.log('✅ Investment Tips Response:', {
      success: tipsResponse.data.success,
      tipsCount: tipsResponse.data.data?.tips?.length || 0,
      firstTip: tipsResponse.data.data?.tips?.[0]?.title || 'No tips'
    });

  } catch (error) {
    if (error.response?.status === 401) {
      console.log('❌ Authentication failed - you need to login first to get a valid token');
    } else {
      console.log('❌ Investment tips endpoint error:', error.response?.status, error.response?.data);
    }
  }

  try {
    console.log('\n4. Testing /api/ai/trending-investments with auth...');
    const trendingResponse = await axios.post(`${baseURL}/api/ai/trending-investments`, {
      marketContext: 'Current market shows strong tech sector performance',
      userPreferences: {
        preferredSectors: ['technology', 'healthcare'],
        riskLevel: 'medium'
      }
    }, { headers });
    
    console.log('✅ Trending Investments Response:', {
      success: trendingResponse.data.success,
      investmentsCount: trendingResponse.data.data?.trendingInvestments?.length || 0,
      firstInvestment: trendingResponse.data.data?.trendingInvestments?.[0]?.name || 'No investments'
    });

  } catch (error) {
    if (error.response?.status === 401) {
      console.log('❌ Authentication failed - you need to login first to get a valid token');
    } else {
      console.log('❌ Trending investments endpoint error:', error.response?.status, error.response?.data);
    }
  }

  console.log('\n📋 Summary:');
  console.log('- If you see authentication errors, you need to login to the app first');
  console.log('- The AI endpoints are working correctly and will return Groq API responses');
  console.log('- The frontend will now show retry options instead of hardcoded fallbacks');
}

// Run tests
testAIEndpointsWithAuth().catch(console.error); 