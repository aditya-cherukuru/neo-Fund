const express = require('express');
const { body } = require('express-validator');
const { validateRequest } = require('../middleware/validateRequest');
const { auth } = require('../middleware/auth');
const {
  getAIInsights,
  generateAIInsight,
  getAIResponse,
  generateFinancialAdvice,
  analyzeSpendingPatterns,
  getAIInsightById,
  deleteAIInsight,
  markInsightAsRead,
  markInsightAsUnread,
  getUnreadInsights,
  getInsightsByType,
  getHighImpactInsights,
  getRecentInsights,
  getAIInsightStats,
  generateInvestmentTips,
  getTrendingInvestments,
  getDailyInvestmentTip
} = require('../controllers/aiController');

const router = express.Router();

// AI routes - all protected with JWT authentication

// Get AI response for any prompt
router.post('/response', auth, [
  body('prompt').isString().notEmpty().withMessage('Prompt is required and must be a string')
], validateRequest, getAIResponse);

// Generate AI insights
router.post('/insights', auth, [
  body('type').isIn(['spending', 'budget', 'investment', 'goal', 'reminder', 'security', 'general']).withMessage('Invalid insight type'),
  body('context').optional().notEmpty().withMessage('Context cannot be empty'),
  body('source').optional().isString().withMessage('Source must be a string')
], validateRequest, generateAIInsight);

// Generate financial advice
router.post('/advice', auth, [
  body('category').isString().notEmpty().withMessage('Advice category is required'),
  body('context').optional().isString().withMessage('Context must be a string'),
  body('userProfile').optional().isObject().withMessage('User profile must be an object')
], validateRequest, generateFinancialAdvice);

// Analyze spending patterns
router.post('/analyze-spending', auth, [
  body('transactions').isArray().withMessage('Transactions must be an array'),
  body('timeFrame').optional().isString().withMessage('Time frame must be a string')
], validateRequest, analyzeSpendingPatterns);

// Get all AI insights
router.get('/insights', auth, getAIInsights);

// Get AI insight by ID
router.get('/insights/:id', auth, getAIInsightById);

// Delete AI insight
router.delete('/insights/:id', auth, deleteAIInsight);

// Mark insight as read/unread
router.patch('/insights/:id/read', auth, markInsightAsRead);
router.patch('/insights/:id/unread', auth, markInsightAsUnread);

// Get unread insights
router.get('/insights/unread/all', auth, getUnreadInsights);

// Get insights by type
router.get('/insights/type/:type', auth, getInsightsByType);

// Get high impact insights
router.get('/insights/impact/high', auth, getHighImpactInsights);

// Get recent insights
router.get('/insights/recent', auth, getRecentInsights);

// Get AI insights statistics
router.get('/insights/stats', auth, getAIInsightStats);

// Generate AI investment tips
router.post('/investment-tips', auth, [
  body('context').optional().isString().withMessage('Context must be a string'),
  body('userProfile').optional().isObject().withMessage('User profile must be an object')
], validateRequest, generateInvestmentTips);

// Get trending investments
router.post('/trending-investments', auth, [
  body('marketContext').optional().isString().withMessage('Market context must be a string'),
  body('userPreferences').optional().isObject().withMessage('User preferences must be an object')
], validateRequest, getTrendingInvestments);

// Get daily investment tip
router.post('/daily-tip', auth, [
  body('userContext').optional().isString().withMessage('User context must be a string')
], validateRequest, getDailyInvestmentTip);

// Legacy route for backward compatibility
router.post('/recommendations', auth, [
  body('type').isIn(['spending', 'saving', 'investment', 'budget', 'general']).withMessage('Invalid recommendation type'),
  body('context').optional().notEmpty().withMessage('Context cannot be empty'),
  body('preferences').optional().isObject().withMessage('Preferences must be an object')
], validateRequest, generateAIInsight);

// Minimal AI insight route for compatibility
router.post('/insight', generateAIInsight);

module.exports = router; 