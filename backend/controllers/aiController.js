const AIInsight = require('../models/AIInsight');
const { AppError } = require('../middleware/errorHandler');
const { queryGroqLLM, queryGroqLLMWithRetry } = require('../utils/groqClient');

// Generate AI insight for the user using Groq LLM
exports.generateAIInsight = async (req, res, next) => {
  try {
    const { type, context, source } = req.body;

    // Validate required fields
    if (!type) {
      throw new AppError('Insight type is required', 400);
    }

    // Validate insight type
    const validTypes = ['spending', 'budget', 'investment', 'goal', 'reminder', 'security', 'general'];
    if (!validTypes.includes(type)) {
      throw new AppError('Invalid insight type', 400);
    }

    // Generate AI insight using Groq LLM
    const aiPrompt = generateAIPrompt(type, context);
    const aiResponse = await queryGroqLLMWithRetry(aiPrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    // Parse AI response to extract title and content
    const parsedInsight = parseAIResponse(aiResponse, type);

    const insight = new AIInsight({
      user: req.user._id,
      title: parsedInsight.title,
      content: parsedInsight.content,
      type: type,
      source: source || 'Groq LLM',
      impactLevel: parsedInsight.impactLevel,
      createdByAI: true,
      read: false
    });

    await insight.save();

    res.status(201).json({
      status: 'success',
      data: insight,
      message: 'AI insight generated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get AI response for any prompt (new function)
exports.getAIResponse = async (req, res, next) => {
  try {
    console.log('getAIResponse called with body:', req.body);
    
    const { prompt } = req.body;

    // Validate prompt
    if (!prompt || typeof prompt !== 'string') {
      console.log('Validation failed: prompt is missing or invalid');
      return res.status(400).json({
        success: false,
        error: 'Prompt is required and must be a string'
      });
    }

    console.log('Calling Groq LLM with prompt:', prompt);

    // Call Groq LLM with the prompt
    const response = await queryGroqLLMWithRetry(prompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    console.log('Groq LLM response received:', response.substring(0, 100) + '...');

    res.json({
      success: true,
      data: response
    });
  } catch (error) {
    console.error('AI Response Error Details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// Generate financial advice using AI
exports.generateFinancialAdvice = async (req, res, next) => {
  try {
    const { category, context, userProfile } = req.body;

    // Validate required fields
    if (!category) {
      throw new AppError('Advice category is required', 400);
    }

    // Generate contextual prompt based on category and user profile
    const advicePrompt = generateFinancialAdvicePrompt(category, context, userProfile);
    
    const aiResponse = await queryGroqLLMWithRetry(advicePrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    res.json({
      status: 'success',
      data: {
        advice: aiResponse,
        category: category,
        generatedAt: new Date()
      },
      message: 'Financial advice generated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Analyze spending patterns using AI
exports.analyzeSpendingPatterns = async (req, res, next) => {
  try {
    const { transactions, timeFrame } = req.body;

    // Validate required fields
    if (!transactions || !Array.isArray(transactions)) {
      throw new AppError('Transactions array is required', 400);
    }

    // Generate analysis prompt
    const analysisPrompt = generateSpendingAnalysisPrompt(transactions, timeFrame);
    
    const aiResponse = await queryGroqLLMWithRetry(analysisPrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    res.json({
      status: 'success',
      data: {
        analysis: aiResponse,
        timeFrame: timeFrame,
        transactionCount: transactions.length,
        analyzedAt: new Date()
      },
      message: 'Spending pattern analysis completed'
    });
  } catch (error) {
    next(error);
  }
};

// Get all AI insights for a user
exports.getAIInsights = async (req, res, next) => {
  try {
    const { type, impactLevel, read, source, limit = 20, page = 1 } = req.query;
    const query = { user: req.user._id };

    // Apply filters
    if (type) {
      query.type = type;
    }

    if (impactLevel) {
      query.impactLevel = impactLevel;
    }

    if (read !== undefined) {
      query.read = read === 'true';
    }

    if (source) {
      query.source = source;
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const insights = await AIInsight.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('user', 'name email');

    // Get total count for pagination
    const total = await AIInsight.countDocuments(query);

    res.json({
      status: 'success',
      data: insights,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get AI insight by ID
exports.getAIInsightById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const insight = await AIInsight.findOne({
      _id: id,
      user: req.user._id
    }).populate('user', 'name email');

    if (!insight) {
      throw new AppError('AI insight not found', 404);
    }

    // Mark as read when retrieved
    if (!insight.read) {
      insight.read = true;
      await insight.save();
    }

    res.json({
      status: 'success',
      data: insight
    });
  } catch (error) {
    next(error);
  }
};

// Delete AI insight
exports.deleteAIInsight = async (req, res, next) => {
  try {
    const { id } = req.params;

    const insight = await AIInsight.findOne({
      _id: id,
      user: req.user._id
    });

    if (!insight) {
      throw new AppError('AI insight not found', 404);
    }

    await AIInsight.deleteOne({ _id: id });

    res.json({
      status: 'success',
      data: null,
      message: 'AI insight deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Mark insight as read
exports.markInsightAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const insight = await AIInsight.findOne({
      _id: id,
      user: req.user._id
    });

    if (!insight) {
      throw new AppError('AI insight not found', 404);
    }

    await insight.markAsRead();

    res.json({
      status: 'success',
      data: insight,
      message: 'Insight marked as read'
    });
  } catch (error) {
    next(error);
  }
};

// Mark insight as unread
exports.markInsightAsUnread = async (req, res, next) => {
  try {
    const { id } = req.params;

    const insight = await AIInsight.findOne({
      _id: id,
      user: req.user._id
    });

    if (!insight) {
      throw new AppError('AI insight not found', 404);
    }

    await insight.markAsUnread();

    res.json({
      status: 'success',
      data: insight,
      message: 'Insight marked as unread'
    });
  } catch (error) {
    next(error);
  }
};

// Get unread insights
exports.getUnreadInsights = async (req, res, next) => {
  try {
    const insights = await AIInsight.getUnreadInsights(req.user._id);

    res.json({
      status: 'success',
      data: insights
    });
  } catch (error) {
    next(error);
  }
};

// Get insights by type
exports.getInsightsByType = async (req, res, next) => {
  try {
    const { type } = req.params;

    const insights = await AIInsight.getInsightsByType(req.user._id, type);

    res.json({
      status: 'success',
      data: insights
    });
  } catch (error) {
    next(error);
  }
};

// Get high impact insights
exports.getHighImpactInsights = async (req, res, next) => {
  try {
    const insights = await AIInsight.getHighImpactInsights(req.user._id);

    res.json({
      status: 'success',
      data: insights
    });
  } catch (error) {
    next(error);
  }
};

// Get recent insights
exports.getRecentInsights = async (req, res, next) => {
  try {
    const { days = 7 } = req.query;

    const insights = await AIInsight.getRecentInsights(req.user._id, parseInt(days));

    res.json({
      status: 'success',
      data: insights
    });
  } catch (error) {
    next(error);
  }
};

// Get AI insights statistics
exports.getAIInsightStats = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    const query = { user: req.user._id };

    if (startDate && endDate) {
      query.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    // Get insight statistics
    const stats = await AIInsight.aggregate([
      { $match: query },
      {
        $group: {
          _id: null,
          totalInsights: { $sum: 1 },
          readInsights: { $sum: { $cond: ['$read', 1, 0] } },
          unreadInsights: { $sum: { $cond: ['$read', 0, 1] } },
          highImpactInsights: { $sum: { $cond: [{ $eq: ['$impactLevel', 'high'] }, 1, 0] } },
          moderateImpactInsights: { $sum: { $cond: [{ $eq: ['$impactLevel', 'moderate'] }, 1, 0] } },
          lowImpactInsights: { $sum: { $cond: [{ $eq: ['$impactLevel', 'low'] }, 1, 0] } }
        }
      }
    ]);

    // Get type-wise insights
    const typeStats = await AIInsight.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          readCount: { $sum: { $cond: ['$read', 1, 0] } },
          avgImpactScore: { $avg: { $cond: [{ $eq: ['$impactLevel', 'high'] }, 3, { $cond: [{ $eq: ['$impactLevel', 'moderate'] }, 2, 1] }] } }
        }
      },
      { $sort: { count: -1 } }
    ]);

    // Get source-wise insights
    const sourceStats = await AIInsight.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$source',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json({
      status: 'success',
      data: {
        overview: stats[0] || {
          totalInsights: 0,
          readInsights: 0,
          unreadInsights: 0,
          highImpactInsights: 0,
          moderateImpactInsights: 0,
          lowImpactInsights: 0
        },
        typeStats,
        sourceStats
      }
    });
  } catch (error) {
    next(error);
  }
};

// Generate AI investment tips using Groq API
exports.generateInvestmentTips = async (req, res, next) => {
  try {
    const { context, userProfile } = req.body;

    // Generate contextual prompt for investment tips
    const tipPrompt = generateInvestmentTipPrompt(context, userProfile);
    
    const aiResponse = await queryGroqLLMWithRetry(tipPrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    // Parse the AI response to extract tips
    const tips = parseInvestmentTips(aiResponse);

    res.json({
      success: true,
      data: {
        tips: tips,
        generatedAt: new Date(),
        source: 'Groq AI'
      },
      message: 'Investment tips generated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get trending investments using AI analysis
exports.getTrendingInvestments = async (req, res, next) => {
  try {
    const { marketContext, userPreferences } = req.body;

    // Generate prompt for trending investments analysis
    const trendingPrompt = generateTrendingInvestmentsPrompt(marketContext, userPreferences);
    
    const aiResponse = await queryGroqLLMWithRetry(trendingPrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    // Parse the AI response to extract trending investments
    const trendingInvestments = parseTrendingInvestments(aiResponse);

    res.json({
      success: true,
      data: {
        trendingInvestments: trendingInvestments,
        generatedAt: new Date(),
        source: 'Groq AI Market Analysis'
      },
      message: 'Trending investments analysis completed'
    });
  } catch (error) {
    next(error);
  }
};

// Get daily investment tip
exports.getDailyInvestmentTip = async (req, res, next) => {
  try {
    const { userContext } = req.body;

    // Generate a daily investment tip prompt
    const dailyTipPrompt = generateDailyTipPrompt(userContext);
    
    const aiResponse = await queryGroqLLMWithRetry(dailyTipPrompt, {
      maxRetries: 2,
      retryDelay: 1000
    });

    // Parse the AI response to extract the daily tip
    const dailyTip = parseDailyTip(aiResponse);

    res.json({
      success: true,
      data: {
        tip: dailyTip,
        generatedAt: new Date(),
        source: 'Groq AI Daily Tip'
      },
      message: 'Daily investment tip generated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Helper function to generate AI prompts
function generateAIPrompt(type, context = '') {
  const prompts = {
    spending: `Analyze the user's spending patterns and provide actionable advice for better financial management. Context: ${context}. Provide a concise title and detailed content with specific recommendations.`,
    budget: `Create personalized budget optimization advice based on the user's financial situation. Context: ${context}. Include practical tips for budget allocation and spending control.`,
    investment: `Provide investment recommendations and portfolio optimization advice. Context: ${context}. Consider risk tolerance and financial goals in your recommendations.`,
    goal: `Help the user achieve their financial goals with strategic planning advice. Context: ${context}. Provide step-by-step guidance and milestone tracking suggestions.`,
    reminder: `Create smart financial reminders and alerts based on the user's patterns. Context: ${context}. Suggest proactive measures for better financial health.`,
    security: `Provide financial security and fraud prevention advice. Context: ${context}. Include best practices for protecting financial information and accounts.`,
    general: `Offer general financial wellness and money management advice. Context: ${context}. Focus on building healthy financial habits and long-term wealth.`
  };

  return prompts[type] || prompts.general;
}

// Helper function to generate financial advice prompts
function generateFinancialAdvicePrompt(category, context = '', userProfile = {}) {
  const basePrompt = `As a financial advisor, provide personalized advice for ${category}. `;
  const contextPrompt = context ? `User context: ${context}. ` : '';
  const profilePrompt = userProfile ? `User profile: ${JSON.stringify(userProfile)}. ` : '';
  
  return `${basePrompt}${contextPrompt}${profilePrompt}Provide practical, actionable advice that is easy to understand and implement. Keep the response focused and relevant to the user's situation.`;
}

// Helper function to generate spending analysis prompts
function generateSpendingAnalysisPrompt(transactions, timeFrame = 'monthly') {
  const transactionSummary = transactions.map(t => 
    `${t.category}: $${t.amount} on ${t.date}`
  ).join(', ');
  
  return `Analyze the following spending transactions for ${timeFrame} period: ${transactionSummary}. 
  Provide insights on spending patterns, identify areas for improvement, and suggest specific actions to optimize spending. 
  Focus on practical recommendations that can help reduce unnecessary expenses and improve financial health.`;
}

// Helper function to parse AI response
function parseAIResponse(response, type) {
  // Try to extract title and content from AI response
  const lines = response.split('\n').filter(line => line.trim());
  
  let title = '';
  let content = response;
  let impactLevel = 'moderate';

  // Look for title patterns
  if (lines.length > 0) {
    const firstLine = lines[0].trim();
    if (firstLine.length < 100 && (firstLine.endsWith(':') || firstLine.includes('Title:'))) {
      title = firstLine.replace('Title:', '').replace(':', '').trim();
      content = lines.slice(1).join('\n').trim();
    } else {
      // Generate title based on type and first few words
      title = `${type.charAt(0).toUpperCase() + type.slice(1)} Insight: ${firstLine.substring(0, 50)}...`;
    }
  }

  // Determine impact level based on content keywords
  const highImpactKeywords = ['urgent', 'critical', 'immediate', 'important', 'significant'];
  const lowImpactKeywords = ['consider', 'optional', 'suggestion', 'might', 'could'];
  
  const contentLower = content.toLowerCase();
  if (highImpactKeywords.some(keyword => contentLower.includes(keyword))) {
    impactLevel = 'high';
  } else if (lowImpactKeywords.some(keyword => contentLower.includes(keyword))) {
    impactLevel = 'low';
  }

  return {
    title: title || `${type.charAt(0).toUpperCase() + type.slice(1)} Financial Insight`,
    content: content,
    impactLevel: impactLevel
  };
} 

// Helper function to generate investment tip prompts
function generateInvestmentTipPrompt(context = '', userProfile = {}) {
  const basePrompt = `As a financial advisor, provide 3-5 actionable investment tips that are relevant for today's market conditions. `;
  const contextPrompt = context ? `User context: ${context}. ` : '';
  const profilePrompt = userProfile ? `User profile: ${JSON.stringify(userProfile)}. ` : '';
  
  return `${basePrompt}${contextPrompt}${profilePrompt}
  
  Please provide tips in the following JSON format:
  {
    "tips": [
      {
        "title": "Tip Title",
        "description": "Detailed explanation of the tip",
        "category": "investment_type",
        "risk_level": "low/medium/high",
        "action_items": ["action1", "action2"],
        "expected_impact": "short/long term benefit"
      }
    ]
  }
  
  Focus on practical, actionable advice that considers current market conditions, risk management, and diversification strategies.`;
}

// Helper function to generate trending investments prompt
function generateTrendingInvestmentsPrompt(marketContext = '', userPreferences = {}) {
  const basePrompt = `Analyze current market trends and provide 4-6 trending investment opportunities across different asset classes. `;
  const contextPrompt = marketContext ? `Market context: ${marketContext}. ` : '';
  const preferencesPrompt = userPreferences ? `User preferences: ${JSON.stringify(userPreferences)}. ` : '';
  
  return `${basePrompt}${contextPrompt}${preferencesPrompt}
  
  Please provide trending investments in the following JSON format:
  {
    "trendingInvestments": [
      {
        "name": "Investment Name",
        "description": "Brief description",
        "returns": "expected_return_percentage",
        "risk": "low/medium/high",
        "category": "asset_class",
        "symbol": "ticker_symbol",
        "trend_reason": "why it's trending",
        "recommendation": "buy/hold/watch"
      }
    ]
  }
  
  Include a mix of stocks, ETFs, bonds, and alternative investments. Consider current market sentiment, sector performance, and economic indicators.`;
}

// Helper function to generate daily tip prompt
function generateDailyTipPrompt(userContext = '') {
  const basePrompt = `Provide one concise, actionable investment tip for today. `;
  const contextPrompt = userContext ? `User context: ${userContext}. ` : '';
  
  return `${basePrompt}${contextPrompt}
  
  Please provide the tip in the following JSON format:
  {
    "tip": {
      "title": "Tip Title",
      "content": "Detailed explanation of the tip",
      "category": "investment_category",
      "difficulty": "beginner/intermediate/advanced",
      "time_horizon": "short/medium/long term"
    }
  }
  
  Make it practical, educational, and relevant to current market conditions. Keep it concise but informative.`;
}

// Helper function to parse investment tips from AI response
function parseInvestmentTips(response) {
  try {
    // Try to extract JSON from the response
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed.tips || [];
    }
    
    // Fallback: parse manually if JSON extraction fails
    const lines = response.split('\n').filter(line => line.trim());
    const tips = [];
    let currentTip = {};
    
    for (const line of lines) {
      if (line.includes('Title:') || line.includes('title:')) {
        if (Object.keys(currentTip).length > 0) {
          tips.push(currentTip);
        }
        currentTip = {
          title: line.split(':')[1]?.trim() || 'Investment Tip',
          description: '',
          category: 'general',
          risk_level: 'medium',
          action_items: [],
          expected_impact: 'long term'
        };
      } else if (line.includes('Description:') || line.includes('description:')) {
        currentTip.description = line.split(':')[1]?.trim() || '';
      } else if (line.includes('Category:') || line.includes('category:')) {
        currentTip.category = line.split(':')[1]?.trim() || 'general';
      } else if (line.includes('Risk:') || line.includes('risk:')) {
        currentTip.risk_level = line.split(':')[1]?.trim() || 'medium';
      }
    }
    
    if (Object.keys(currentTip).length > 0) {
      tips.push(currentTip);
    }
    
    return tips;
  } catch (error) {
    console.error('Error parsing investment tips:', error);
    // Return a default tip if parsing fails
    return [{
      title: 'Diversify Your Portfolio',
      description: 'Consider spreading your investments across different asset classes to reduce risk.',
      category: 'general',
      risk_level: 'medium',
      action_items: ['Review current portfolio', 'Add new asset classes'],
      expected_impact: 'long term'
    }];
  }
}

// Helper function to parse trending investments from AI response
function parseTrendingInvestments(response) {
  try {
    // Try to extract JSON from the response
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed.trendingInvestments || [];
    }
    
    // Fallback: parse manually if JSON extraction fails
    const lines = response.split('\n').filter(line => line.trim());
    const investments = [];
    let currentInvestment = {};
    
    for (const line of lines) {
      if (line.includes('Name:') || line.includes('name:')) {
        if (Object.keys(currentInvestment).length > 0) {
          investments.push(currentInvestment);
        }
        currentInvestment = {
          name: line.split(':')[1]?.trim() || 'Investment',
          description: '',
          returns: '+0.0%',
          risk: 'medium',
          category: 'general',
          symbol: '',
          trend_reason: '',
          recommendation: 'watch'
        };
      } else if (line.includes('Description:') || line.includes('description:')) {
        currentInvestment.description = line.split(':')[1]?.trim() || '';
      } else if (line.includes('Returns:') || line.includes('returns:')) {
        currentInvestment.returns = line.split(':')[1]?.trim() || '+0.0%';
      } else if (line.includes('Risk:') || line.includes('risk:')) {
        currentInvestment.risk = line.split(':')[1]?.trim() || 'medium';
      } else if (line.includes('Category:') || line.includes('category:')) {
        currentInvestment.category = line.split(':')[1]?.trim() || 'general';
      } else if (line.includes('Symbol:') || line.includes('symbol:')) {
        currentInvestment.symbol = line.split(':')[1]?.trim() || '';
      }
    }
    
    if (Object.keys(currentInvestment).length > 0) {
      investments.push(currentInvestment);
    }
    
    return investments;
  } catch (error) {
    console.error('Error parsing trending investments:', error);
    // Return default trending investments if parsing fails
    return [
      {
        name: 'S&P 500 ETF',
        description: 'Broad market index fund',
        returns: '+15.2%',
        risk: 'low',
        category: 'stocks',
        symbol: 'SPY',
        trend_reason: 'Market recovery and economic growth',
        recommendation: 'buy'
      },
      {
        name: 'Technology Stocks',
        description: 'Growth technology companies',
        returns: '+22.8%',
        risk: 'medium',
        category: 'stocks',
        symbol: 'QQQ',
        trend_reason: 'AI and innovation driving growth',
        recommendation: 'buy'
      }
    ];
  }
}

// Helper function to parse daily tip from AI response
function parseDailyTip(response) {
  try {
    // Try to extract JSON from the response
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed.tip || {};
    }
    
    // Fallback: parse manually if JSON extraction fails
    const lines = response.split('\n').filter(line => line.trim());
    const tip = {
      title: 'Daily Investment Tip',
      content: response,
      category: 'general',
      difficulty: 'beginner',
      time_horizon: 'medium term'
    };
    
    for (const line of lines) {
      if (line.includes('Title:') || line.includes('title:')) {
        tip.title = line.split(':')[1]?.trim() || 'Daily Investment Tip';
      } else if (line.includes('Content:') || line.includes('content:')) {
        tip.content = line.split(':')[1]?.trim() || response;
      } else if (line.includes('Category:') || line.includes('category:')) {
        tip.category = line.split(':')[1]?.trim() || 'general';
      } else if (line.includes('Difficulty:') || line.includes('difficulty:')) {
        tip.difficulty = line.split(':')[1]?.trim() || 'beginner';
      } else if (line.includes('Time Horizon:') || line.includes('time_horizon:')) {
        tip.time_horizon = line.split(':')[1]?.trim() || 'medium term';
      }
    }
    
    return tip;
  } catch (error) {
    console.error('Error parsing daily tip:', error);
    // Return a default tip if parsing fails
    return {
      title: 'Start Investing Early',
      content: 'The earlier you start investing, the more time your money has to grow through compound interest.',
      category: 'general',
      difficulty: 'beginner',
      time_horizon: 'long term'
    };
  }
} 