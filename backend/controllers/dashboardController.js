const Transaction = require('../models/Transaction');
const Account = require('../models/Account');
const Goal = require('../models/Goal');
const { HttpException } = require('../utils/httpException');

/**
 * Get comprehensive dashboard summary data
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const getDashboardSummary = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get current date and calculate date ranges
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    
    // Get last 7 days for spending trend
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(now.getDate() - i);
      last7Days.push(date.toISOString().split('T')[0]);
    }

    // Fetch transactions for different periods
    const [monthlyTransactions, weeklyTransactions, recentTransactions] = await Promise.all([
      // Monthly transactions
      Transaction.find({
        userId,
        date: { $gte: startOfMonth },
        type: 'expense'
      }),
      
      // Weekly transactions
      Transaction.find({
        userId,
        date: { $gte: startOfWeek },
        type: 'expense'
      }),
      
      // Recent transactions (last 5)
      Transaction.find({ userId })
        .sort({ date: -1 })
        .limit(5)
    ]);

    // Calculate financial metrics
    const monthlySpending = monthlyTransactions.reduce((sum, t) => sum + t.amount, 0);
    const weeklySpending = weeklyTransactions.reduce((sum, t) => sum + t.amount, 0);
    
    // Get accounts for net worth calculation
    const accounts = await Account.find({ userId });
    const netWorth = accounts.reduce((sum, account) => {
      if (account.type === 'loan' || account.type === 'credit') {
        return sum - account.balance;
      }
      return sum + account.balance;
    }, 0);

    // Calculate savings rate (mock calculation for now)
    const monthlyIncome = 4500; // This should come from income transactions
    const savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlySpending) / monthlyIncome) * 100 : 0;

    // Calculate budget data
    const monthlyBudget = 20000; // This should come from user's budget settings
    const remainingBudget = Math.max(0, monthlyBudget - monthlySpending);
    const spendingPercentage = monthlyBudget > 0 ? (monthlySpending / monthlyBudget) * 100 : 0;
    
    // Determine budget status
    let budgetStatus = 'on_track';
    if (spendingPercentage > 90) {
      budgetStatus = 'warning';
    } else if (spendingPercentage > 100) {
      budgetStatus = 'over_budget';
    } else if (spendingPercentage < 50) {
      budgetStatus = 'under_budget';
    }

    // Generate spending trend data
    const spendingTrend = last7Days.map(date => {
      const dayTransactions = weeklyTransactions.filter(t => 
        t.date.toISOString().split('T')[0] === date
      );
      const amount = dayTransactions.reduce((sum, t) => sum + t.amount, 0);
      return { date, amount };
    });

    // Generate smart suggestions based on financial data
    const smartSuggestions = generateSmartSuggestions({
      monthlySpending,
      monthlyIncome,
      savingsRate,
      netWorth,
      accounts
    });

    // Format recent transactions for frontend
    const formattedTransactions = recentTransactions.map(t => ({
      id: t._id.toString(),
      title: t.description,
      description: t.category,
      amount: t.amount,
      date: t.date,
      category: t.category,
      icon: getCategoryIcon(t.category),
      color: getCategoryColor(t.category),
      isExpense: t.type === 'expense'
    }));

    // Create dashboard summary
    const summary = {
      netWorth: Math.round(netWorth * 100) / 100,
      monthlySpending: Math.round(monthlySpending * 100) / 100,
      monthlyIncome: monthlyIncome,
      savingsRate: Math.round(savingsRate * 10) / 10,
      emergencyFundStatus: getEmergencyFundStatus(monthlySpending),
      investmentPortfolio: getInvestmentPortfolio(accounts),
      debtAmount: getDebtAmount(accounts),
      creditScore: 750 // Mock credit score
    };

    // Create budget data
    const budgetData = {
      monthlyBudget: monthlyBudget,
      amountSpent: Math.round(monthlySpending * 100) / 100,
      remainingBudget: Math.round(remainingBudget * 100) / 100,
      spendingPercentage: Math.round(spendingPercentage * 10) / 10,
      budgetStatus: budgetStatus
    };

    res.json({
      success: true,
      data: {
        summary,
        budgetData,
        recentTransactions: formattedTransactions,
        smartSuggestions,
        spendingTrend
      }
    });

  } catch (error) {
    console.error('Dashboard summary error:', error);
    throw new HttpException(500, 'Failed to fetch dashboard summary');
  }
};

/**
 * Generate smart financial suggestions
 */
const generateSmartSuggestions = (financialData) => {
  const suggestions = [];

  // Budget optimization suggestion
  if (financialData.savingsRate < 20) {
    suggestions.push({
      id: '1',
      title: 'Optimize Your Budget',
      description: 'Based on your spending patterns, you could save 15% more by reducing dining out expenses and optimizing your subscription services.',
      icon: 'tune',
      color: '#2196F3',
      category: 'Budget Optimization',
      impact: 15.0,
      priority: 'high'
    });
  }

  // Emergency fund suggestion
  const emergencyFundNeeded = financialData.monthlySpending * 3;
  if (financialData.netWorth < emergencyFundNeeded) {
    suggestions.push({
      id: '2',
      title: 'Emergency Fund Alert',
      description: `Your emergency fund is below the recommended 3-month expense level. Consider setting aside an additional $${Math.round(emergencyFundNeeded - financialData.netWorth)} for better financial security.`,
      icon: 'security',
      color: '#FF9800',
      category: 'Financial Security',
      impact: 25.0,
      priority: 'high'
    });
  }

  // Investment suggestion
  if (financialData.savingsRate > 20) {
    suggestions.push({
      id: '3',
      title: 'Investment Opportunity',
      description: 'With your current savings rate, you could start investing $500 monthly in a diversified portfolio to build long-term wealth.',
      icon: 'trending_up',
      color: '#4CAF50',
      category: 'Investment',
      impact: 30.0,
      priority: 'medium'
    });
  }

  // Debt reduction suggestion
  if (financialData.debtAmount > 0) {
    suggestions.push({
      id: '4',
      title: 'Debt Reduction Strategy',
      description: 'Focus on paying off your high-interest credit card debt first. This could save you $180 in interest payments this year.',
      icon: 'payment',
      color: '#F44336',
      category: 'Debt Management',
      impact: 12.0,
      priority: 'medium'
    });
  }

  return suggestions;
};

/**
 * Get emergency fund status
 */
const getEmergencyFundStatus = (monthlySpending) => {
  const emergencyFundNeeded = monthlySpending * 3;
  if (monthlySpending === 0) return 'Unknown';
  if (monthlySpending < 1000) return 'Good';
  if (monthlySpending < 2000) return 'Fair';
  return 'Needs Attention';
};

/**
 * Get investment portfolio value
 */
const getInvestmentPortfolio = (accounts) => {
  return accounts
    .filter(account => account.type === 'investment')
    .reduce((sum, account) => sum + account.balance, 0);
};

/**
 * Get total debt amount
 */
const getDebtAmount = (accounts) => {
  return accounts
    .filter(account => account.type === 'loan' || account.type === 'credit')
    .reduce((sum, account) => sum + account.balance, 0);
};

/**
 * Get category icon
 */
const getCategoryIcon = (category) => {
  const iconMap = {
    'Food & Dining': 'restaurant',
    'Transportation': 'directions_car',
    'Entertainment': 'movie',
    'Shopping': 'shopping_cart',
    'Utilities': 'power',
    'Healthcare': 'local_hospital',
    'Income': 'account_balance',
    'default': 'receipt'
  };
  return iconMap[category] || iconMap.default;
};

/**
 * Get category color
 */
const getCategoryColor = (category) => {
  const colorMap = {
    'Food & Dining': '#4CAF50',
    'Transportation': '#FF9800',
    'Entertainment': '#9C27B0',
    'Shopping': '#2196F3',
    'Utilities': '#FF5722',
    'Healthcare': '#E91E63',
    'Income': '#4CAF50',
    'default': '#607D8B'
  };
  return colorMap[category] || colorMap.default;
};

module.exports = {
  getDashboardSummary
}; 