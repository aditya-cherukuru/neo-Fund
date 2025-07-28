const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { AppError } = require('../middleware/errorHandler');
const { logger } = require('../utils/logger');
const path = require('path');
const fs = require('fs');

// Get user profile
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      status: 'success',
      data: user.getPublicProfile()
    });
  } catch (error) {
    next(error);
  }
};

// Update user profile
exports.updateProfile = async (req, res, next) => {
  try {
    const { firstName, lastName, email, phoneNumber, username, settings, profilePicture, dateOfBirth, address, bio } = req.body;

    // Debug logging for date of birth specifically
    if (dateOfBirth !== undefined) {
      logger.info('Date of birth update:', { 
        userId: req.user._id,
        oldValue: req.user.dateOfBirth, 
        newValue: dateOfBirth,
        type: typeof dateOfBirth 
      });
    }

    // Check if username is taken
    if (username) {
      const existingUser = await User.findOne({
        username,
        _id: { $ne: req.user._id }
      });

      if (existingUser) {
        throw new AppError('Username already taken', 400);
      }
    }

    // Check if email is taken
    if (email) {
      const existingUser = await User.findOne({
        email,
        _id: { $ne: req.user._id }
      });

      if (existingUser) {
        throw new AppError('Email already taken', 400);
      }
    }

    const user = await User.findById(req.user._id);
    
    // Update basic profile fields
    if (firstName !== undefined) user.firstName = firstName;
    if (lastName !== undefined) user.lastName = lastName;
    if (email !== undefined) user.email = email;
    if (phoneNumber !== undefined) user.phoneNumber = phoneNumber;
    if (username !== undefined) user.username = username;
    if (profilePicture !== undefined) user.profilePicture = profilePicture;
    if (dateOfBirth !== undefined) {
      // Handle date of birth to prevent timezone conversion issues
      if (dateOfBirth === null || dateOfBirth === '') {
        user.dateOfBirth = null;
      } else {
        // Parse the date from YYYY-MM-DD format and create a local date
        const [year, month, day] = dateOfBirth.split('-').map(Number);
        const localDate = new Date(year, month - 1, day); // month is 0-indexed
        user.dateOfBirth = localDate;
      }
    }
    if (address !== undefined) user.address = address;
    if (bio !== undefined) user.bio = bio;

    // Update settings if provided
    if (settings) {
      if (settings.currency !== undefined) user.settings.currency = settings.currency;
      if (settings.language !== undefined) user.settings.language = settings.language;
      if (settings.theme !== undefined) user.settings.theme = settings.theme;
      if (settings.notifications) {
        if (settings.notifications.email !== undefined) {
          user.settings.notifications.email = settings.notifications.email;
        }
        if (settings.notifications.push !== undefined) {
          user.settings.notifications.push = settings.notifications.push;
        }
      }
    }

    await user.save();

    res.json({
      status: 'success',
      data: user.getPublicProfile()
    });
  } catch (error) {
    next(error);
  }
};

// Update user settings
exports.updateSettings = async (req, res, next) => {
  try {
    const { currency, language, notifications, theme } = req.body;

    const user = await User.findById(req.user._id);
    user.settings = {
      ...user.settings,
      currency: currency || user.settings.currency,
      language: language || user.settings.language,
      notifications: {
        ...user.settings.notifications,
        ...notifications
      },
      theme: theme || user.settings.theme
    };

    await user.save();

    res.json({
      status: 'success',
      data: user.settings
    });
  } catch (error) {
    next(error);
  }
};

// Update password
exports.updatePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user._id);

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      throw new AppError('Current password is incorrect', 401);
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      status: 'success',
      message: 'Password updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Delete account
exports.deleteAccount = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);

    // TODO: Delete all user data (transactions, accounts, goals, etc.)

    await User.deleteOne({ _id: req.user._id });

    res.json({
      status: 'success',
      message: 'Account deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Upload profile picture
exports.uploadProfilePicture = async (req, res, next) => {
  try {
    if (!req.file) {
      throw new AppError('No file uploaded', 400);
    }

    const user = await User.findById(req.user._id);
    
    // Convert the uploaded file buffer to base64
    const base64Image = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
    
    // Save the base64 image to user profile
    user.profilePicture = base64Image;
    await user.save();

    res.json({
      status: 'success',
      data: user.getPublicProfile()
    });
  } catch (error) {
    next(error);
  }
};

// Delete profile picture
exports.deleteProfilePicture = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    
    // Clear the profile picture (base64 data)
    user.profilePicture = '';
    await user.save();

    res.json({
      status: 'success',
      message: 'Profile picture removed successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get profile picture by userId
exports.getProfilePicture = async (req, res, next) => {
  try {
    const { userId } = req.params;
    
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    if (!user.profilePicture || user.profilePicture === '') {
      throw new AppError('Profile picture not found', 404);
    }

    // Extract base64 data and content type
    const base64Data = user.profilePicture;
    const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    
    if (!matches || matches.length !== 3) {
      throw new AppError('Invalid image format', 400);
    }

    const contentType = matches[1];
    const imageBuffer = Buffer.from(matches[2], 'base64');

    // Set appropriate headers
    res.set({
      'Content-Type': contentType,
      'Content-Length': imageBuffer.length,
      'Cache-Control': 'public, max-age=31536000', // Cache for 1 year
    });

    res.send(imageBuffer);
  } catch (error) {
    next(error);
  }
}; 