const fetch = require('node-fetch');

const baseUrl = 'http://localhost:3000/api';

async function testPerformance() {
  console.log('🚀 Testing Investment History API Performance...\n');
  
  const testCases = [
    { symbol: 'AAPL', type: 'Stocks' },
    { symbol: 'BTCUSDT', type: 'Crypto' },
    { symbol: 'MSFT', type: 'Stocks' },
    { symbol: 'ETHUSDT', type: 'Crypto' },
  ];
  
  for (const testCase of testCases) {
    console.log(`📊 Testing ${testCase.symbol} (${testCase.type})...`);
    
    const startTime = Date.now();
    
    try {
      const response = await fetch(`${baseUrl}/investment/historical-data`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          symbol: testCase.symbol,
          type: testCase.type,
          interval: 'monthly'
        })
      });
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      if (response.ok) {
        const data = await response.json();
        console.log(`✅ Success: ${duration}ms - ${data.data?.source || 'Unknown source'}`);
        
        if (data.data?.metrics) {
          console.log(`   📈 Total Return: ${data.data.metrics.totalReturn?.toFixed(2)}%`);
          console.log(`   📊 Data Points: ${data.data.metrics.dataPoints}`);
        }
      } else {
        console.log(`❌ Failed: ${duration}ms - Status: ${response.status}`);
      }
    } catch (error) {
      const endTime = Date.now();
      const duration = endTime - startTime;
      console.log(`❌ Error: ${duration}ms - ${error.message}`);
    }
    
    console.log('');
    
    // Wait a bit between tests
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('🔄 Testing cache performance (second request should be faster)...\n');
  
  // Test cache performance
  const cacheTest = { symbol: 'AAPL', type: 'Stocks' };
  console.log(`📊 Testing cache for ${cacheTest.symbol}...`);
  
  // First request
  const start1 = Date.now();
  try {
    const response1 = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ symbol: cacheTest.symbol, type: cacheTest.type, interval: 'monthly' })
    });
    const duration1 = Date.now() - start1;
    console.log(`   First request: ${duration1}ms`);
    
    // Second request (should be cached)
    const start2 = Date.now();
    const response2 = await fetch(`${baseUrl}/investment/historical-data`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ symbol: cacheTest.symbol, type: cacheTest.type, interval: 'monthly' })
    });
    const duration2 = Date.now() - start2;
    console.log(`   Second request (cached): ${duration2}ms`);
    
    const improvement = ((duration1 - duration2) / duration1 * 100).toFixed(1);
    console.log(`   🚀 Performance improvement: ${improvement}% faster`);
    
  } catch (error) {
    console.log(`❌ Cache test failed: ${error.message}`);
  }
  
  console.log('\n✨ Performance test completed!');
}

// Run the test
testPerformance().catch(console.error); 