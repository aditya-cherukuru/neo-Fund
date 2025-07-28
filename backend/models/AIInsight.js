const mongoose = require('mongoose');

const aiInsightSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  title: {
    type: String,
    required: [true, 'Insight title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: [true, 'Insight content is required'],
    trim: true,
    maxlength: [2000, 'Content cannot exceed 2000 characters']
  },
  type: {
    type: String,
    required: [true, 'Insight type is required'],
    enum: {
      values: ['spending', 'budget', 'investment', 'goal', 'reminder', 'security', 'tax', 'general'],
      message: 'Type must be one of: spending, budget, investment, goal, reminder, security, tax, general'
    }
  },
  source: {
    type: String,
    enum: {
      values: ['LLM', 'rule_engine', 'external_api'],
      message: 'Source must be one of: LLM, rule_engine, external_api'
    },
    default: 'LLM'
  },
  impactLevel: {
    type: String,
    required: [true, 'Impact level is required'],
    enum: {
      values: ['low', 'moderate', 'high'],
      message: 'Impact level must be one of: low, moderate, high'
    }
  },
  createdByAI: {
    type: Boolean,
    default: true
  },
  read: {
    type: Boolean,
    default: false
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
    validate: {
      validator: function(value) {
        return value && typeof value === 'object';
      },
      message: 'Metadata must be a valid object'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for age of insight in days
aiInsightSchema.virtual('ageInDays').get(function() {
  const now = new Date();
  const created = new Date(this.createdAt);
  return Math.floor((now - created) / (1000 * 60 * 60 * 24));
});

// Virtual for freshness status
aiInsightSchema.virtual('freshnessStatus').get(function() {
  const age = this.ageInDays;
  if (age <= 1) return 'fresh';
  if (age <= 7) return 'recent';
  if (age <= 30) return 'stale';
  return 'old';
});

// Virtual for priority score (for sorting)
aiInsightSchema.virtual('priorityScore').get(function() {
  const impactScores = { low: 1, moderate: 2, high: 3 };
  const freshnessScores = { fresh: 4, recent: 3, stale: 2, old: 1 };
  const readScores = { true: 0, false: 2 }; // Unread insights get higher priority
  
  return impactScores[this.impactLevel] * freshnessScores[this.freshnessStatus] * readScores[this.read];
});

// Virtual for actionability score
aiInsightSchema.virtual('actionabilityScore').get(function() {
  const typeScores = {
    'spending': 3,
    'budget': 3,
    'investment': 2,
    'goal': 2,
    'reminder': 1,
    'security': 3,
    'general': 1
  };
  
  const impactScores = { low: 1, moderate: 2, high: 3 };
  
  return typeScores[this.type] * impactScores[this.impactLevel];
});

// Virtual for insight category
aiInsightSchema.virtual('category').get(function() {
  const categories = {
    'spending': 'Spending Analysis',
    'budget': 'Budget Optimization',
    'investment': 'Investment Advice',
    'goal': 'Goal Planning',
    'reminder': 'Financial Reminders',
    'security': 'Security & Fraud',
    'general': 'General Tips'
  };
  
  return categories[this.type] || 'General';
});

// Indexes for better query performance
aiInsightSchema.index({ user: 1, createdAt: -1 });
aiInsightSchema.index({ user: 1, type: 1 });
aiInsightSchema.index({ user: 1, impactLevel: 1 });
aiInsightSchema.index({ user: 1, read: 1 });
aiInsightSchema.index({ user: 1, source: 1 });
aiInsightSchema.index({ createdAt: -1 }); // For global insights

// Pre-save middleware to validate content length
aiInsightSchema.pre('save', function(next) {
  if (this.content.length < 10) {
    return next(new Error('Insight content must be at least 10 characters long'));
  }
  next();
});

// Instance method to mark as read
aiInsightSchema.methods.markAsRead = function() {
  this.read = true;
  return this.save();
};

// Instance method to mark as unread
aiInsightSchema.methods.markAsUnread = function() {
  this.read = false;
  return this.save();
};

// Instance method to update content
aiInsightSchema.methods.updateContent = function(newContent) {
  this.content = newContent;
  this.updatedAt = new Date();
  return this.save();
};

// Instance method to get insight summary
aiInsightSchema.methods.getSummary = function() {
  return {
    id: this._id,
    title: this.title,
    type: this.type,
    impactLevel: this.impactLevel,
    read: this.read,
    ageInDays: this.ageInDays,
    priorityScore: this.priorityScore
  };
};

// Static method to get user's unread insights
aiInsightSchema.statics.getUnreadInsights = function(userId) {
  return this.find({
    user: userId,
    read: false
  }).sort({ createdAt: -1 });
};

// Static method to get user's insights by type
aiInsightSchema.statics.getInsightsByType = function(userId, type) {
  return this.find({
    user: userId,
    type: type
  }).sort({ createdAt: -1 });
};

// Static method to get high impact insights
aiInsightSchema.statics.getHighImpactInsights = function(userId) {
  return this.find({
    user: userId,
    impactLevel: 'high'
  }).sort({ createdAt: -1 });
};

// Static method to get recent insights (last 7 days)
aiInsightSchema.statics.getRecentInsights = function(userId, days = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);
  
  return this.find({
    user: userId,
    createdAt: { $gte: cutoffDate }
  }).sort({ createdAt: -1 });
};

// Static method to get insights by source
aiInsightSchema.statics.getInsightsBySource = function(userId, source) {
  return this.find({
    user: userId,
    source: source
  }).sort({ createdAt: -1 });
};

// Static method to get top priority insights
aiInsightSchema.statics.getTopPriorityInsights = function(userId, limit = 10) {
  return this.find({
    user: userId
  })
  .sort({ priorityScore: -1 })
  .limit(limit);
};

// Static method to get insights for dashboard
aiInsightSchema.statics.getDashboardInsights = function(userId, limit = 5) {
  return this.find({
    user: userId,
    read: false
  })
  .sort({ priorityScore: -1 })
  .limit(limit);
};

// Static method to get insights by impact level
aiInsightSchema.statics.getInsightsByImpactLevel = function(userId, impactLevel) {
  return this.find({
    user: userId,
    impactLevel: impactLevel
  }).sort({ createdAt: -1 });
};

// Static method to get actionable insights
aiInsightSchema.statics.getActionableInsights = function(userId) {
  return this.find({
    user: userId,
    type: { $in: ['spending', 'budget', 'investment', 'security'] }
  }).sort({ actionabilityScore: -1 });
};

// Static method to get insights count by type
aiInsightSchema.statics.getInsightsCountByType = function(userId) {
  return this.aggregate([
    { $match: { user: mongoose.Types.ObjectId(userId) } },
    { $group: { _id: '$type', count: { $sum: 1 } } },
    { $sort: { count: -1 } }
  ]);
};

// Static method to get insights count by read status
aiInsightSchema.statics.getInsightsCountByReadStatus = function(userId) {
  return this.aggregate([
    { $match: { user: mongoose.Types.ObjectId(userId) } },
    { $group: { _id: '$read', count: { $sum: 1 } } }
  ]);
};

// Clear any existing model to prevent OverwriteModelError
mongoose.models = {};

// Export the model with explicit collection name
module.exports = mongoose.model('AIInsight', aiInsightSchema, 'ai_insights'); 