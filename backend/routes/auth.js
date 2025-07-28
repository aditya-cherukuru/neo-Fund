const express = require('express');
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validateRequest');
const { 
  register,
  login,
  refreshToken,
  logout,
  getMe,
  verifyEmail,
  verifyPhone,
  resendVerification,
  forgotPassword,
  resetPassword
} = require('../controllers/authController');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const registerValidation = [
  body('firstName').notEmpty().withMessage('First name is required'),
  body('lastName').notEmpty().withMessage('Last name is required'),
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('username')
    .isLength({ min: 3 })
    .withMessage('Username must be at least 3 characters long'),
];

const loginValidation = [
  body('email').notEmpty().withMessage('Email or username is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

const refreshTokenValidation = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
];

// Routes
router.post('/register', registerValidation, validateRequest, register);
router.post('/login', loginValidation, validateRequest, login);
router.post('/refresh-token', refreshTokenValidation, validateRequest, refreshToken);
router.post('/logout', auth, logout);
router.get('/me', auth, getMe);

// Optional routes (can be implemented later)
router.post('/verify-email', verifyEmail);
router.post('/verify-phone', verifyPhone);
router.post('/resend-verification', resendVerification);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

module.exports = router; 