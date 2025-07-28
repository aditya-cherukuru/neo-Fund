const fetch = require('node-fetch');

async function testForecastIntegration() {
  const baseUrl = 'http://localhost:3000/api';
  
  console.log('🧪 Testing Forecast Integration...\n');
  
  // Test 1: Create a forecast
  console.log('1. Testing forecast creation...');
  try {
    const forecastData = {
      symbol: 'AAPL',
      type: 'Stocks',
      investmentAmount: 1000,
      duration: 10,
      riskLevel: 'Medium',
      historicalData: {
        symbol: 'AAPL',
        data: [
          { date: '2024-01-01', close: 150.0 },
          { date: '2024-01-02', close: 151.0 }
        ],
        metrics: {
          totalReturn: 5.2,
          volatility: 12.5,
          bestPeriod: { date: '2024-01-02', return: 5.2 }
        }
      },
      metrics: {
        totalReturn: 5.2,
        volatility: 12.5,
        bestPeriod: { date: '2024-01-02', return: 5.2 }
      },
      insights: [
        'The investment has shown positive growth over the analyzed period.',
        'Moderate volatility suggests stable but variable performance.'
      ],
      generatedAt: new Date().toISOString(),
      reportType: 'investment_history'
    };
    
    const createResponse = await fetch(`${baseUrl}/forecast`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token' // You'll need a real token
      },
      body: JSON.stringify(forecastData)
    });
    
    console.log('   Status:', createResponse.status);
    const createResult = await createResponse.text();
    console.log('   Response:', createResult);
    
  } catch (error) {
    console.log('   Error:', error.message);
  }
  
  // Test 2: Get forecasts
  console.log('\n2. Testing forecast retrieval...');
  try {
    const getResponse = await fetch(`${baseUrl}/forecast`, {
      headers: {
        'Authorization': 'Bearer test-token' // You'll need a real token
      }
    });
    
    console.log('   Status:', getResponse.status);
    const getResult = await getResponse.text();
    console.log('   Response:', getResult);
    
  } catch (error) {
    console.log('   Error:', error.message);
  }
  
  console.log('\n✅ Test completed!');
}

testForecastIntegration().catch(console.error); 