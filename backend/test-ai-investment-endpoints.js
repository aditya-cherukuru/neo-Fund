const axios = require('axios');

// Test configuration
const BASE_URL = 'http://localhost:3000';
const TEST_TOKEN = 'your-test-jwt-token-here'; // Replace with actual test token

// Test the new AI investment endpoints
async function testAIInvestmentEndpoints() {
  console.log('🧪 Testing AI Investment Endpoints...\n');

  const headers = {
    'Authorization': `Bearer ${TEST_TOKEN}`,
    'Content-Type': 'application/json'
  };

  try {
    // Test 1: Get daily investment tip
    console.log('1. Testing Daily Investment Tip...');
    const dailyTipResponse = await axios.post(`${BASE_URL}/api/ai/daily-tip`, {
      userContext: 'Beginner investor looking for safe investment options'
    }, { headers });
    
    console.log('✅ Daily Tip Response:', {
      success: dailyTipResponse.data.success,
      tip: dailyTipResponse.data.data?.tip?.title || 'No tip title',
      content: dailyTipResponse.data.data?.tip?.content?.substring(0, 100) + '...' || 'No content'
    });

    // Test 2: Get investment tips
    console.log('\n2. Testing Investment Tips...');
    const tipsResponse = await axios.post(`${BASE_URL}/api/ai/investment-tips`, {
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

    // Test 3: Get trending investments
    console.log('\n3. Testing Trending Investments...');
    const trendingResponse = await axios.post(`${BASE_URL}/api/ai/trending-investments`, {
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

    console.log('\n🎉 All tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', {
      message: error.response?.data?.message || error.message,
      status: error.response?.status,
      data: error.response?.data
    });
  }
}

// Test error handling
async function testErrorHandling() {
  console.log('\n🧪 Testing Error Handling...\n');

  const headers = {
    'Authorization': `Bearer ${TEST_TOKEN}`,
    'Content-Type': 'application/json'
  };

  try {
    // Test with invalid data
    console.log('1. Testing with invalid data...');
    const invalidResponse = await axios.post(`${BASE_URL}/api/ai/daily-tip`, {
      userContext: 123 // Should be string
    }, { headers });
    
    console.log('❌ Should have failed but got:', invalidResponse.data);

  } catch (error) {
    console.log('✅ Correctly handled invalid data:', {
      status: error.response?.status,
      message: error.response?.data?.message
    });
  }

  try {
    // Test without authentication
    console.log('\n2. Testing without authentication...');
    const noAuthResponse = await axios.post(`${BASE_URL}/api/ai/daily-tip`, {
      userContext: 'test'
    });
    
    console.log('❌ Should have failed but got:', noAuthResponse.data);

  } catch (error) {
    console.log('✅ Correctly handled missing authentication:', {
      status: error.response?.status,
      message: error.response?.data?.message
    });
  }
}

// Run tests
async function runTests() {
  console.log('🚀 Starting AI Investment Endpoints Tests\n');
  
  await testAIInvestmentEndpoints();
  await testErrorHandling();
  
  console.log('\n✨ Test suite completed!');
}

// Export for use in other test files
module.exports = {
  testAIInvestmentEndpoints,
  testErrorHandling,
  runTests
};

// Run if this file is executed directly
if (require.main === module) {
  runTests().catch(console.error);
} 