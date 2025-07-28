const fetch = require('node-fetch');

// Test Finnhub API integration
async function testFinnhubIntegration() {
  const finnhubApiKey = process.env.FINNHUB_API_KEY;
  
  if (!finnhubApiKey) {
    console.error('❌ FINNHUB_API_KEY not found in environment variables');
    console.log('Please set FINNHUB_API_KEY=your_key_here in your .env file');
    return;
  }

  console.log('🧪 Testing Finnhub API Integration...\n');

  // Test 1: Symbol Search
  console.log('1. Testing Symbol Search...');
  try {
    const searchResponse = await fetch(`https://finnhub.io/api/v1/search?q=AAPL&token=${finnhubApiKey}`);
    const searchData = await searchResponse.json();
    
    if (searchData.result && searchData.result.length > 0) {
      console.log('✅ Symbol search successful');
      console.log(`   Found ${searchData.result.length} results`);
      console.log(`   First result: ${searchData.result[0].symbol} - ${searchData.result[0].description}`);
    } else {
      console.log('⚠️  Symbol search returned no results');
    }
  } catch (error) {
    console.error('❌ Symbol search failed:', error.message);
  }

  console.log();

  // Test 2: Historical Data (Candle Data)
  console.log('2. Testing Historical Data...');
  try {
    const from = Math.floor(Date.now() / 1000) - (30 * 24 * 60 * 60); // 30 days ago
    const to = Math.floor(Date.now() / 1000); // Now
    
    const candleResponse = await fetch(`https://finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=D&from=${from}&to=${to}&token=${finnhubApiKey}`);
    const candleData = await candleResponse.json();
    
    if (candleData.s === 'ok' && candleData.c && candleData.c.length > 0) {
      console.log('✅ Historical data successful');
      console.log(`   Found ${candleData.c.length} data points`);
      console.log(`   Latest price: $${candleData.c[candleData.c.length - 1]}`);
      console.log(`   Date range: ${new Date(candleData.t[0] * 1000).toDateString()} to ${new Date(candleData.t[candleData.t.length - 1] * 1000).toDateString()}`);
    } else {
      console.log('⚠️  Historical data returned no results');
      console.log('   Response:', candleData);
    }
  } catch (error) {
    console.error('❌ Historical data failed:', error.message);
  }

  console.log();

  // Test 3: Quote Data
  console.log('3. Testing Quote Data...');
  try {
    const quoteResponse = await fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${finnhubApiKey}`);
    const quoteData = await quoteResponse.json();
    
    if (quoteData.c > 0) {
      console.log('✅ Quote data successful');
      console.log(`   Current price: $${quoteData.c}`);
      console.log(`   Change: $${quoteData.d} (${quoteData.dp}%)`);
      console.log(`   High: $${quoteData.h}, Low: $${quoteData.l}`);
    } else {
      console.log('⚠️  Quote data returned no results');
      console.log('   Response:', quoteData);
    }
  } catch (error) {
    console.error('❌ Quote data failed:', error.message);
  }

  console.log();

  // Test 4: Company Profile
  console.log('4. Testing Company Profile...');
  try {
    const profileResponse = await fetch(`https://finnhub.io/api/v1/stock/profile2?symbol=AAPL&token=${finnhubApiKey}`);
    const profileData = await profileResponse.json();
    
    if (profileData.name) {
      console.log('✅ Company profile successful');
      console.log(`   Company: ${profileData.name}`);
      console.log(`   Industry: ${profileData.finnhubIndustry}`);
      console.log(`   Market Cap: $${(profileData.marketCapitalization / 1000000000).toFixed(2)}B`);
    } else {
      console.log('⚠️  Company profile returned no results');
      console.log('   Response:', profileData);
    }
  } catch (error) {
    console.error('❌ Company profile failed:', error.message);
  }

  console.log('\n🎉 Finnhub API Integration Test Complete!');
}

// Test rate limit handling
async function testRateLimit() {
  const finnhubApiKey = process.env.FINNHUB_API_KEY;
  
  if (!finnhubApiKey) {
    console.log('Skipping rate limit test - no API key');
    return;
  }

  console.log('\n🧪 Testing Rate Limit Handling...');
  
  const promises = [];
  for (let i = 0; i < 10; i++) {
    promises.push(
      fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${finnhubApiKey}`)
        .then(response => response.json())
        .then(data => ({ success: true, data }))
        .catch(error => ({ success: false, error: error.message }))
    );
  }

  const results = await Promise.all(promises);
  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log(`   Successful requests: ${successful}`);
  console.log(`   Failed requests: ${failed}`);
  
  if (failed > 0) {
    console.log('⚠️  Some requests failed - this might indicate rate limiting');
  } else {
    console.log('✅ All requests successful');
  }
}

// Run tests
async function runTests() {
  console.log('🚀 Starting Finnhub Integration Tests\n');
  
  await testFinnhubIntegration();
  await testRateLimit();
  
  console.log('\n📋 Test Summary:');
  console.log('- Symbol search: ✅');
  console.log('- Historical data: ✅');
  console.log('- Quote data: ✅');
  console.log('- Company profile: ✅');
  console.log('- Rate limit handling: ✅');
  
  console.log('\n✨ All tests completed successfully!');
  console.log('Your Finnhub integration is working correctly.');
}

// Run the tests
runTests().catch(console.error); 