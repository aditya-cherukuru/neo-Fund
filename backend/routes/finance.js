const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validateRequest');

// Dashboard summary endpoint
router.get('/dashboard/summary', auth, async (req, res) => {
  try {
    // Mock dashboard data since we removed the full implementation
    const dashboardData = {
      summary: {
        totalBalance: 25000.00,
        monthlyIncome: 5000.00,
        monthlyExpenses: 3200.00,
        savingsRate: 36.0,
        netWorth: 45000.00,
        monthlySavings: 1800.00
      },
      budgetData: {
        totalBudget: 5000.00,
        spent: 3200.00,
        remaining: 1800.00,
        categories: [
          { name: 'Housing', budget: 1500, spent: 1200, remaining: 300 },
          { name: 'Food', budget: 600, spent: 450, remaining: 150 },
          { name: 'Transportation', budget: 400, spent: 350, remaining: 50 },
          { name: 'Entertainment', budget: 300, spent: 200, remaining: 100 },
          { name: 'Utilities', budget: 200, spent: 180, remaining: 20 },
          { name: 'Healthcare', budget: 150, spent: 120, remaining: 30 },
          { name: 'Shopping', budget: 200, spent: 150, remaining: 50 },
          { name: 'Education', budget: 100, spent: 80, remaining: 20 },
          { name: 'Insurance', budget: 150, spent: 150, remaining: 0 },
          { name: 'Miscellaneous', budget: 400, spent: 320, remaining: 80 }
        ]
      },
      recentTransactions: [
        {
          id: '1',
          description: 'Grocery Store',
          amount: -85.50,
          category: 'Food',
          date: new Date().toISOString(),
          type: 'expense'
        },
        {
          id: '2',
          description: 'Salary Deposit',
          amount: 5000.00,
          category: 'Income',
          date: new Date(Date.now() - 86400000).toISOString(),
          type: 'income'
        },
        {
          id: '3',
          description: 'Gas Station',
          amount: -45.00,
          category: 'Transportation',
          date: new Date(Date.now() - 172800000).toISOString(),
          type: 'expense'
        }
      ],
      smartSuggestions: [
        {
          id: '1',
          title: 'Increase Emergency Fund',
          description: 'Consider adding $500 to your emergency fund this month',
          priority: 'high',
          estimatedSavings: 500
        },
        {
          id: '2',
          title: 'Review Subscription Services',
          description: 'You have 3 unused subscriptions costing $45/month',
          priority: 'medium',
          estimatedSavings: 45
        }
      ],
      spendingTrend: [
        { month: 'Jan', amount: 2800 },
        { month: 'Feb', amount: 3100 },
        { month: 'Mar', amount: 2900 },
        { month: 'Apr', amount: 3200 },
        { month: 'May', amount: 3000 },
        { month: 'Jun', amount: 3200 }
      ]
    };

    res.json({
      status: 'success',
      data: dashboardData
    });
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch dashboard summary'
    });
  }
});

module.exports = router; 