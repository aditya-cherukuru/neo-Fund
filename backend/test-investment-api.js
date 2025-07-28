const fetch = require('node-fetch');

async function testInvestmentAPI() {
  console.log('Testing Investment History API...\n');
  
  const baseUrl = 'http://localhost:3000/api';
  
  // Test 1: Search for symbols
  console.log('1. Testing symbol search for "AAPL"...');
  try {
    const searchResponse = await fetch(`${baseUrl}/investment/search-symbols`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query: 'AAPL',
        type: 'Stocks'
      })
    });
    
    const searchData = await searchResponse.json();
    console.log('Search response status:', searchData.status);
    if (searchData.status === 'success') {
      console.log('Found', searchData.data.length, 'symbols');
    }
  } catch (error) {
    console.error('Search error:', error.message);
  }
  
  console.log('\n2. Testing historical data for "AAPL"...');
  try {
    const historyResponse = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        symbol: 'AAPL',
        type: 'Stocks',
        interval: 'monthly'
      })
    });
    
    const historyData = await historyResponse.json();
    console.log('History response status:', historyData.status);
    if (historyData.status === 'success') {
      console.log('✅ SUCCESS: Data fetched successfully');
      console.log('Data points:', historyData.data?.data?.length || 0);
      console.log('Symbol:', historyData.data?.symbol);
      console.log('Note:', historyData.data?.note || 'Real data');
      if (historyData.data?.metrics) {
        console.log('Current Price:', historyData.data.metrics.currentPrice);
        console.log('Total Return:', historyData.data.metrics.totalReturn?.toFixed(2) + '%');
      }
    } else {
      console.log('❌ ERROR:', historyData.message);
    }
  } catch (error) {
    console.error('History error:', error.message);
  }
  
  console.log('\n3. Testing with popular symbol "MSFT"...');
  try {
    const msftResponse = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        symbol: 'MSFT',
        type: 'Stocks',
        interval: 'monthly'
      })
    });
    
    const msftData = await msftResponse.json();
    console.log('MSFT response status:', msftData.status);
    if (msftData.status === 'success') {
      console.log('✅ SUCCESS: MSFT data fetched');
      console.log('Data points:', msftData.data?.data?.length || 0);
      console.log('Note:', msftData.data?.note || 'Real data');
    } else {
      console.log('❌ ERROR:', msftData.message);
    }
  } catch (error) {
    console.error('MSFT error:', error.message);
  }
  
  console.log('\n4. Testing with invalid symbol "TS"...');
  try {
    const invalidResponse = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        symbol: 'TS',
        type: 'Stocks',
        interval: 'monthly'
      })
    });
    
    const invalidData = await invalidResponse.json();
    console.log('TS response status:', invalidData.status);
    if (invalidData.status === 'error') {
      console.log('❌ EXPECTED ERROR:', invalidData.message);
      console.log('This is expected behavior for invalid symbols');
    }
  } catch (error) {
    console.error('TS error:', error.message);
  }
  
  console.log('\n5. Testing crypto symbol "BTCUSDT"...');
  try {
    const cryptoResponse = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        symbol: 'BTCUSDT',
        type: 'Crypto',
        interval: 'monthly'
      })
    });
    
    const cryptoData = await cryptoResponse.json();
    console.log('Crypto response status:', cryptoData.status);
    if (cryptoData.status === 'success') {
      console.log('✅ SUCCESS: Crypto data fetched');
      console.log('Data points:', cryptoData.data?.data?.length || 0);
    } else {
      console.log('❌ ERROR:', cryptoData.message);
    }
  } catch (error) {
    console.error('Crypto error:', error.message);
  }
}

testInvestmentAPI().catch(console.error); 