const axios = require('axios');

// Environment variable for Golang service URL
// Production/Staging: http://api-golang.staging.generic-gha.local:8080
// Local dev: http://localhost:8000
const golangServiceUrl = process.env.GOLANG_SERVICE_URL || 'http://localhost:8000';

console.log(`Golang service URL configured: ${golangServiceUrl}`);

const client = axios.create({
  baseURL: golangServiceUrl,
  timeout: 5000, // 5 second timeout
  headers: { 'Content-Type': 'application/json' }
});

const getGolangData = async () => {
  const startTime = Date.now();
  try {
    console.log(`Calling Golang service at: ${golangServiceUrl}/api/golang/`);
    const response = await client.get('/api/golang/');
    const duration = Date.now() - startTime;
    console.log(`Golang service response time: ${duration}ms`);
    return {
      success: true,
      data: response.data,
      duration: `${duration}ms`
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error('Error calling Golang service:', error.message);
    return {
      success: false,
      error: error.message,
      duration: `${duration}ms`
    };
  }
};

module.exports = { getGolangData };
