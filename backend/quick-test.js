const http = require('http');

async function makeRequest(method, path, data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: data });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function test() {
  console.log('🧪 Testing AI Controller...\n');

  // 1. Register a user
  console.log('1. Registering test user...');
  const userData = {
    firstName: 'Test',
    lastName: 'User', 
    email: `test${Date.now()}@example.com`,
    username: `testuser${Date.now()}`,
    password: 'password123'
  };

  const registerResponse = await makeRequest('POST', '/api/auth/register', userData);
  console.log('Register status:', registerResponse.statusCode);
  console.log('Register response:', registerResponse.data);
  
  if (registerResponse.statusCode !== 201) {
    console.log('❌ Registration failed:', registerResponse.data);
    return;
  }

  const token = registerResponse.data.data.accessToken;
  console.log('✅ Got JWT token:', token ? 'Token received' : 'No token');
  console.log('Token preview:', token ? token.substring(0, 50) + '...' : 'No token');

  // 2. Test AI endpoint
  console.log('\n2. Testing AI endpoint...');
  console.log('Using token:', token ? token.substring(0, 50) + '...' : 'No token');
  console.log('Full Authorization header:', `Bearer ${token}`);
  
  const aiResponse = await makeRequest('POST', '/api/ai/response', 
    { prompt: 'What is the best way to save money?' },
    { 'Authorization': `Bearer ${token}` }
  );

  console.log('AI endpoint status:', aiResponse.statusCode);
  console.log('AI endpoint response:', aiResponse.data);
  
  if (aiResponse.statusCode === 200 && aiResponse.data.success) {
    console.log('✅ AI Controller WORKS!');
    console.log('Response preview:', aiResponse.data.data.substring(0, 100) + '...');
  } else {
    console.log('❌ AI Controller failed:', aiResponse.data);
  }
}

test().catch(console.error); 