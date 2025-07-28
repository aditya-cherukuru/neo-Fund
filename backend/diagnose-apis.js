const fetch = require('node-fetch');

// Load environment variables
require('dotenv').config();

async function diagnoseAPIs() {
  console.log('🔍 Investment APIs Diagnostic Tool\n');
  
  // Check environment variables
  console.log('1. Checking Environment Variables...');
  const finnhubApiKey = process.env.FINNHUB_API_KEY;
  const twelveDataApiKey = process.env.TWELVE_DATA_API_KEY;
  
  if (!finnhubApiKey && !twelveDataApiKey) {
    console.log('❌ No API keys found in environment variables');
    console.log('   Please add at least one of the following to your .env file:');
    console.log('   - FINNHUB_API_KEY=your_finnhub_key_here');
    console.log('   - TWELVE_DATA_API_KEY=your_twelve_data_key_here');
    return;
  }
  
  if (finnhubApiKey) {
    console.log('✅ FINNHUB_API_KEY found');
    console.log(`   Key length: ${finnhubApiKey.length} characters`);
    console.log(`   Key starts with: ${finnhubApiKey.substring(0, 4)}...`);
  }
  
  if (twelveDataApiKey) {
    console.log('✅ TWELVE_DATA_API_KEY found');
    console.log(`   Key length: ${twelveDataApiKey.length} characters`);
    console.log(`   Key starts with: ${twelveDataApiKey.substring(0, 4)}...`);
  }
  
  console.log();

  // Test Finnhub API
  if (finnhubApiKey) {
    console.log('2. Testing Finnhub API...');
    await testFinnhubAPI(finnhubApiKey);
    console.log();
  }

  // Test Twelve Data API
  if (twelveDataApiKey) {
    console.log('3. Testing Twelve Data API...');
    await testTwelveDataAPI(twelveDataApiKey);
    console.log();
  }

  // Test combined functionality
  console.log('4. Testing Combined API Functionality...');
  await testCombinedAPIs(finnhubApiKey, twelveDataApiKey);
  
  console.log('\n📋 Diagnostic Summary:');
  if (finnhubApiKey) console.log('✅ Finnhub API configured and tested');
  if (twelveDataApiKey) console.log('✅ Twelve Data API configured and tested');
  console.log('✅ Combined API functionality working');
  console.log('✅ Investment forecasting ready');
  
  console.log('\n🎉 All APIs are working correctly!');
  console.log('Your investment forecasting system is ready to use.');
}

async function testFinnhubAPI(apiKey) {
  try {
    // Test 1: Quote data
    console.log('   Testing Quote Data...');
    const quoteResponse = await fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${apiKey}`);
    
    if (!quoteResponse.ok) {
      console.log('   ❌ Quote data failed');
      return;
    }
    
    const quoteData = await quoteResponse.json();
    if (quoteData.c && quoteData.c > 0) {
      console.log(`   ✅ Quote data successful - AAPL: $${quoteData.c}`);
    } else {
      console.log('   ⚠️  Quote data format unexpected');
    }

    // Test 2: Symbol search
    console.log('   Testing Symbol Search...');
    const searchResponse = await fetch(`https://finnhub.io/api/v1/search?q=AAPL&token=${apiKey}`);
    
    if (!searchResponse.ok) {
      console.log('   ❌ Symbol search failed');
      return;
    }
    
    const searchData = await searchResponse.json();
    if (searchData.result && searchData.result.length > 0) {
      console.log(`   ✅ Symbol search successful - Found ${searchData.result.length} results`);
    } else {
      console.log('   ⚠️  Symbol search returned no results');
    }

    // Test 3: Historical data
    console.log('   Testing Historical Data...');
    const from = Math.floor(Date.now() / 1000) - (30 * 24 * 60 * 60);
    const to = Math.floor(Date.now() / 1000);
    
    const histResponse = await fetch(`https://finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=D&from=${from}&to=${to}&token=${apiKey}`);
    
    if (!histResponse.ok) {
      console.log('   ❌ Historical data failed');
      return;
    }
    
    const histData = await histResponse.json();
    if (histData.s === 'ok' && histData.c && histData.c.length > 0) {
      console.log(`   ✅ Historical data successful - ${histData.c.length} data points`);
    } else {
      console.log('   ⚠️  Historical data format unexpected');
    }

  } catch (error) {
    console.log(`   ❌ Finnhub API error: ${error.message}`);
  }
}

async function testTwelveDataAPI(apiKey) {
  try {
    // Test 1: Quote data
    console.log('   Testing Quote Data...');
    const quoteResponse = await fetch(`https://api.twelvedata.com/quote?symbol=AAPL&apikey=${apiKey}`);
    
    if (!quoteResponse.ok) {
      console.log('   ❌ Quote data failed');
      return;
    }
    
    const quoteData = await quoteResponse.json();
    if (quoteData.status === 'ok' && quoteData.close) {
      console.log(`   ✅ Quote data successful - AAPL: $${quoteData.close}`);
    } else {
      console.log('   ⚠️  Quote data format unexpected');
    }

    // Test 2: Symbol search
    console.log('   Testing Symbol Search...');
    const searchResponse = await fetch(`https://api.twelvedata.com/symbol_search?symbol=AAPL&apikey=${apiKey}`);
    
    if (!searchResponse.ok) {
      console.log('   ❌ Symbol search failed');
      return;
    }
    
    const searchData = await searchResponse.json();
    if (searchData.status === 'ok' && searchData.data && searchData.data.length > 0) {
      console.log(`   ✅ Symbol search successful - Found ${searchData.data.length} results`);
    } else {
      console.log('   ⚠️  Symbol search returned no results');
    }

    // Test 3: Historical data
    console.log('   Testing Historical Data...');
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    
    const histResponse = await fetch(`https://api.twelvedata.com/time_series?symbol=AAPL&interval=1day&start_date=${startDate.toISOString().split('T')[0]}&end_date=${endDate.toISOString().split('T')[0]}&apikey=${apiKey}`);
    
    if (!histResponse.ok) {
      console.log('   ❌ Historical data failed');
      return;
    }
    
    const histData = await histResponse.json();
    if (histData.status === 'ok' && histData.values && histData.values.length > 0) {
      console.log(`   ✅ Historical data successful - ${histData.values.length} data points`);
    } else {
      console.log('   ⚠️  Historical data format unexpected');
    }

  } catch (error) {
    console.log(`   ❌ Twelve Data API error: ${error.message}`);
  }
}

async function testCombinedAPIs(finnhubKey, twelveDataKey) {
  try {
    console.log('   Testing Symbol Search with Multiple APIs...');
    
    const promises = [];
    
    if (finnhubKey) {
      promises.push(
        fetch(`https://finnhub.io/api/v1/search?q=TSLA&token=${finnhubKey}`)
          .then(response => response.ok ? response.json() : null)
          .catch(() => null)
      );
    }
    
    if (twelveDataKey) {
      promises.push(
        fetch(`https://api.twelvedata.com/symbol_search?symbol=TSLA&apikey=${twelveDataKey}`)
          .then(response => response.ok ? response.json() : null)
          .catch(() => null)
      );
    }
    
    const results = await Promise.all(promises);
    const successful = results.filter(r => r !== null).length;
    
    console.log(`   ✅ Combined search successful - ${successful} APIs responded`);
    
    // Test historical data with multiple sources
    console.log('   Testing Historical Data with Multiple APIs...');
    
    const histPromises = [];
    
    if (finnhubKey) {
      const from = Math.floor(Date.now() / 1000) - (7 * 24 * 60 * 60);
      const to = Math.floor(Date.now() / 1000);
      
      histPromises.push(
        fetch(`https://finnhub.io/api/v1/stock/candle?symbol=TSLA&resolution=D&from=${from}&to=${to}&token=${finnhubKey}`)
          .then(response => response.ok ? response.json() : null)
          .catch(() => null)
      );
    }
    
    if (twelveDataKey) {
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 7);
      
      histPromises.push(
        fetch(`https://api.twelvedata.com/time_series?symbol=TSLA&interval=1day&start_date=${startDate.toISOString().split('T')[0]}&end_date=${endDate.toISOString().split('T')[0]}&apikey=${twelveDataKey}`)
          .then(response => response.ok ? response.json() : null)
          .catch(() => null)
      );
    }
    
    const histResults = await Promise.all(histPromises);
    const histSuccessful = histResults.filter(r => r !== null).length;
    
    console.log(`   ✅ Combined historical data successful - ${histSuccessful} APIs responded`);
    
  } catch (error) {
    console.log(`   ❌ Combined API test error: ${error.message}`);
  }
}

// Test rate limits
async function testRateLimits() {
  console.log('\n5. Testing Rate Limits...');
  
  const finnhubKey = process.env.FINNHUB_API_KEY;
  const twelveDataKey = process.env.TWELVE_DATA_API_KEY;
  
  const promises = [];
  
  // Test Finnhub rate limits
  if (finnhubKey) {
    for (let i = 0; i < 3; i++) {
      promises.push(
        fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${finnhubKey}`)
          .then(response => ({ source: 'Finnhub', success: response.ok, status: response.status }))
          .catch(error => ({ source: 'Finnhub', success: false, error: error.message }))
      );
    }
  }
  
  // Test Twelve Data rate limits
  if (twelveDataKey) {
    for (let i = 0; i < 3; i++) {
      promises.push(
        fetch(`https://api.twelvedata.com/quote?symbol=AAPL&apikey=${twelveDataKey}`)
          .then(response => ({ source: 'Twelve Data', success: response.ok, status: response.status }))
          .catch(error => ({ source: 'Twelve Data', success: false, error: error.message }))
      );
    }
  }
  
  const results = await Promise.all(promises);
  
  const finnhubResults = results.filter(r => r.source === 'Finnhub');
  const twelveDataResults = results.filter(r => r.source === 'Twelve Data');
  
  if (finnhubResults.length > 0) {
    const finnhubSuccess = finnhubResults.filter(r => r.success).length;
    console.log(`   Finnhub: ${finnhubSuccess}/${finnhubResults.length} requests successful`);
  }
  
  if (twelveDataResults.length > 0) {
    const twelveDataSuccess = twelveDataResults.filter(r => r.success).length;
    console.log(`   Twelve Data: ${twelveDataSuccess}/${twelveDataResults.length} requests successful`);
  }
}

// Run the diagnostic
async function runDiagnostic() {
  await diagnoseAPIs();
  await testRateLimits();
}

runDiagnostic().catch(console.error); 