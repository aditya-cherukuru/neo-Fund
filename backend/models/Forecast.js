const mongoose = require('mongoose');

const ForecastSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  timestamp: { type: Date, default: Date.now },
  userInput: { type: Object, required: true },
  forecastResult: { type: Object, required: true },
  metadata: { type: Object, default: {} },
});

module.exports = mongoose.model('Forecast', ForecastSchema); 