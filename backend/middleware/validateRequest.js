const { validationResult } = require('express-validator');
const { AppError } = require('./errorHandler');

exports.validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.log('Validation errors:', errors.array());
    const error = new AppError('Validation failed', 400);
    error.errors = errors.array();
    return next(error);
  }
  next();
}; 