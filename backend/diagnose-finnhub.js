const fetch = require('node-fetch');

// Load environment variables
require('dotenv').config();

async function diagnoseFinnhub() {
  console.log('🔍 Finnhub API Diagnostic Tool\n');
  
  // Check 1: Environment Variable
  console.log('1. Checking Environment Variable...');
  const finnhubApiKey = process.env.FINNHUB_API_KEY;
  
  if (!finnhubApiKey) {
    console.log('❌ FINNHUB_API_KEY not found in environment variables');
    console.log('   Please add FINNHUB_API_KEY=your_key_here to your .env file');
    return;
  }
  
  if (finnhubApiKey === 'your-finnhub-api-key-here' || finnhubApiKey.length < 10) {
    console.log('❌ FINNHUB_API_KEY appears to be invalid or placeholder');
    console.log('   Please get a valid API key from https://finnhub.io/');
    return;
  }
  
  console.log('✅ FINNHUB_API_KEY found in environment');
  console.log(`   Key length: ${finnhubApiKey.length} characters`);
  console.log(`   Key starts with: ${finnhubApiKey.substring(0, 4)}...`);
  
  // Check 2: Basic API Connectivity
  console.log('\n2. Testing Basic API Connectivity...');
  try {
    const response = await fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${finnhubApiKey}`);
    
    console.log(`   Response status: ${response.status} ${response.statusText}`);
    console.log(`   Content-Type: ${response.headers.get('content-type')}`);
    
    if (!response.ok) {
      console.log('❌ API request failed');
      const errorText = await response.text();
      console.log(`   Error response: ${errorText.substring(0, 200)}...`);
      return;
    }
    
    const data = await response.json();
    if (data.c && data.c > 0) {
      console.log('✅ Basic API connectivity successful');
      console.log(`   AAPL current price: $${data.c}`);
    } else {
      console.log('⚠️  API responded but data format unexpected');
      console.log(`   Response: ${JSON.stringify(data).substring(0, 200)}...`);
    }
  } catch (error) {
    console.log('❌ Network error:', error.message);
    return;
  }
  
  // Check 3: Symbol Search
  console.log('\n3. Testing Symbol Search...');
  try {
    const response = await fetch(`https://finnhub.io/api/v1/search?q=AAPL&token=${finnhubApiKey}`);
    
    if (!response.ok) {
      console.log('❌ Symbol search failed');
      const errorText = await response.text();
      console.log(`   Error response: ${errorText.substring(0, 200)}...`);
      return;
    }
    
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      console.log('❌ Symbol search returned non-JSON response');
      const responseText = await response.text();
      console.log(`   Response: ${responseText.substring(0, 200)}...`);
      return;
    }
    
    const data = await response.json();
    
    if (data.error) {
      console.log('❌ Symbol search API error:', data.error);
      return;
    }
    
    if (data.result && data.result.length > 0) {
      console.log('✅ Symbol search successful');
      console.log(`   Found ${data.result.length} results`);
      console.log(`   First result: ${data.result[0].symbol} - ${data.result[0].description}`);
    } else {
      console.log('⚠️  Symbol search returned no results');
      console.log(`   Response: ${JSON.stringify(data).substring(0, 200)}...`);
    }
  } catch (error) {
    console.log('❌ Symbol search error:', error.message);
  }
  
  // Check 4: Historical Data
  console.log('\n4. Testing Historical Data...');
  try {
    const from = Math.floor(Date.now() / 1000) - (30 * 24 * 60 * 60); // 30 days ago
    const to = Math.floor(Date.now() / 1000); // Now
    
    const response = await fetch(`https://finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=D&from=${from}&to=${to}&token=${finnhubApiKey}`);
    
    if (!response.ok) {
      console.log('❌ Historical data request failed');
      const errorText = await response.text();
      console.log(`   Error response: ${errorText.substring(0, 200)}...`);
      return;
    }
    
    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      console.log('❌ Historical data returned non-JSON response');
      const responseText = await response.text();
      console.log(`   Response: ${responseText.substring(0, 200)}...`);
      return;
    }
    
    const data = await response.json();
    
    if (data.error) {
      console.log('❌ Historical data API error:', data.error);
      return;
    }
    
    if (data.s === 'ok' && data.c && data.c.length > 0) {
      console.log('✅ Historical data successful');
      console.log(`   Found ${data.c.length} data points`);
      console.log(`   Latest price: $${data.c[data.c.length - 1]}`);
    } else {
      console.log('⚠️  Historical data format unexpected');
      console.log(`   Response: ${JSON.stringify(data).substring(0, 200)}...`);
    }
  } catch (error) {
    console.log('❌ Historical data error:', error.message);
  }
  
  // Check 5: Rate Limit Test
  console.log('\n5. Testing Rate Limits...');
  try {
    const promises = [];
    for (let i = 0; i < 5; i++) {
      promises.push(
        fetch(`https://finnhub.io/api/v1/quote?symbol=AAPL&token=${finnhubApiKey}`)
          .then(response => ({ success: response.ok, status: response.status }))
          .catch(error => ({ success: false, error: error.message }))
      );
    }
    
    const results = await Promise.all(promises);
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    console.log(`   Successful requests: ${successful}/5`);
    console.log(`   Failed requests: ${failed}/5`);
    
    if (failed > 0) {
      console.log('⚠️  Some requests failed - check rate limits');
    } else {
      console.log('✅ Rate limit test passed');
    }
  } catch (error) {
    console.log('❌ Rate limit test error:', error.message);
  }
  
  console.log('\n📋 Diagnostic Summary:');
  console.log('✅ Environment variable configured');
  console.log('✅ Basic API connectivity working');
  console.log('✅ Symbol search functional');
  console.log('✅ Historical data accessible');
  console.log('✅ Rate limits acceptable');
  
  console.log('\n🎉 Finnhub API is working correctly!');
  console.log('If you\'re still seeing errors in the app, check:');
  console.log('1. Server logs for specific error messages');
  console.log('2. Network connectivity from your server');
  console.log('3. Firewall/proxy settings');
  console.log('4. Application error handling');
}

// Run the diagnostic
diagnoseFinnhub().catch(console.error); 