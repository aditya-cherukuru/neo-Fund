const jwt = require('jsonwebtoken');
const { HttpException } = require('./httpException');

// Validate JWT secrets are present
const validateJWTSecrets = () => {
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET environment variable is not set');
  }
  if (!process.env.JWT_REFRESH_SECRET) {
    throw new Error('JWT_REFRESH_SECRET environment variable is not set');
  }
};

const generateToken = (userId) => {
  validateJWTSecrets();
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

const verifyToken = (token) => {
  validateJWTSecrets();
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      throw new HttpException(401, 'Invalid token');
    }
    if (error instanceof jwt.TokenExpiredError) {
      throw new HttpException(401, 'Token expired');
    }
    throw error;
  }
};

const generateRefreshToken = (userId) => {
  validateJWTSecrets();
  return jwt.sign({ id: userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: '7d',
  });
};

const verifyRefreshToken = (token) => {
  validateJWTSecrets();
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      throw new HttpException(401, 'Invalid refresh token');
    }
    if (error instanceof jwt.TokenExpiredError) {
      throw new HttpException(401, 'Refresh token expired');
    }
    throw error;
  }
};

module.exports = {
  generateToken,
  verifyToken,
  generateRefreshToken,
  verifyRefreshToken,
}; 