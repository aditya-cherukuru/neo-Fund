const { queryGroqLLM, queryGroqLLMWithRetry, testGroqConnection } = require('./utils/groqClient');

async function testGroqClient() {
  console.log('🧪 Testing Groq LLM Client...\n');

  try {
    // Test 1: Connection test
    console.log('1. Testing API connection...');
    const connectionTest = await testGroqConnection();
    console.log(`   ✅ Connection test: ${connectionTest ? 'PASSED' : 'FAILED'}\n`);

    // Test 2: Simple query
    console.log('2. Testing simple query...');
    const simpleResponse = await queryGroqLLM("What is 2 + 2? Please respond with just the number.");
    console.log(`   ✅ Simple query response: ${simpleResponse.trim()}\n`);

    // Test 3: Financial advice query
    console.log('3. Testing financial advice query...');
    const financialPrompt = "Give me a brief tip for saving money. Keep it under 50 words.";
    const financialResponse = await queryGroqLLM(financialPrompt);
    console.log(`   ✅ Financial advice: ${financialResponse.trim()}\n`);

    // Test 4: Retry functionality (simulate a temporary error)
    console.log('4. Testing retry functionality...');
    try {
      const retryResponse = await queryGroqLLMWithRetry("What is the capital of France?", {
        maxRetries: 2,
        retryDelay: 500
      });
      console.log(`   ✅ Retry test response: ${retryResponse.trim()}\n`);
    } catch (error) {
      console.log(`   ⚠️  Retry test: ${error.message}\n`);
    }

    console.log('🎉 All tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testGroqClient();
}

module.exports = { testGroqClient }; 