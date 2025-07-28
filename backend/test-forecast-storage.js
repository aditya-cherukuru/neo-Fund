const fetch = require('node-fetch');

const baseUrl = 'http://localhost:3000/api';

async function testForecastStorage() {
  console.log('🧪 Testing Forecast Storage System...\n');

  try {
    // First, let's test if the server is running
    console.log('1. Testing server connectivity...');
    const healthResponse = await fetch(`${baseUrl}/health`);
    if (healthResponse.ok) {
      console.log('✅ Server is running');
    } else {
      console.log('❌ Server is not responding');
      return;
    }

    // Test 2: Create a sample investment history report
    console.log('\n2. Testing investment history report creation...');
    
    const sampleReport = {
      symbol: 'AAPL',
      type: 'Stocks',
      investmentAmount: 5000,
      duration: 5,
      riskLevel: 'Medium',
      historicalData: {
        symbol: 'AAPL',
        data: [
          { date: '2023-01-01', close: 150.0 },
          { date: '2023-02-01', close: 155.0 },
          { date: '2023-03-01', close: 160.0 },
        ],
        metrics: {
          totalReturn: 15.5,
          volatility: 12.3,
          currentPrice: 175.0,
          dataPoints: 12,
        }
      },
      metrics: {
        totalReturn: 15.5,
        volatility: 12.3,
        currentPrice: 175.0,
        dataPoints: 12,
      },
      insights: [
        'Sample analysis based on 5 years of historical data.',
        'The investment has shown positive growth over the analyzed period.',
        'Moderate volatility suggests stable but variable performance.',
      ],
      generatedAt: new Date().toISOString(),
      reportType: 'investment_history',
    };

    console.log('📊 Sample report data:', JSON.stringify(sampleReport, null, 2));

    const createResponse = await fetch(`${baseUrl}/forecast`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token' // You'll need a real token
      },
      body: JSON.stringify(sampleReport)
    });

    console.log('📤 Create response status:', createResponse.status);
    
    if (createResponse.ok) {
      const createResult = await createResponse.json();
      console.log('✅ Report created successfully:', createResult.status);
      console.log('📋 Created report ID:', createResult.data?._id);
    } else {
      const errorText = await createResponse.text();
      console.log('❌ Failed to create report:', errorText);
    }

    // Test 3: Retrieve all forecasts
    console.log('\n3. Testing forecast retrieval...');
    
    const getResponse = await fetch(`${baseUrl}/forecast`, {
      method: 'GET',
      headers: {
        'Authorization': 'Bearer test-token' // You'll need a real token
      }
    });

    console.log('📥 Get response status:', getResponse.status);
    
    if (getResponse.ok) {
      const getResult = await getResponse.json();
      console.log('✅ Retrieved forecasts successfully:', getResult.status);
      console.log('📊 Total forecasts found:', getResult.data?.length || 0);
      
      if (getResult.data && getResult.data.length > 0) {
        console.log('📋 First forecast structure:', Object.keys(getResult.data[0]));
        console.log('📋 First forecast symbol:', getResult.data[0].symbol);
        console.log('📋 First forecast amount:', getResult.data[0].investmentAmount);
      }
    } else {
      const errorText = await getResponse.text();
      console.log('❌ Failed to retrieve forecasts:', errorText);
    }

    console.log('\n🎉 Forecast storage test completed!');

  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
  }
}

// Run the test
testForecastStorage().catch(console.error); 