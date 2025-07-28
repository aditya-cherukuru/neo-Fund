const Forecast = require('../models/Forecast');

// Save a new forecast for the logged-in user
exports.createForecast = async (req, res, next) => {
  try {
    const { symbol, type, investmentAmount, duration, riskLevel, historicalData, metrics, insights, generatedAt, reportType } = req.body;
    
    // Handle both old and new data structures
    if (reportType === 'investment_history') {
      // New investment history report structure
      const forecast = new Forecast({
        user: req.user._id,
        userInput: {
          symbol,
          type,
          investmentAmount,
          duration,
          riskLevel,
        },
        forecastResult: {
          historicalData,
          metrics,
          insights,
          keyTakeaways: insights, // For backward compatibility
        },
        metadata: {
          generatedAt,
          reportType,
        },
        timestamp: new Date(generatedAt || Date.now()),
      });
      await forecast.save();
      res.status(201).json({ status: 'success', data: forecast });
    } else {
      // Old forecast structure (for backward compatibility)
      const { userInput, forecastResult, metadata } = req.body;
      if (!userInput || !forecastResult) {
        return res.status(400).json({ message: 'userInput and forecastResult are required' });
      }
      const forecast = new Forecast({
        user: req.user._id,
        userInput,
        forecastResult,
        metadata: metadata || {},
      });
      await forecast.save();
      res.status(201).json({ status: 'success', data: forecast });
    }
  } catch (error) {
    next(error);
  }
};

// Get all forecasts for the logged-in user
exports.getForecasts = async (req, res, next) => {
  try {
    const forecasts = await Forecast.find({ user: req.user._id })
      .sort({ timestamp: -1 });
    
    // Transform the data to match the expected frontend structure
    const transformedForecasts = forecasts.map(forecast => {
      const forecastObj = forecast.toObject();
      
      // If it's an investment history report, transform to new structure
      if (forecastObj.metadata?.reportType === 'investment_history') {
        return {
          symbol: forecastObj.userInput.symbol,
          type: forecastObj.userInput.type,
          investmentAmount: forecastObj.userInput.investmentAmount,
          duration: forecastObj.userInput.duration,
          riskLevel: forecastObj.userInput.riskLevel,
          historicalData: forecastObj.forecastResult.historicalData,
          metrics: forecastObj.forecastResult.metrics,
          insights: forecastObj.forecastResult.insights,
          generatedAt: forecastObj.metadata.generatedAt || forecastObj.timestamp,
          reportType: forecastObj.metadata.reportType,
        };
      }
      
      // For old structure, keep as is
      return forecastObj;
    });
    
    res.json({ status: 'success', data: transformedForecasts });
  } catch (error) {
    next(error);
  }
};

// Optional: Delete a forecast by ID
exports.deleteForecast = async (req, res, next) => {
  try {
    const { id } = req.params;
    const forecast = await Forecast.findOneAndDelete({ _id: id, user: req.user._id });
    if (!forecast) {
      return res.status(404).json({ message: 'Forecast not found' });
    }
    res.json({ status: 'success', message: 'Forecast deleted' });
  } catch (error) {
    next(error);
  }
}; 