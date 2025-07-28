import 'package:flutter/foundation.dart';
import 'http_client.dart';

class DashboardService extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  
  // State variables
  bool _isLoading = false;
  String? _error;
  
  // Dashboard data
  DashboardSummary? _summary;
  List<Transaction> _recentTransactions = [];
  List<FinancialSuggestion> _smartSuggestions = [];
  List<Map<String, dynamic>> _spendingTrend = [];
  BudgetData? _budgetData;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardSummary? get summary => _summary;
  List<Transaction> get recentTransactions => _recentTransactions;
  List<FinancialSuggestion> get smartSuggestions => _smartSuggestions;
  List<Map<String, dynamic>> get spendingTrend => _spendingTrend;
  BudgetData? get budgetData => _budgetData;
  
  /// Get today's AI tip
  String getSmartTips() {
    // Empty tips - will be populated from backend
    return "Add your first transaction to get personalized financial tips!";
  }
  
  /// Fetch complete dashboard data
  Future<void> fetchDashboardData() async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('DashboardService: Fetching dashboard data...');
      
      // Fetch dashboard summary from backend
      final response = await _httpClient.get('/finance/dashboard/summary');
      
      if (response['status'] == 'success' && response['data'] != null) {
        _parseDashboardData(response['data']);
        debugPrint('DashboardService: Dashboard data fetched successfully');
      } else {
        // If API returns no data, initialize with empty data
        debugPrint('DashboardService: No data available, initializing empty dashboard');
        _initializeEmptyData();
      }
    } catch (e) {
      debugPrint('DashboardService: Error fetching dashboard data: $e');
      
      // Check if it's an auth error and retry once after a short delay
      if (e.toString().contains('Authentication') || e.toString().contains('401')) {
        debugPrint('DashboardService: Auth error detected, retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final retryResponse = await _httpClient.get('/finance/dashboard/summary');
          if (retryResponse['status'] == 'success' && retryResponse['data'] != null) {
            _parseDashboardData(retryResponse['data']);
            debugPrint('DashboardService: Dashboard data fetched successfully on retry');
            return;
          } else {
            _initializeEmptyData();
          }
        } catch (retryError) {
          debugPrint('DashboardService: Retry also failed: $retryError');
          _initializeEmptyData();
        }
      } else {
        _setError('Failed to load dashboard data: $e');
        _initializeEmptyData();
      }
    } finally {
      _setLoading(false);
    }
  }
  
  /// Parse dashboard data from API response
  void _parseDashboardData(Map<String, dynamic> data) {
    try {
      // Parse summary
      if (data['summary'] != null) {
        _summary = DashboardSummary.fromJson(data['summary']);
      } else {
        _summary = DashboardSummary.empty();
      }
      
      // Parse budget data
      if (data['budgetData'] != null) {
        _budgetData = BudgetData.fromJson(data['budgetData']);
      } else {
        _budgetData = BudgetData.empty();
      }
      
      // Parse recent transactions
      if (data['recentTransactions'] != null) {
        _recentTransactions = (data['recentTransactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      } else {
        _recentTransactions = [];
      }
      
      // Parse smart suggestions
      if (data['smartSuggestions'] != null) {
        _smartSuggestions = (data['smartSuggestions'] as List)
            .map((json) => FinancialSuggestion.fromJson(json))
            .toList();
      } else {
        _smartSuggestions = [];
      }
      
      // Parse spending trend
      if (data['spendingTrend'] != null) {
        _spendingTrend = List<Map<String, dynamic>>.from(data['spendingTrend']);
      } else {
        _spendingTrend = [];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('DashboardService: Error parsing dashboard data: $e');
      _initializeEmptyData();
    }
  }
  
  /// Initialize empty data when no real data is available
  void _initializeEmptyData() {
    _summary = DashboardSummary.empty();
    _budgetData = BudgetData.empty();
    _recentTransactions = [];
    _smartSuggestions = [];
    _spendingTrend = [];
    
    notifyListeners();
  }
  
  /// Refresh dashboard data
  Future<void> refresh() async {
    await fetchDashboardData();
  }
  
  /// Clear all data
  void clear() {
    _summary = null;
    _recentTransactions = [];
    _smartSuggestions = [];
    _spendingTrend = [];
    _budgetData = null;
    _clearError();
    notifyListeners();
  }
  
  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}

// Data Models
class DashboardSummary {
  final double netWorth;
  final double monthlySpending;
  final double monthlyIncome;
  final double savingsRate;
  final String emergencyFundStatus;
  final double investmentPortfolio;
  final double debtAmount;
  final int creditScore;

  DashboardSummary({
    required this.netWorth,
    required this.monthlySpending,
    required this.monthlyIncome,
    required this.savingsRate,
    required this.emergencyFundStatus,
    required this.investmentPortfolio,
    required this.debtAmount,
    required this.creditScore,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      netWorth: (json['netWorth'] ?? 0.0).toDouble(),
      monthlySpending: (json['monthlySpending'] ?? 0.0).toDouble(),
      monthlyIncome: (json['monthlyIncome'] ?? 0.0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0.0).toDouble(),
      emergencyFundStatus: json['emergencyFundStatus'] ?? 'Unknown',
      investmentPortfolio: (json['investmentPortfolio'] ?? 0.0).toDouble(),
      debtAmount: (json['debtAmount'] ?? 0.0).toDouble(),
      creditScore: json['creditScore'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'netWorth': netWorth,
      'monthlySpending': monthlySpending,
      'monthlyIncome': monthlyIncome,
      'savingsRate': savingsRate,
      'emergencyFundStatus': emergencyFundStatus,
      'investmentPortfolio': investmentPortfolio,
      'debtAmount': debtAmount,
      'creditScore': creditScore,
    };
  }

  factory DashboardSummary.empty() {
    return DashboardSummary(
      netWorth: 0.0,
      monthlySpending: 0.0,
      monthlyIncome: 0.0,
      savingsRate: 0.0,
      emergencyFundStatus: 'Unknown',
      investmentPortfolio: 0.0,
      debtAmount: 0.0,
      creditScore: 0,
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String icon;
  final String color;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? '',
      icon: json['icon'] ?? 'receipt',
      color: json['color'] ?? '#2196F3',
      isExpense: json['isExpense'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'icon': icon,
      'color': color,
      'isExpense': isExpense,
    };
  }
}

class FinancialSuggestion {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final String category;
  final double impact;
  final String priority;

  FinancialSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.impact,
    required this.priority,
  });

  factory FinancialSuggestion.fromJson(Map<String, dynamic> json) {
    return FinancialSuggestion(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'lightbulb',
      color: json['color'] ?? '#2196F3',
      category: json['category'] ?? '',
      impact: (json['impact'] ?? 0.0).toDouble(),
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'category': category,
      'impact': impact,
      'priority': priority,
    };
  }
}

class BudgetData {
  final double monthlyBudget;
  final double amountSpent;
  final double remainingBudget;
  final double spendingPercentage;
  final String budgetStatus;

  BudgetData({
    required this.monthlyBudget,
    required this.amountSpent,
    required this.remainingBudget,
    required this.spendingPercentage,
    required this.budgetStatus,
  });

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    return BudgetData(
      monthlyBudget: (json['monthlyBudget'] ?? 0.0).toDouble(),
      amountSpent: (json['amountSpent'] ?? 0.0).toDouble(),
      remainingBudget: (json['remainingBudget'] ?? 0.0).toDouble(),
      spendingPercentage: (json['spendingPercentage'] ?? 0.0).toDouble(),
      budgetStatus: json['budgetStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyBudget': monthlyBudget,
      'amountSpent': amountSpent,
      'remainingBudget': remainingBudget,
      'spendingPercentage': spendingPercentage,
      'budgetStatus': budgetStatus,
    };
  }

  factory BudgetData.empty() {
    return BudgetData(
      monthlyBudget: 0.0,
      amountSpent: 0.0,
      remainingBudget: 0.0,
      spendingPercentage: 0.0,
      budgetStatus: '',
    );
  }
} 