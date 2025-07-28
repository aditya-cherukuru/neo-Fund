const Investment = require('../models/Investment');
const { AppError } = require('../middleware/errorHandler');

// Simple in-memory cache for historical data
const historicalDataCache = new Map();
const CACHE_EXPIRY = 5 * 60 * 1000; // 5 minutes in milliseconds

// Helper function to get cached data
function getCachedData(symbol, type, interval, duration = 10) {
  const cacheKey = `${symbol}_${type}_${interval}_${duration}`;
  const cached = historicalDataCache.get(cacheKey);
  
  if (cached && (Date.now() - cached.timestamp) < CACHE_EXPIRY) {
    console.log(`Returning cached data for ${symbol}`);
    return cached.data;
  }
  
  return null;
}

// Helper function to set cached data
function setCachedData(symbol, type, interval, data, duration = 10) {
  const cacheKey = `${symbol}_${type}_${interval}_${duration}`;
  historicalDataCache.set(cacheKey, {
    data: data,
    timestamp: Date.now()
  });
  
  // Clean up old cache entries (keep only last 100 entries)
  if (historicalDataCache.size > 100) {
    const entries = Array.from(historicalDataCache.entries());
    entries.sort((a, b) => a[1].timestamp - b[1].timestamp);
    const toDelete = entries.slice(0, entries.length - 100);
    toDelete.forEach(([key]) => historicalDataCache.delete(key));
  }
}

// Get all investments for a user
exports.getAllInvestments = async (req, res, next) => {
  try {
    const { type, status, category, accountId } = req.query;
    const query = { user: req.user._id };

    if (type) {
      query.type = type;
    }

    if (status) {
      query.status = status;
    }

    if (category) {
      query.category = category;
    }

    if (accountId) {
      query.accountId = accountId;
    }

    const investments = await Investment.find(query)
      .sort({ purchaseDate: -1 })
      .populate('user', 'name email')
      .populate('accountId', 'name type');

    res.json({
      status: 'success',
      data: investments
    });
  } catch (error) {
    next(error);
  }
};

// Get investment by ID
exports.getInvestmentById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const investment = await Investment.findOne({
      _id: id,
      user: req.user._id
    })
      .populate('user', 'name email')
      .populate('accountId', 'name type');

    if (!investment) {
      throw new AppError('Investment not found', 404);
    }

    res.json({
      status: 'success',
      data: investment
    });
  } catch (error) {
    next(error);
  }
};

// Create a new investment
exports.createInvestment = async (req, res, next) => {
  try {
    const {
      name,
      type,
      category,
      amount,
      currency,
      purchaseDate,
      accountId,
      symbol,
      shares,
      purchasePrice,
      currentPrice,
      description,
      status,
      riskLevel,
      expectedReturn,
      maturityDate,
      dividendYield,
      metadata,
      tags
    } = req.body;

    // Validate required fields
    if (!name || !type || !amount || !purchaseDate) {
      throw new AppError('Name, type, amount, and purchase date are required', 400);
    }

    // Validate amount
    if (amount <= 0) {
      throw new AppError('Investment amount must be greater than 0', 400);
    }

    // Validate purchase date
    const purchase = new Date(purchaseDate);
    if (isNaN(purchase.getTime())) {
      throw new AppError('Invalid purchase date', 400);
    }

    // Validate maturity date if provided
    let maturity = null;
    if (maturityDate) {
      maturity = new Date(maturityDate);
      if (isNaN(maturity.getTime()) || maturity <= purchase) {
        throw new AppError('Maturity date must be after purchase date', 400);
      }
    }

    // Validate shares and prices for stock investments
    if (type === 'stock' || type === 'mutual_fund') {
      if (!shares || shares <= 0) {
        throw new AppError('Number of shares must be greater than 0 for stock investments', 400);
      }
      if (!purchasePrice || purchasePrice <= 0) {
        throw new AppError('Purchase price must be greater than 0 for stock investments', 400);
      }
    }

    const investment = new Investment({
      user: req.user._id,
      name,
      type,
      category,
      amount,
      currency: currency || 'INR',
      purchaseDate: purchase,
      accountId,
      symbol,
      shares,
      purchasePrice,
      currentPrice: currentPrice || purchasePrice,
      description,
      status: status || 'active',
      riskLevel,
      expectedReturn,
      maturityDate: maturity,
      dividendYield,
      metadata: metadata || {},
      tags: tags || []
    });

    await investment.save();

    res.status(201).json({
      status: 'success',
      data: investment
    });
  } catch (error) {
    next(error);
  }
};

// Update an investment
exports.updateInvestment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      name,
      type,
      category,
      amount,
      currency,
      purchaseDate,
      accountId,
      symbol,
      shares,
      purchasePrice,
      currentPrice,
      description,
      status,
      riskLevel,
      expectedReturn,
      maturityDate,
      dividendYield,
      metadata,
      tags
    } = req.body;

    const investment = await Investment.findOne({
      _id: id,
      user: req.user._id
    });

    if (!investment) {
      throw new AppError('Investment not found', 404);
    }

    // Validate amount if provided
    if (amount !== undefined && amount <= 0) {
      throw new AppError('Investment amount must be greater than 0', 400);
    }

    // Validate dates if provided
    if (purchaseDate) {
      const purchase = new Date(purchaseDate);
      if (isNaN(purchase.getTime())) {
        throw new AppError('Invalid purchase date', 400);
      }
    }

    if (maturityDate) {
      const maturity = new Date(maturityDate);
      const purchase = purchaseDate ? new Date(purchaseDate) : investment.purchaseDate;
      if (isNaN(maturity.getTime()) || maturity <= purchase) {
        throw new AppError('Maturity date must be after purchase date', 400);
      }
    }

    // Validate shares and prices for stock investments
    if ((type === 'stock' || type === 'mutual_fund') || 
        (investment.type === 'stock' || investment.type === 'mutual_fund')) {
      if (shares !== undefined && shares <= 0) {
        throw new AppError('Number of shares must be greater than 0 for stock investments', 400);
      }
      if (purchasePrice !== undefined && purchasePrice <= 0) {
        throw new AppError('Purchase price must be greater than 0 for stock investments', 400);
      }
    }

    // Update investment fields
    const updateFields = {};
    if (name !== undefined) updateFields.name = name;
    if (type !== undefined) updateFields.type = type;
    if (category !== undefined) updateFields.category = category;
    if (amount !== undefined) updateFields.amount = amount;
    if (currency !== undefined) updateFields.currency = currency;
    if (purchaseDate !== undefined) updateFields.purchaseDate = new Date(purchaseDate);
    if (accountId !== undefined) updateFields.accountId = accountId;
    if (symbol !== undefined) updateFields.symbol = symbol;
    if (shares !== undefined) updateFields.shares = shares;
    if (purchasePrice !== undefined) updateFields.purchasePrice = purchasePrice;
    if (currentPrice !== undefined) updateFields.currentPrice = currentPrice;
    if (description !== undefined) updateFields.description = description;
    if (status !== undefined) updateFields.status = status;
    if (riskLevel !== undefined) updateFields.riskLevel = riskLevel;
    if (expectedReturn !== undefined) updateFields.expectedReturn = expectedReturn;
    if (maturityDate !== undefined) updateFields.maturityDate = maturityDate ? new Date(maturityDate) : null;
    if (dividendYield !== undefined) updateFields.dividendYield = dividendYield;
    if (metadata !== undefined) updateFields.metadata = metadata;
    if (tags !== undefined) updateFields.tags = tags;

    Object.assign(investment, updateFields);

    await investment.save();

    res.json({
      status: 'success',
      data: investment
    });
  } catch (error) {
    next(error);
  }
};

// Delete an investment
exports.deleteInvestment = async (req, res, next) => {
  try {
    const { id } = req.params;

    const investment = await Investment.findOne({
      _id: id,
      user: req.user._id
    });

    if (!investment) {
      throw new AppError('Investment not found', 404);
    }

    await Investment.deleteOne({ _id: id });

    res.json({
      status: 'success',
      data: null,
      message: 'Investment deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get investment statistics
exports.getInvestmentStats = async (req, res, next) => {
  try {
    const { type, status, startDate, endDate } = req.query;
    const query = { user: req.user._id };

    if (type) {
      query.type = type;
    }

    if (status) {
      query.status = status;
    }

    if (startDate && endDate) {
      query.purchaseDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    // Get investment statistics
    const stats = await Investment.aggregate([
      { $match: query },
      {
        $group: {
          _id: null,
          totalInvestments: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          avgAmount: { $avg: '$amount' },
          activeInvestments: { $sum: { $cond: [{ $eq: ['$status', 'active'] }, 1, 0] } },
          maturedInvestments: { $sum: { $cond: [{ $eq: ['$status', 'matured'] }, 1, 0] } },
          soldInvestments: { $sum: { $cond: [{ $eq: ['$status', 'sold'] }, 1, 0] } }
        }
      }
    ]);

    // Get type-wise investments
    const typeStats = await Investment.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$type',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 },
          avgAmount: { $avg: '$amount' }
        }
      },
      { $sort: { totalAmount: -1 } }
    ]);

    // Get category-wise investments
    const categoryStats = await Investment.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$category',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { totalAmount: -1 } }
    ]);

    // Get risk level distribution
    const riskStats = await Investment.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$riskLevel',
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json({
      status: 'success',
      data: {
        overview: stats[0] || {
          totalInvestments: 0,
          totalAmount: 0,
          avgAmount: 0,
          activeInvestments: 0,
          maturedInvestments: 0,
          soldInvestments: 0
        },
        typeStats,
        categoryStats,
        riskStats
      }
    });
  } catch (error) {
    next(error);
  }
};

// Update investment current price
exports.updateCurrentPrice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { currentPrice } = req.body;

    if (!currentPrice || currentPrice <= 0) {
      throw new AppError('Current price must be greater than 0', 400);
    }

    const investment = await Investment.findOne({
      _id: id,
      user: req.user._id
    });

    if (!investment) {
      throw new AppError('Investment not found', 404);
    }

    investment.currentPrice = currentPrice;

    // Calculate current value for stock investments
    if (investment.type === 'stock' || investment.type === 'mutual_fund') {
      if (investment.shares) {
        investment.currentValue = investment.shares * currentPrice;
      }
    } else {
      investment.currentValue = investment.amount;
    }

    // Calculate return percentage
    if (investment.purchasePrice) {
      investment.returnPercentage = ((currentPrice - investment.purchasePrice) / investment.purchasePrice) * 100;
    }

    await investment.save();

    res.json({
      status: 'success',
      data: investment
    });
  } catch (error) {
    next(error);
  }
};

// Get portfolio performance
exports.getPortfolioPerformance = async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    const query = { user: req.user._id, status: 'active' };

    if (startDate && endDate) {
      query.purchaseDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const investments = await Investment.find(query);

    let totalInvested = 0;
    let totalCurrentValue = 0;
    let totalReturn = 0;
    let totalReturnPercentage = 0;

    investments.forEach(investment => {
      totalInvested += investment.amount;
      
      if (investment.currentValue) {
        totalCurrentValue += investment.currentValue;
      } else {
        totalCurrentValue += investment.amount;
      }
    });

    if (totalInvested > 0) {
      totalReturn = totalCurrentValue - totalInvested;
      totalReturnPercentage = (totalReturn / totalInvested) * 100;
    }

    res.json({
      status: 'success',
      data: {
        totalInvested,
        totalCurrentValue,
        totalReturn,
        totalReturnPercentage,
        investmentCount: investments.length
      }
    });
  } catch (error) {
    next(error);
  }
}; 

// AI-Powered Investment Forecasting
const AIInvestmentForecastService = require('../services/aiInvestmentForecastService');



// Generate AI-powered investment forecast
exports.generateForecast = async (req, res, next) => {
  try {
    const {
      investmentAmount,
      duration,
      riskAppetite,
      investmentType,
      expectedReturn,
      currency
    } = req.body;

    // Validate inputs
    if (!investmentAmount || investmentAmount <= 0) {
      throw new AppError('Investment amount must be greater than 0', 400);
    }
    if (!duration || duration <= 0 || duration > 30) {
      throw new AppError('Duration must be between 1 and 30 years', 400);
    }
    if (!riskAppetite || !['low', 'medium', 'high'].includes(riskAppetite.toLowerCase())) {
      throw new AppError('Risk appetite must be low, medium, or high', 400);
    }
    if (!investmentType) {
      throw new AppError('Investment type is required', 400);
    }
    if (!expectedReturn || expectedReturn < 0 || expectedReturn > 100) {
      throw new AppError('Expected return must be between 0 and 100', 400);
    }

    // Calculate risk-adjusted return based on risk appetite
    let baseReturn = expectedReturn;
    let volatility = 0;
    
    switch (riskAppetite.toLowerCase()) {
      case 'low':
        baseReturn = Math.min(expectedReturn, 6.0);
        volatility = 8.0;
        break;
      case 'medium':
        baseReturn = expectedReturn;
        volatility = 15.0;
        break;
      case 'high':
        baseReturn = Math.max(expectedReturn, 12.0);
        volatility = 25.0;
        break;
    }

    // Generate year-wise growth data
    const yearWiseGrowth = [];
    let currentValue = investmentAmount;
    
    for (let year = 1; year <= duration; year++) {
      // Add some randomness to make it more realistic
      let annualReturn = baseReturn + (Math.random() - 0.5) * volatility;
      annualReturn = Math.max(annualReturn, -20.0); // Cap losses at 20%
      annualReturn = Math.min(annualReturn, 50.0); // Cap gains at 50%
      
      currentValue = currentValue * (1 + annualReturn / 100);
      
      yearWiseGrowth.push({
        year: year,
        value: currentValue,
        growth: annualReturn,
        cumulativeGrowth: ((currentValue - investmentAmount) / investmentAmount) * 100,
      });
    }

    // Calculate final metrics
    const projectedValue = yearWiseGrowth[yearWiseGrowth.length - 1].value;
    const totalGrowth = ((projectedValue - investmentAmount) / investmentAmount) * 100;
    
    // Generate insights based on the forecast
    const insights = generateInsights({
      investmentAmount,
      projectedValue,
      totalGrowth,
      riskAppetite,
      investmentType,
      duration,
    });

    // Risk analysis
    const riskAnalysis = {
      volatility: volatility,
      expectedReturn: baseReturn,
      riskRewardRatio: baseReturn / volatility,
      maxDrawdown: volatility * 0.5, // Estimated max drawdown
      sharpeRatio: baseReturn / volatility, // Simplified Sharpe ratio
    };

    const forecastData = {
      forecast: {
        projectedValue: projectedValue,
        totalGrowth: totalGrowth,
        annualizedReturn: Math.pow(projectedValue / investmentAmount, 1.0 / duration) - 1,
        initialInvestment: investmentAmount,
        duration: duration,
      },
      yearWiseGrowth: yearWiseGrowth,
      insights: insights,
      riskAnalysis: riskAnalysis,
      parameters: {
        investmentAmount: investmentAmount,
        duration: duration,
        riskAppetite: riskAppetite,
        investmentType: investmentType,
        expectedReturn: expectedReturn,
        currency: currency,
        generatedAt: new Date().toISOString(),
      },
    };

    res.json({
      status: 'success',
      data: forecastData
    });
  } catch (error) {
    next(error);
  }
};

// Generate AI-like insights based on forecast data
function generateInsights({
  investmentAmount,
  projectedValue,
  totalGrowth,
  riskAppetite,
  investmentType,
  duration,
}) {
  const insights = [];

  // Basic growth insight
  if (totalGrowth > 0) {
    insights.push(`Your investment is projected to grow by ${totalGrowth.toFixed(1)}% over ${duration} years, potentially reaching $${projectedValue.toFixed(2)}.`);
  } else {
    insights.push(`Based on current market conditions, your investment may experience a decline of ${Math.abs(totalGrowth).toFixed(1)}% over ${duration} years.`);
  }

  // Risk level insight
  switch (riskAppetite.toLowerCase()) {
    case 'low':
      insights.push(`Your conservative approach with ${riskAppetite} risk appetite provides stability but may limit growth potential.`);
      break;
    case 'medium':
      insights.push(`Your balanced ${riskAppetite} risk approach offers a good mix of growth potential and stability.`);
      break;
    case 'high':
      insights.push(`Your aggressive ${riskAppetite} risk strategy has higher growth potential but also increased volatility.`);
      break;
  }

  // Investment type insight
  switch (investmentType.toLowerCase()) {
    case 'stocks':
      insights.push('Stock investments typically offer higher returns but come with market volatility. Consider diversifying across sectors.');
      break;
    case 'mutual funds':
      insights.push('Mutual funds provide diversification and professional management, making them suitable for most investors.');
      break;
    case 'crypto':
      insights.push('Cryptocurrency investments are highly volatile and speculative. Only invest what you can afford to lose.');
      break;
    case 'bonds':
      insights.push('Bonds offer stability and regular income, making them ideal for conservative investors.');
      break;
    case 'etfs':
      insights.push('ETFs combine the benefits of stocks and mutual funds with lower fees and better liquidity.');
      break;
    case 'real estate':
      insights.push('Real estate investments provide tangible assets and potential rental income, but require significant capital.');
      break;
  }

  // Duration insight
  if (duration >= 10) {
    insights.push(`Long-term investments (${duration}+ years) typically benefit from compound growth and can weather market fluctuations.`);
  } else if (duration >= 5) {
    insights.push(`Medium-term investments (${duration} years) balance growth potential with manageable risk.`);
  } else {
    insights.push(`Short-term investments (${duration} years) may be more suitable for specific financial goals or if you need liquidity.`);
  }

  // Compound interest insight
  if (totalGrowth > 50) {
    insights.push('The power of compound interest is evident in your forecast, showing how small annual returns can lead to significant long-term growth.');
  }

  // Market timing insight
  insights.push('Remember that market timing is difficult. Regular investments (dollar-cost averaging) often perform better than trying to time the market.');

  // Diversification insight
  insights.push('Consider diversifying your portfolio across different asset classes to reduce risk and improve potential returns.');

  return insights;
}

// Search for symbols with auto-suggestions
exports.searchSymbols = async (req, res, next) => {
  console.log('Search symbols endpoint called');
  try {
    const { query, type = 'stocks' } = req.query;
    console.log('Query:', query, 'Type:', type);
    
    if (!query || query.length < 2) {
      console.log('Query too short, returning empty array');
      return res.json({
        status: 'success',
        data: []
      });
    }

    const cleanQuery = query.trim().toUpperCase();
    console.log(`Searching symbols for: ${cleanQuery}, type: ${type}`);

    const finnhubApiKey = process.env.FINNHUB_API_KEY;
      const twelveDataApiKey = process.env.TWELVE_DATA_API_KEY;

    let results = [];

    try {
      const promises = [];

      // Finnhub symbol search
      if (finnhubApiKey) {
        promises.push(
          fetch(`https://finnhub.io/api/v1/search?q=${encodeURIComponent(cleanQuery)}&token=${finnhubApiKey}`, {
            signal: AbortSignal.timeout(3000)
          }).then(async response => {
            if (!response.ok) return null;
          const data = await response.json();
            return data.result || [];
          }).catch(() => [])
        );
      }

      // Twelve Data symbol search
      if (twelveDataApiKey) {
        promises.push(
          fetch(`https://api.twelvedata.com/symbol_search?symbol=${encodeURIComponent(cleanQuery)}&apikey=${twelveDataApiKey}`, {
            signal: AbortSignal.timeout(3000)
          }).then(async response => {
            if (!response.ok) return null;
            const data = await response.json();
            return data.data || [];
          }).catch(() => [])
        );
      }

      const [finnhubResults, twelveDataResults] = await Promise.all(promises);

      // Process Finnhub results
      if (finnhubResults && finnhubResults.length > 0) {
        results.push(...finnhubResults.slice(0, 5).map(item => ({
          symbol: item.symbol,
          name: item.description || item.symbol,
          type: item.type || 'stock',
          exchange: item.primaryExchange || 'Unknown',
          source: 'Finnhub'
        })));
      }

      // Process Twelve Data results
      if (twelveDataResults && twelveDataResults.length > 0) {
        results.push(...twelveDataResults.slice(0, 5).map(item => ({
              symbol: item.symbol,
              name: item.instrument_name || item.symbol,
          type: item.instrument_type || 'stock',
          exchange: item.exchange || 'Unknown',
              source: 'Twelve Data'
            })));
    }

    // Remove duplicates and limit results
    const uniqueResults = results.filter((item, index, self) => 
      index === self.findIndex(t => t.symbol === item.symbol)
      ).slice(0, 10);

    res.json({
      status: 'success',
      data: uniqueResults
    });

    } catch (error) {
      console.error('Symbol search error:', error);
      res.json({
        status: 'success',
        data: []
      });
    }

  } catch (error) {
    next(error);
  }
};

// Get historical data for a symbol
exports.getHistoricalData = async (req, res, next) => {
  try {
    const { symbol, type, interval = 'monthly', duration = 10 } = req.body;
    
    if (!symbol) {
      throw new AppError('Symbol is required', 400);
    }

    // Clean the symbol - remove any extra text after dash
    const cleanSymbol = symbol.split(' - ')[0].trim().toUpperCase();
    
    console.log(`Fetching historical data for symbol: ${cleanSymbol}, type: ${type}, interval: ${interval}`);

    let historicalData = null;

    // Check cache first
    const cached = getCachedData(cleanSymbol, type, interval, duration);
    if (cached) {
      historicalData = cached;
    } else {
      // For crypto assets, try multiple APIs in parallel
      if (type && type.toLowerCase() === 'crypto') {
        try {
          // Map common crypto symbols to CoinGecko IDs
          const coinGeckoId = getCoinGeckoId(cleanSymbol);
          
          // Try CoinGecko API with proper error handling
          const coinGeckoPromise = fetch(`https://api.coingecko.com/api/v3/coins/${coinGeckoId}/market_chart?vs_currency=usd&days=365&interval=monthly`, {
            signal: AbortSignal.timeout(3000)
          }).then(async response => {
            if (!response.ok) {
              console.error('CoinGecko API error:', response.status, response.statusText);
              return null;
            }
            
            // Check if response is valid JSON
            const contentType = response.headers.get('content-type');
            if (!contentType || !contentType.includes('application/json')) {
              console.error('CoinGecko API returned non-JSON response:', await response.text());
              return null;
            }
            
            try {
              const data = await response.json();
              return data;
            } catch (error) {
              console.error('CoinGecko API JSON parse error:', error.message);
              return null;
            }
          }).catch(error => {
            console.error('CoinGecko API request failed:', error.message);
            return null;
          });

          // Try Binance API as backup with proper error handling
          const binanceLimit = Math.min(duration, 12);
          const binancePromise = fetch(`https://api.binance.com/api/v3/klines?symbol=${cleanSymbol}&interval=1M&limit=${binanceLimit}`, {
            signal: AbortSignal.timeout(2000)
          }).then(async response => {
            if (!response.ok) {
              console.error('Binance API error:', response.status, response.statusText);
              return null;
            }
            
            // Check if response is valid JSON
            const contentType = response.headers.get('content-type');
            if (!contentType || !contentType.includes('application/json')) {
              console.error('Binance API returned non-JSON response:', await response.text());
              return null;
            }
            
            try {
              const data = await response.json();
              return data;
            } catch (error) {
              console.error('Binance API JSON parse error:', error.message);
              return null;
            }
          }).catch(error => {
            console.error('Binance API request failed:', error.message);
            return null;
          });

          // Wait for first successful response
          const [coinGeckoData, binanceData] = await Promise.all([coinGeckoPromise, binancePromise]);
          
          if (coinGeckoData && coinGeckoData.prices && coinGeckoData.prices.length > 0) {
            const processedData = [];
            const prices = [];
            const dates = [];
            
            // Process data points based on duration (max 12 months for crypto)
            const maxDataPoints = Math.min(duration, 12);
            const recentPrices = coinGeckoData.prices.slice(-maxDataPoints);
            
            for (let i = 0; i < recentPrices.length; i++) {
              const [timestamp, price] = recentPrices[i];
              const date = new Date(timestamp);
              
              processedData.push({
                date: date.toISOString().substring(0, 10),
                close: price
              });
              
              prices.push(price);
              dates.push(date.toISOString().substring(0, 10));
            }
            
            const metrics = calculateMetrics(prices, dates);
            historicalData = {
              symbol: cleanSymbol,
              data: processedData,
              metrics: metrics,
              source: 'CoinGecko',
              requestedDuration: duration, // Add this for frontend reference
              actualDataPoints: processedData.length
            };
            setCachedData(cleanSymbol, type, interval, historicalData, duration);
          } else if (binanceData && binanceData.length > 0) {
            const processedData = [];
            const prices = [];
            const dates = [];
            
            // Limit data points based on duration
            const maxDataPoints = Math.min(duration, binanceData.length);
            const recentData = binanceData.slice(-maxDataPoints);
            
            for (let i = 0; i < recentData.length; i++) {
              const [openTime, open, high, low, close, volume] = recentData[i];
              const date = new Date(openTime);
              
              processedData.push({
                date: date.toISOString().substring(0, 10),
                open: parseFloat(open),
                high: parseFloat(high),
                low: parseFloat(low),
                close: parseFloat(close),
                volume: parseFloat(volume)
              });
              
              prices.push(parseFloat(close));
              dates.push(date.toISOString().substring(0, 10));
            }
            
            const metrics = calculateMetrics(prices, dates);
            historicalData = {
              symbol: cleanSymbol,
              data: processedData,
              metrics: metrics,
              source: 'Binance',
              requestedDuration: duration, // Add this for frontend reference
              actualDataPoints: processedData.length
            };
            setCachedData(cleanSymbol, type, interval, historicalData, duration);
          } else {
            console.log('No crypto data found from APIs, providing sample data for:', cleanSymbol);
            console.log('This may be due to:');
            console.log('- Invalid crypto symbol format');
            console.log('- API rate limiting');
            console.log('- Network connectivity issues');
            console.log('- API service unavailability');
            
            const sampleData = generateSampleData(cleanSymbol, interval, duration);
            historicalData = {
              ...sampleData,
              requestedDuration: duration,
              actualDataPoints: sampleData.data.length
            };
            setCachedData(cleanSymbol, type, interval, historicalData, duration);
          }
        } catch (error) {
          console.error('Crypto API error for', cleanSymbol, ':', error.message);
          console.log('Providing sample data due to API error');
          
          const sampleData = generateSampleData(cleanSymbol, interval, duration);
          historicalData = {
            ...sampleData,
            requestedDuration: duration,
            actualDataPoints: sampleData.data.length
          };
          setCachedData(cleanSymbol, type, interval, historicalData, duration);
        }
      } else {
        // For stocks/ETFs, use multiple APIs in parallel for better data coverage
        const finnhubApiKey = process.env.FINNHUB_API_KEY;
        const twelveDataApiKey = process.env.TWELVE_DATA_API_KEY;

        // Check if we have at least one API key configured
        if (!finnhubApiKey && !twelveDataApiKey) {
          throw new AppError('Please configure at least one API key. Get free keys from:\n- Finnhub: https://finnhub.io/\n- Twelve Data: https://twelvedata.com/', 400);
        }

        try {
          const promises = [];

          // Yahoo Finance (always try as fallback)
          promises.push(
            fetch(`https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(cleanSymbol)}?interval=1mo&range=1y`, {
              signal: AbortSignal.timeout(3000)
            }).then(response => response.ok ? response.json() : null).catch(() => null)
          );

          // Finnhub candle data (monthly) - if API key available
          if (finnhubApiKey) {
            promises.push(
              fetch(`https://finnhub.io/api/v1/stock/candle?symbol=${encodeURIComponent(cleanSymbol)}&resolution=M&from=${Math.floor(Date.now() / 1000) - (365 * 24 * 60 * 60)}&to=${Math.floor(Date.now() / 1000)}&token=${finnhubApiKey}`, {
                signal: AbortSignal.timeout(3000)
              }).then(async response => {
                if (!response.ok) {
                  console.error('Finnhub API error:', response.status, response.statusText);
                  return null;
                }
                
                const contentType = response.headers.get('content-type');
                if (!contentType || !contentType.includes('application/json')) {
                  console.error('Finnhub API returned non-JSON response:', await response.text());
                  return null;
                }
                
                const data = await response.json();
                if (data.error) {
                  console.error('Finnhub API error:', data.error);
                  return null;
                }
                
                return data;
              }).catch(error => {
                console.error('Finnhub API request failed:', error.message);
                return null;
              })
            );
          } else {
            promises.push(Promise.resolve(null));
          }

          // Twelve Data time series (monthly) - if API key available
          if (twelveDataApiKey) {
            const endDate = new Date();
            const startDate = new Date();
            startDate.setFullYear(startDate.getFullYear() - 1);
            
            promises.push(
              fetch(`https://api.twelvedata.com/time_series?symbol=${encodeURIComponent(cleanSymbol)}&interval=1month&start_date=${startDate.toISOString().split('T')[0]}&end_date=${endDate.toISOString().split('T')[0]}&apikey=${twelveDataApiKey}`, {
                signal: AbortSignal.timeout(3000)
              }).then(async response => {
                if (!response.ok) {
                  console.error('Twelve Data API error:', response.status, response.statusText);
                  return null;
                }
                
                const contentType = response.headers.get('content-type');
                if (!contentType || !contentType.includes('application/json')) {
                  console.error('Twelve Data API returned non-JSON response:', await response.text());
                  return null;
                }
                
                const data = await response.json();
                if (data.status !== 'ok' || data.code) {
                  console.error('Twelve Data API error:', data.message || data.code);
                  return null;
                }
                
                return data;
              }).catch(error => {
                console.error('Twelve Data API request failed:', error.message);
                return null;
              })
            );
          } else {
            promises.push(Promise.resolve(null));
          }

          const [yahooData, finnhubData, twelveDataData] = await Promise.all(promises);
          
          let data = null;
          let apiSource = 'none';
          
          // Process Yahoo Finance data first (preferred)
          if (yahooData && yahooData.chart && yahooData.chart.result && yahooData.chart.result[0]) {
            const result = yahooData.chart.result[0];
            const timestamps = result.timestamp;
            const quotes = result.indicators.quote[0];
            
            if (timestamps && quotes && quotes.close) {
              const processedData = [];
              const prices = [];
              const dates = [];
              
              // Process data points based on duration (max 12 months for stocks)
              const maxDataPoints = Math.min(duration, 12);
              const recentData = timestamps.slice(-maxDataPoints);
              
              for (let i = 0; i < recentData.length; i++) {
                if (quotes.close[i] !== null && quotes.close[i] !== undefined) {
                  const date = new Date(timestamps[i] * 1000);
                  const closePrice = quotes.close[i];
                  
                  processedData.push({
                    date: date.toISOString().substring(0, 10),
                    open: quotes.open[i] || closePrice,
                    high: quotes.high[i] || closePrice,
                    low: quotes.low[i] || closePrice,
                    close: closePrice,
                    volume: quotes.volume[i] || 0
                  });
                  
                  prices.push(closePrice);
                  dates.push(date.toISOString().substring(0, 10));
                }
              }
              
              if (prices.length > 0) {
                const metrics = calculateMetrics(prices, dates);
                historicalData = {
                  symbol: cleanSymbol,
                  data: processedData,
                  metrics: metrics,
                  source: 'Yahoo Finance',
                  requestedDuration: duration, // Add this for frontend reference
                  actualDataPoints: processedData.length
                };
                setCachedData(cleanSymbol, type, interval, historicalData, duration);
                data = { success: true };
                apiSource = 'yahoo';
              }
            }
          }
          
          // Fallback to Finnhub if Yahoo Finance failed
          if (!data && finnhubData && finnhubData.s === 'ok') {
            apiSource = 'finnhub';
            
            const timestamps = finnhubData.t;
            const opens = finnhubData.o;
            const highs = finnhubData.h;
            const lows = finnhubData.l;
            const closes = finnhubData.c;
            const volumes = finnhubData.v;
            
            if (timestamps && closes && closes.length > 0) {
              const processedData = [];
              const prices = [];
              const dates = [];
              
              // Process data points based on duration (max 12 months for stocks)
              const maxDataPoints = Math.min(duration, 12);
              const recentData = timestamps.slice(-maxDataPoints);
              
              for (let i = 0; i < recentData.length; i++) {
                const date = new Date(timestamps[i] * 1000);
                const closePrice = closes[i];
                
                processedData.push({
                  date: date.toISOString().substring(0, 10),
                  open: opens[i] || closePrice,
                  high: highs[i] || closePrice,
                  low: lows[i] || closePrice,
                  close: closePrice,
                  volume: volumes[i] || 0
                });
                
                prices.push(closePrice);
                dates.push(date.toISOString().substring(0, 10));
              }
              
              if (prices.length > 0) {
                const metrics = calculateMetrics(prices, dates);
                historicalData = {
                  symbol: cleanSymbol,
                  data: processedData,
                  metrics: metrics,
                  source: 'Finnhub',
                  requestedDuration: duration, // Add this for frontend reference
                  actualDataPoints: processedData.length
                };
                setCachedData(cleanSymbol, type, interval, historicalData, duration);
                data = { success: true };
              }
            }
          }
          
          // Fallback to Twelve Data if other sources failed
          if (!data && twelveDataData && twelveDataData.values && twelveDataData.values.length > 0) {
            apiSource = 'twelve_data';
            
            const values = twelveDataData.values;
            const processedData = [];
            const prices = [];
            const dates = [];
            
            // Process data points based on duration (max 12 months for stocks)
            const maxDataPoints = Math.min(duration, 12);
            const recentValues = values.slice(-maxDataPoints);
            
            for (let i = 0; i < recentValues.length; i++) {
              const value = recentValues[i];
              const date = new Date(value.datetime);
              const closePrice = parseFloat(value.close);
              
              processedData.push({
                date: date.toISOString().substring(0, 10),
                open: parseFloat(value.open) || closePrice,
                high: parseFloat(value.high) || closePrice,
                low: parseFloat(value.low) || closePrice,
                close: closePrice,
                volume: parseFloat(value.volume) || 0
              });
              
              prices.push(closePrice);
              dates.push(date.toISOString().substring(0, 10));
            }
            
            if (prices.length > 0) {
              const metrics = calculateMetrics(prices, dates);
              historicalData = {
                symbol: cleanSymbol,
                data: processedData,
                metrics: metrics,
                source: 'Twelve Data',
                requestedDuration: duration, // Add this for frontend reference
                actualDataPoints: processedData.length
              };
              setCachedData(cleanSymbol, type, interval, historicalData, duration);
              data = { success: true };
            }
          }
          
          // If no data from either source, provide sample data
          if (!data) {
            console.log('No data found from APIs, providing sample data for:', cleanSymbol);
            const sampleData = generateSampleData(cleanSymbol, interval, duration);
            historicalData = {
              ...sampleData,
              requestedDuration: duration,
              actualDataPoints: sampleData.data.length
            };
            setCachedData(cleanSymbol, type, interval, historicalData, duration);
          }
          
          console.log(`${apiSource.toUpperCase()} API Response for`, cleanSymbol, ':', apiSource !== 'none' ? 'Success' : 'Failed');
          
        } catch (error) {
          console.error('Error fetching stock data for', cleanSymbol, ':', error.message);
          console.log('Providing sample data due to API error/timeout for:', cleanSymbol);
          const sampleData = generateSampleData(cleanSymbol, interval, duration);
          historicalData = {
            ...sampleData,
            requestedDuration: duration,
            actualDataPoints: sampleData.data.length
          };
          setCachedData(cleanSymbol, type, interval, historicalData, duration); // Cache sample data
        }
      }
    }

    if (!historicalData) {
      throw new AppError(`Unable to fetch data for symbol "${cleanSymbol}". Please try a different symbol or check your internet connection.`, 500);
    }

    // Format response to match frontend expectations
    const responseData = {
      symbol: historicalData.symbol,
      prices: historicalData.data.map(item => item.close),
      dates: historicalData.data.map(item => item.date),
      metrics: historicalData.metrics,
      source: historicalData.source,
      requestedDuration: historicalData.requestedDuration,
      actualDataPoints: historicalData.actualDataPoints,
      // Also include the original data structure for compatibility
      data: historicalData.data
    };

    res.json({
      status: 'success',
      data: responseData
    });
  } catch (error) {
    next(error);
  }
};

// Helper function to map crypto symbols to CoinGecko IDs
function getCoinGeckoId(symbol) {
  const symbolMap = {
    'BTCUSDT': 'bitcoin',
    'BTC': 'bitcoin',
    'ETHUSDT': 'ethereum',
    'ETH': 'ethereum',
    'BNBUSDT': 'binancecoin',
    'BNB': 'binancecoin',
    'ADAUSDT': 'cardano',
    'ADA': 'cardano',
    'SOLUSDT': 'solana',
    'SOL': 'solana',
    'DOTUSDT': 'polkadot',
    'DOT': 'polkadot',
    'DOGEUSDT': 'dogecoin',
    'DOGE': 'dogecoin',
    'AVAXUSDT': 'avalanche-2',
    'AVAX': 'avalanche-2',
    'MATICUSDT': 'matic-network',
    'MATIC': 'matic-network',
    'LINKUSDT': 'chainlink',
    'LINK': 'chainlink',
    'UNIUSDT': 'uniswap',
    'UNI': 'uniswap',
    'LTCUSDT': 'litecoin',
    'LTC': 'litecoin',
    'BCHUSDT': 'bitcoin-cash',
    'BCH': 'bitcoin-cash',
    'XRPUSDT': 'ripple',
    'XRP': 'ripple',
    'ATOMUSDT': 'cosmos',
    'ATOM': 'cosmos',
    'FTMUSDT': 'fantom',
    'FTM': 'fantom',
    'NEARUSDT': 'near',
    'NEAR': 'near',
    'ALGOUSDT': 'algorand',
    'ALGO': 'algorand',
    'VETUSDT': 'vechain',
    'VET': 'vechain',
    'ICPUSDT': 'internet-computer',
    'ICP': 'internet-computer',
    'FILUSDT': 'filecoin',
    'FIL': 'filecoin',
    'TRXUSDT': 'tron',
    'TRX': 'tron',
    'ETCUSDT': 'ethereum-classic',
    'ETC': 'ethereum-classic',
    'XLMUSDT': 'stellar',
    'XLM': 'stellar',
    'HBARUSDT': 'hedera-hashgraph',
    'HBAR': 'hedera-hashgraph',
    'THETAUSDT': 'theta-token',
    'THETA': 'theta-token',
    'XTZUSDT': 'tezos',
    'XTZ': 'tezos'
  };
  
  return symbolMap[symbol] || symbol.toLowerCase();
}

// Helper function to generate sample data when API is rate limited (optimized)
function generateSampleData(symbol, interval, duration = 10) {
  const now = new Date();
  const data = [];
  const prices = [];
  const dates = [];
  
  // Use predefined base prices for faster generation
  const basePrices = {
    'AAPL': 175, 'MSFT': 350, 'GOOGL': 2800, 'TSLA': 250, 'BTCUSDT': 45000,
    'ETHUSDT': 3000, 'AMZN': 150, 'META': 300, 'NVDA': 500, 'NFLX': 400,
    'GOOG': 2800, 'META': 300, 'BRK.A': 500000, 'JNJ': 150, 'V': 250,
    'JPM': 150, 'PG': 150, 'UNH': 500, 'HD': 300, 'MA': 400
  };
  
  let basePrice = basePrices[symbol] || 100;
  
  // Generate data based on duration (max 12 months for performance)
  const maxMonths = Math.min(duration, 12);
  for (let i = maxMonths - 1; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    
    // Optimized trend calculation
    const trend = (Math.random() - 0.48) * 0.01; // Reduced volatility
    basePrice = basePrice * (1 + trend);
    basePrice = Math.max(basePrice, 1);
    
    const closePrice = basePrice;
    const openPrice = basePrice * (1 + (Math.random() - 0.5) * 0.01);
    const highPrice = Math.max(openPrice, closePrice) * 1.005;
    const lowPrice = Math.min(openPrice, closePrice) * 0.995;
    
    data.push({
      date: date.toISOString().substring(0, 10),
      open: Math.round(openPrice * 100) / 100,
      high: Math.round(highPrice * 100) / 100,
      low: Math.round(lowPrice * 100) / 100,
      close: Math.round(closePrice * 100) / 100,
      volume: Math.floor(Math.random() * 100000) + 10000
    });
    
    prices.push(closePrice);
    dates.push(date.toISOString().substring(0, 10));
  }
  
  const metrics = calculateMetrics(prices, dates);
  return {
    symbol: symbol,
    data: data,
    metrics: metrics,
    note: 'Sample data (API unavailable) - This is simulated data for demonstration purposes'
  };
}

// Helper function to calculate investment metrics (optimized)
function calculateMetrics(prices, dates) {
  if (prices.length === 0) return {};
  
  const currentPrice = prices[0];
  const oldestPrice = prices[prices.length - 1];
  const totalReturn = ((currentPrice - oldestPrice) / oldestPrice) * 100;
  
  // Optimize: Calculate returns, avg, variance, and find best/worst in single pass
  let sumReturns = 0;
  let sumSquaredReturns = 0;
  let maxReturn = -Infinity;
  let minReturn = Infinity;
  let bestPeriod = '';
  let worstPeriod = '';
  let validReturns = 0;
  
  for (let i = 1; i < prices.length; i++) {
    const returnRate = ((prices[i - 1] - prices[i]) / prices[i]) * 100;
    
    if (!isNaN(returnRate) && isFinite(returnRate)) {
      sumReturns += returnRate;
      sumSquaredReturns += returnRate * returnRate;
      validReturns++;
      
      if (returnRate > maxReturn) {
        maxReturn = returnRate;
        bestPeriod = dates[i];
      }
      if (returnRate < minReturn) {
        minReturn = returnRate;
        worstPeriod = dates[i];
      }
    }
  }
  
  const avgReturn = validReturns > 0 ? sumReturns / validReturns : 0;
  const variance = validReturns > 0 ? (sumSquaredReturns / validReturns) - (avgReturn * avgReturn) : 0;
  const volatility = Math.sqrt(Math.max(0, variance));
  
  return {
    currentPrice: currentPrice,
    oldestPrice: oldestPrice,
    totalReturn: totalReturn,
    volatility: volatility,
    avgReturn: avgReturn,
    bestPeriod: {
      date: bestPeriod,
      return: maxReturn === -Infinity ? 0 : maxReturn
    },
    worstPeriod: {
      date: worstPeriod,
      return: minReturn === Infinity ? 0 : minReturn
    },
    dataPoints: prices.length,
    timeSpan: `${dates.length} periods`
  };
}

 