const express = require('express');
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validateRequest');
const { auth } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const {
  getProfile,
  updateProfile,
  updateSettings,
  updatePassword,
  deleteAccount,
  uploadProfilePicture,
  deleteProfilePicture,
  getProfilePicture
} = require('../controllers/userController');

const router = express.Router();

// Configure multer for profile picture uploads
const upload = multer({ 
  storage: multer.memoryStorage(), // Use memory storage for base64 conversion
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: function (req, file, cb) {
    // Accept only JPEG and PNG images
    if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/png' || file.mimetype === 'image/jpg') {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG and PNG images are allowed. Please select a valid image file.'), false);
    }
  }
});

// Profile routes
router.get('/profile', auth, getProfile);
router.put('/profile', auth, [
  body('firstName').optional().notEmpty(),
  body('lastName').optional().notEmpty(),
  body('email').optional().isEmail(),
  // Temporarily disabled phone number validation to fix login issue
  // body('phoneNumber').optional().matches(/^[\+]?[1-9][\d\s\-\(\)]{9,15}$/).withMessage('Please enter a valid phone number'),
  body('username').optional().notEmpty(),
  body('dateOfBirth').optional().custom((value) => {
    if (value === null || value === undefined || value === '') {
      return true; // Allow null/empty values
    }
    // Check if it's a valid date in YYYY-MM-DD format
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateRegex.test(value)) {
      return false;
    }
    const date = new Date(value);
    return !isNaN(date.getTime());
  }).withMessage('Date of birth must be in YYYY-MM-DD format'),
  body('address').optional().isObject(),
  body('address.street').optional().isString(),
  body('address.city').optional().isString(),
  body('address.state').optional().isString(),
  body('address.country').optional().isString(),
  body('address.zipCode').optional().isString(),
  body('bio').optional().isLength({ max: 500 }).withMessage('Bio cannot exceed 500 characters'),
  body('settings').optional().isObject(),
  body('profilePicture').optional().isString()
], validateRequest, updateProfile);

// Settings routes
router.get('/settings', auth, (req, res) => {
  res.json({
    status: 'success',
    data: req.user.settings
  });
});

router.put('/settings', auth, [
  body('currency').optional().isString(),
  body('language').optional().isString(),
  body('notifications.email').optional().isBoolean(),
  body('notifications.push').optional().isBoolean(),
  body('theme').optional().isString()
], validateRequest, updateSettings);

// Security routes
router.put('/password', auth, [
  body('currentPassword').notEmpty(),
  body('newPassword').isLength({ min: 6 })
], validateRequest, updatePassword);

router.delete('/account', auth, deleteAccount);

// Profile picture route with multer middleware
router.post('/profile/picture', auth, upload.single('profilePicture'), uploadProfilePicture);
router.delete('/profile/picture', auth, deleteProfilePicture);
router.get('/profile-picture/:userId', getProfilePicture);

module.exports = router; 