const { verifyToken } = require('../utils/jwt');
const { HttpException } = require('../utils/httpException');
const User = require('../models/User');

const auth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    console.log('Auth header received:', authHeader);
    
    const token = authHeader?.replace('Bearer ', '');
    console.log('Token extracted:', token ? token.substring(0, 50) + '...' : 'No token');
    
    if (!token) {
      console.log('No token provided');
      throw new HttpException(401, 'Authentication required');
    }

    console.log('Attempting to verify token...');
    const decoded = verifyToken(token);
    console.log('Token verified successfully, decoded:', decoded);
    
    const user = await User.findById(decoded.id).select('-password');
    console.log('User found:', user ? 'Yes' : 'No');
    
    if (!user) {
      console.log('User not found in database');
      throw new HttpException(401, 'User not found');
    }

    console.log('Authentication successful for user:', user.email);
    req.user = user;
    next();
  } catch (error) {
    console.log('Auth middleware error:', error.message);
    // If it's already a HttpException, pass it through
    if (error instanceof HttpException) {
      return next(error);
    }
    
    // If it's a JWT error, pass it through as-is (error handler will handle it)
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return next(error);
    }
    
    // For other errors, wrap them in HttpException
    next(new HttpException(401, 'Authentication failed'));
  }
};

// Role-based access control middleware
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new HttpException(401, 'Authentication required'));
    }

    if (!roles.includes(req.user.role)) {
      return next(new HttpException(403, 'Access denied'));
    }

    next();
  };
};

module.exports = {
  auth,
  authorize,
}; 