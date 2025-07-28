const https = require('https');
const { logger } = require('./logger');

// Groq API configuration from environment variables
const GROQ_API_BASE_URL = 'api.groq.com';
const GROQ_MODEL = process.env.GROQ_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct';
const GROQ_API_KEY = process.env.GROQ_API_KEY;

// Validate required environment variables
if (!GROQ_API_KEY) {
  logger.error('GROQ_API_KEY is not defined in environment variables');
  throw new Error('GROQ_API_KEY environment variable is required');
}

/**
 * Send a request to Groq API
 * @param {string} prompt - The user prompt to send to the LLM
 * @returns {Promise<string>} - The AI model's response
 */
async function queryGroqLLM(prompt) {
  return new Promise((resolve, reject) => {
    // Validate input
    if (!prompt || typeof prompt !== 'string') {
      return reject(new Error('Invalid prompt: must be a non-empty string'));
    }

    // Prepare request data
    const requestData = JSON.stringify({
      model: GROQ_MODEL,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.7,
      max_tokens: 2048,
      top_p: 1,
      stream: false
    });

    // Request options
    const options = {
      hostname: GROQ_API_BASE_URL,
      port: 443,
      path: '/openai/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestData),
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'User-Agent': 'MintMate-Finance-App/1.0'
      }
    };

    logger.info('Sending request to Groq LLM', {
      model: GROQ_MODEL,
      promptLength: prompt.length,
      timestamp: new Date().toISOString()
    });

    // Make HTTPS request
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          // Handle different HTTP status codes
          if (res.statusCode === 200) {
            const response = JSON.parse(responseData);
            
            // Extract the AI response from the completion
            if (response.choices && response.choices.length > 0) {
              const aiResponse = response.choices[0].message?.content;
              
              if (aiResponse) {
                logger.info('Groq LLM response received successfully', {
                  responseLength: aiResponse.length,
                  model: response.model,
                  usage: response.usage
                });
                console.log('Groq LLM response:', aiResponse.substring(0, 200));
                return resolve(aiResponse);
              } else {
                console.error('No content in AI response:', response);
                return reject(new Error('No content in AI response'));
              }
            } else {
              console.error('No choices in API response:', response);
              return reject(new Error('No choices in API response'));
            }
          } else if (res.statusCode === 401) {
            logger.error('Groq API authentication failed', { statusCode: res.statusCode });
            console.error('Groq API authentication failed:', responseData);
            return reject(new Error('Authentication failed: Invalid API key'));
          } else if (res.statusCode === 429) {
            logger.error('Groq API rate limit exceeded', { statusCode: res.statusCode });
            console.error('Groq API rate limit exceeded:', responseData);
            return reject(new Error('Rate limit exceeded: Please try again later'));
          } else if (res.statusCode >= 500) {
            logger.error('Groq API server error', { statusCode: res.statusCode });
            console.error('Groq API server error:', responseData);
            return reject(new Error('Server error: Please try again later'));
          } else {
            logger.error('Groq API request failed', { 
              statusCode: res.statusCode, 
              response: responseData 
            });
            console.error('Groq API request failed:', res.statusCode, responseData);
            return reject(new Error(`API request failed with status ${res.statusCode}`));
          }
        } catch (parseError) {
          logger.error('Failed to parse Groq API response', { 
            error: parseError.message, 
            responseData 
          });
          console.error('Failed to parse Groq API response:', parseError, responseData);
          return reject(new Error('Failed to parse API response'));
        }
      });
    });

    // Handle request errors
    req.on('error', (error) => {
      logger.error('Groq API request error', { 
        error: error.message, 
        code: error.code 
      });
      console.error('Groq API request error:', error);
      reject(new Error(`Request failed: ${error.message}`));
    });

    // Handle timeout
    req.setTimeout(30000, () => {
      req.destroy();
      logger.error('Groq API request timeout');
      console.error('Groq API request timeout');
      reject(new Error('Request timeout: Please try again'));
    });

    // Send the request
    req.write(requestData);
    req.end();
  });
}

/**
 * Enhanced query function with retry logic and better error handling
 * @param {string} prompt - The user prompt to send to the LLM
 * @param {Object} options - Additional options
 * @param {number} options.maxRetries - Maximum number of retry attempts (default: 2)
 * @param {number} options.retryDelay - Delay between retries in milliseconds (default: 1000)
 * @returns {Promise<string>} - The AI model's response
 */
async function queryGroqLLMWithRetry(prompt, options = {}) {
  const { maxRetries = 2, retryDelay = 1000 } = options;
  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await queryGroqLLM(prompt);
    } catch (error) {
      lastError = error;
      
      // Don't retry on authentication errors or invalid prompts
      if (error.message.includes('Authentication failed') || 
          error.message.includes('Invalid prompt')) {
        throw error;
      }

      // Log retry attempt
      if (attempt < maxRetries) {
        logger.warn(`Groq API request failed, retrying...`, {
          attempt: attempt + 1,
          maxRetries,
          error: error.message
        });
        
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, retryDelay * (attempt + 1)));
      }
    }
  }

  // All retries failed
  logger.error('All Groq API retry attempts failed', { 
    maxRetries, 
    finalError: lastError.message 
  });
  throw lastError;
}

/**
 * Test the Groq API connection
 * @returns {Promise<boolean>} - True if connection is successful
 */
async function testGroqConnection() {
  try {
    const testPrompt = "Hello, this is a test message. Please respond with 'Connection successful' if you can read this.";
    const response = await queryGroqLLM(testPrompt);
    
    logger.info('Groq API connection test successful', { response: response.substring(0, 100) });
    return true;
  } catch (error) {
    logger.error('Groq API connection test failed', { error: error.message });
    return false;
  }
}

module.exports = {
  queryGroqLLM,
  queryGroqLLMWithRetry,
  testGroqConnection
}; 