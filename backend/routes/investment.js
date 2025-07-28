const express = require('express');
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validateRequest');
const { auth } = require('../middleware/auth');
const {
  createInvestment,
  getAllInvestments,
  updateInvestment,
  deleteInvestment,
  searchSymbols,
  getHistoricalData,
  generateForecast
} = require('../controllers/investmentController');

const router = express.Router();

// Investment routes - all protected with JWT authentication
router.post('/create', auth, [
  body('name').notEmpty().withMessage('Investment name is required'),
  body('type').isIn(['stocks', 'bonds', 'mutual_funds', 'etfs', 'real_estate', 'crypto', 'other']).withMessage('Invalid investment type'),
  body('amount').isNumeric().withMessage('Investment amount must be a number'),
  body('platform').optional().notEmpty().withMessage('Platform cannot be empty'),
  body('purchaseDate').isISO8601().withMessage('Purchase date must be a valid date'),
  body('expectedReturn').optional().isNumeric().withMessage('Expected return must be a number'),
  body('riskLevel').optional().isIn(['low', 'medium', 'high']).withMessage('Invalid risk level')
], validateRequest, createInvestment);

router.get('/', auth, getAllInvestments);

router.put('/:id', auth, [
  body('name').optional().notEmpty().withMessage('Investment name cannot be empty'),
  body('type').optional().isIn(['stocks', 'bonds', 'mutual_funds', 'etfs', 'real_estate', 'crypto', 'other']).withMessage('Invalid investment type'),
  body('amount').optional().isNumeric().withMessage('Investment amount must be a number'),
  body('platform').optional().notEmpty().withMessage('Platform cannot be empty'),
  body('purchaseDate').optional().isISO8601().withMessage('Purchase date must be a valid date'),
  body('expectedReturn').optional().isNumeric().withMessage('Expected return must be a number'),
  body('riskLevel').optional().isIn(['low', 'medium', 'high']).withMessage('Invalid risk level')
], validateRequest, updateInvestment);

router.delete('/:id', auth, deleteInvestment);

// New endpoints for investment forecasting
router.post('/forecast', generateForecast);
router.get('/search-symbols', searchSymbols);
router.post('/historical-data', getHistoricalData);

module.exports = router; 