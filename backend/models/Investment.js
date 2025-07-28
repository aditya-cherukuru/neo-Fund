const mongoose = require('mongoose');

const investmentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  title: {
    type: String,
    required: [true, 'Investment title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  type: {
    type: String,
    required: [true, 'Investment type is required'],
    enum: {
      values: ['stocks', 'mutual_funds', 'crypto', 'real_estate', 'bonds', 'other'],
      message: 'Type must be one of: stocks, mutual_funds, crypto, real_estate, bonds, other'
    }
  },
  institution: {
    type: String,
    trim: true,
    maxlength: [100, 'Institution name cannot exceed 100 characters']
  },
  amountInvested: {
    type: Number,
    required: [true, 'Amount invested is required'],
    min: [0, 'Amount invested must be greater than or equal to 0'],
    validate: {
      validator: function(value) {
        return value >= 0;
      },
      message: 'Amount invested must be greater than or equal to 0'
    }
  },
  currentValue: {
    type: Number,
    default: 0,
    min: [0, 'Current value must be greater than or equal to 0'],
    validate: {
      validator: function(value) {
        return value >= 0;
      },
      message: 'Current value must be greater than or equal to 0'
    }
  },
  returnRate: {
    type: Number,
    min: [-100, 'Return rate cannot be less than -100%'],
    max: [1000, 'Return rate cannot exceed 1000%'],
    validate: {
      validator: function(value) {
        return value >= -100 && value <= 1000;
      },
      message: 'Return rate must be between -100% and 1000%'
    }
  },
  riskLevel: {
    type: String,
    required: [true, 'Risk level is required'],
    enum: {
      values: ['low', 'moderate', 'high'],
      message: 'Risk level must be one of: low, moderate, high'
    }
  },
  startDate: {
    type: Date,
    required: [true, 'Start date is required'],
    validate: {
      validator: function(value) {
        return value instanceof Date && !isNaN(value);
      },
      message: 'Start date must be a valid date'
    }
  },
  targetDate: {
    type: Date,
    validate: {
      validator: function(value) {
        if (value) {
          return value instanceof Date && !isNaN(value);
        }
        return true;
      },
      message: 'Target date must be a valid date'
    }
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  },
  status: {
    type: String,
    enum: {
      values: ['active', 'completed', 'liquidated'],
      message: 'Status must be one of: active, completed, liquidated'
    },
    default: 'active'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for total return amount
investmentSchema.virtual('totalReturn').get(function() {
  return this.currentValue - this.amountInvested;
});

// Virtual for total return percentage
investmentSchema.virtual('totalReturnPercentage').get(function() {
  if (this.amountInvested === 0) return 0;
  return ((this.currentValue - this.amountInvested) / this.amountInvested) * 100;
});

// Virtual for investment duration in days
investmentSchema.virtual('durationDays').get(function() {
  const now = new Date();
  const start = new Date(this.startDate);
  return Math.floor((now - start) / (1000 * 60 * 60 * 24));
});

// Virtual for investment performance status
investmentSchema.virtual('performanceStatus').get(function() {
  const returnPercentage = this.totalReturnPercentage;
  if (returnPercentage > 10) return 'excellent';
  if (returnPercentage > 5) return 'good';
  if (returnPercentage > 0) return 'positive';
  if (returnPercentage > -5) return 'neutral';
  return 'negative';
});

// Indexes for better query performance
investmentSchema.index({ user: 1, type: 1 });
investmentSchema.index({ user: 1, status: 1 });
investmentSchema.index({ user: 1, startDate: -1 });
investmentSchema.index({ user: 1, riskLevel: 1 });

// Pre-save middleware to validate dates
investmentSchema.pre('save', function(next) {
  if (this.targetDate && this.startDate >= this.targetDate) {
    return next(new Error('Target date must be after start date'));
  }
  next();
});

// Instance method to update current value
investmentSchema.methods.updateCurrentValue = function(value) {
  this.currentValue = Math.max(0, value);
  return this.save();
};

// Instance method to calculate return rate
investmentSchema.methods.calculateReturnRate = function() {
  if (this.amountInvested === 0) return 0;
  const durationYears = this.durationDays / 365;
  if (durationYears === 0) return 0;
  return ((this.currentValue - this.amountInvested) / this.amountInvested) / durationYears * 100;
};

// Instance method to check if investment is active
investmentSchema.methods.isActive = function() {
  return this.status === 'active';
};

// Static method to get user's active investments
investmentSchema.statics.getActiveInvestments = function(userId) {
  return this.find({
    user: userId,
    status: 'active'
  });
};

// Static method to get user's investments by type
investmentSchema.statics.getInvestmentsByType = function(userId, type) {
  return this.find({
    user: userId,
    type: type
  }).sort({ startDate: -1 });
};

// Static method to get user's portfolio value
investmentSchema.statics.getPortfolioValue = function(userId) {
  return this.aggregate([
    { $match: { user: mongoose.Types.ObjectId(userId), status: 'active' } },
    { $group: { _id: null, totalValue: { $sum: '$currentValue' } } }
  ]);
};

// Clear any existing model to prevent OverwriteModelError
mongoose.models = {};

// Export the model with explicit collection name
module.exports = mongoose.model('Investment', investmentSchema, 'investments'); 