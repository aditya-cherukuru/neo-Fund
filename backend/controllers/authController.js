const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { HttpException } = require('../utils/httpException');
const { logger } = require('../utils/logger');
const {
  generateToken,
  verifyToken,
  generateRefreshToken,
  verifyRefreshToken,
} = require('../utils/jwt');

// Register
exports.register = async (req, res, next) => {
  try {
    console.log('Registration request body:', req.body);
    const { firstName, lastName, email, password, username, profilePicture } = req.body;
    console.log('Parsed fields:', { firstName, lastName, email, username });

    // Ensure profilePicture is set to empty string if not provided
    const userProfilePicture = profilePicture || "";

    logger.info('Registration attempt:', { email, username, firstName, lastName });

    // Check if email exists
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      logger.warn('Registration failed: Email already exists', { email });
      return res.status(409).json({
        status: 'error',
        message: 'Email already registered'
      });
    }

    // Check if username exists
    const existingUsername = await User.findOne({ username });
    if (existingUsername) {
      logger.warn('Registration failed: Username already exists', { username });
      return res.status(409).json({
        status: 'error',
        message: 'Username already taken'
      });
    }

    // Create user instance
    const adminEmails = ['arian.zg2003@gmail.com']; // Add your email(s) here
    const user = new User({
      firstName,
      lastName,
      email,
      password, // Will be hashed by pre-save hook
      username,
      profilePicture: userProfilePicture,
      role: adminEmails.includes(email) ? 'admin' : 'user'
    });

    // Save user to database
    try {
      const savedUser = await user.save();
      logger.info('User saved successfully:', { 
        userId: savedUser._id,
        email: savedUser.email,
        username: savedUser.username,
        firstName: savedUser.firstName,
        lastName: savedUser.lastName
      });

      // Generate tokens
      const accessToken = generateToken(savedUser._id);
      const refreshToken = generateRefreshToken(savedUser._id);

      // Save refresh token
      savedUser.refreshToken = refreshToken;
      await savedUser.save();
      logger.info('Refresh token saved successfully:', { userId: savedUser._id });

      res.status(201).json({
        status: 'success',
        data: {
          userId: savedUser._id,
          accessToken,
          refreshToken,
          user: savedUser.getPublicProfile(),
        },
      });
    } catch (saveError) {
      logger.error('Failed to save user:', {
        error: saveError.message,
        stack: saveError.stack,
        email,
        username
      });
      
      // Handle mongoose validation errors specifically
      if (saveError.name === 'ValidationError') {
        console.log('Validation errors:', saveError.errors);
        return res.status(400).json({
          status: 'error',
          message: 'Validation failed',
          errors: Object.keys(saveError.errors).map(key => ({
            field: key,
            message: saveError.errors[key].message
          }))
        });
      }
      
      throw saveError;
    }
  } catch (error) {
    logger.error('Registration error:', {
      error: error.message,
      stack: error.stack,
      email: req.body.email,
      username: req.body.username
    });

    if (error.code === 11000) {
      return res.status(409).json({
        status: 'error',
        message: 'Email or username already exists'
      });
    }

    // Handle mongoose validation errors
    if (error.name === 'ValidationError') {
      console.log('Validation errors:', error.errors);
      return res.status(400).json({
        status: 'error',
        message: 'Validation failed',
        errors: Object.keys(error.errors).map(key => ({
          field: key,
          message: error.errors[key].message
        }))
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Registration failed: ' + error.message
    });
  }
};

// Login
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    console.log("Login attempt for email:", email);
    logger.info('Login attempt:', { email });

    // Check if the email field is actually an email or username
    const isEmail = email.includes('@');
    let user;

    if (isEmail) {
      // Find user by email
      user = await User.findOne({ email });
      console.log("User found by email:", user ? "Yes" : "No");
    } else {
      // Find user by username
      user = await User.findOne({ username: email });
      console.log("User found by username:", user ? "Yes" : "No");
    }

    if (!user) {
      logger.warn('Login failed: User not found', { email, isEmail });
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    // Check password using the model's comparePassword method
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      logger.warn('Login failed: Invalid password', { 
        userId: user._id,
        email,
        isEmail
      });
      return res.status(401).json({
        status: 'error',
        message: 'Invalid credentials'
      });
    }

    // Generate tokens
    const accessToken = generateToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    // Save refresh token
    user.refreshToken = refreshToken;
    await user.save();

    logger.info('Login successful:', { 
      userId: user._id,
      email: user.email,
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      loginMethod: isEmail ? 'email' : 'username'
    });

    res.status(200).json({
      status: 'success',
      data: {
        userId: user._id,
        accessToken,
        refreshToken,
        user: user.getPublicProfile(),
      },
    });
  } catch (error) {
    logger.error('Login error:', {
      error: error.message,
      stack: error.stack,
      email: req.body.email
    });
    res.status(500).json({
      status: 'error',
      message: 'Login failed: ' + error.message
    });
  }
};

// Refresh token
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      throw new HttpException(400, 'Refresh token is required');
    }

    // Verify refresh token
    const decoded = verifyRefreshToken(refreshToken);
    const user = await User.findById(decoded.id);

    if (!user || user.refreshToken !== refreshToken) {
      throw new HttpException(401, 'Invalid refresh token');
    }

    // Generate new tokens
    const newAccessToken = generateToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    // Update refresh token
    user.refreshToken = newRefreshToken;
    await user.save();

    res.json({
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Logout
exports.logout = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (user) {
      user.refreshToken = null;
      await user.save();
    }

    res.json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Get current user
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('-password -refreshToken');
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// Optional: Email verification
exports.verifyEmail = async (req, res, next) => {
  try {
    const { token } = req.body;
    
    // Verify token and update user
    const decoded = verifyToken(token);
    const user = await User.findById(decoded.id);
    
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    user.isEmailVerified = true;
    await user.save();

    res.json({
      success: true,
      message: 'Email verified successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Optional: Forgot password
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    // Generate reset token
    const resetToken = generateToken(user._id);
    
    // TODO: Send email with reset link
    // For now, just return the token
    res.json({
      success: true,
      message: 'Password reset email sent',
      data: { resetToken }
    });
  } catch (error) {
    next(error);
  }
};

// Optional: Reset password
exports.resetPassword = async (req, res, next) => {
  try {
    const { token, password } = req.body;
    
    // Verify token
    const decoded = verifyToken(token);
    const user = await User.findById(decoded.id);
    
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    // Update password
    user.password = password;
    await user.save();

    res.json({
      success: true,
      message: 'Password reset successful'
    });
  } catch (error) {
    next(error);
  }
};

// Google OAuth
exports.googleAuth = async (req, res, next) => {
  try {
    const { user: googleUser } = req;

    // Check if user exists
    let user = await User.findOne({ googleId: googleUser.id });

    if (!user) {
      // Create new user
      user = new User({
        email: googleUser.emails[0].value,
        firstName: googleUser.name.givenName,
        lastName: googleUser.name.familyName,
        username: googleUser.emails[0].value.split('@')[0],
        googleId: googleUser.id,
        profilePicture: googleUser.photos[0].value,
        isEmailVerified: true
      });

      await user.save();
    }

    // Generate token
    const token = generateToken(user._id);

    res.json({
      status: 'success',
      token,
      user: user.getPublicProfile()
    });
  } catch (error) {
    next(error);
  }
};

// Verify phone
exports.verifyPhone = async (req, res, next) => {
  try {
    const { phoneNumber, code } = req.body;
    
    // Verify OTP and update user
    const user = await User.findOne({ phoneNumber });
    
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    // TODO: Implement OTP verification logic
    
    user.isPhoneVerified = true;
    await user.save();

    res.json({
      status: 'success',
      message: 'Phone number verified successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Resend verification
exports.resendVerification = async (req, res, next) => {
  try {
    const { email } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      throw new HttpException(404, 'User not found');
    }

    // TODO: Implement resend verification logic

    res.json({
      status: 'success',
      message: 'Verification email sent'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register: exports.register,
  login: exports.login,
  refreshToken: exports.refreshToken,
  logout: exports.logout,
  getMe: exports.getMe,
  verifyEmail: exports.verifyEmail,
  verifyPhone: exports.verifyPhone,
  resendVerification: exports.resendVerification,
  forgotPassword: exports.forgotPassword,
  resetPassword: exports.resetPassword
}; 