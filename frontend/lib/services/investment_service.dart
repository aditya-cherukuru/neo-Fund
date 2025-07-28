import 'package:flutter/material.dart';
import '../models/investment.dart';
import 'http_client.dart';

class InvestmentService extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  
  // State variables
  bool _isLoading = false;
  String? _error;
  List<Investment> _investments = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Investment> get investments => _investments;

  /// Get all investments
  Future<List<Investment>> getInvestments({BuildContext? context}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('InvestmentService: Fetching investments...');
      
      final response = await _httpClient.get('/investment/', context: context);
      
      if (response['success'] == true && response['data'] != null) {
        _investments = (response['data'] as List)
            .map((json) => Investment.fromJson(json))
            .toList();
        
        debugPrint('InvestmentService: Fetched ${_investments.length} investments');
        notifyListeners();
        return _investments;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch investments');
      }
    } catch (e) {
      debugPrint('InvestmentService: Error fetching investments: $e');
      _setError('Failed to load investments: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new investment
  Future<void> createInvestment(Investment investment, {BuildContext? context}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('InvestmentService: Creating investment: ${investment.name}');
      
      final response = await _httpClient.post('/investment/create', investment.toJson(), context: context);
      
      if (response['success'] == true && response['data'] != null) {
        final newInvestment = Investment.fromJson(response['data']);
        _investments.add(newInvestment);
        
        debugPrint('InvestmentService: Investment created successfully');
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to create investment');
      }
    } catch (e) {
      debugPrint('InvestmentService: Error creating investment: $e');
      _setError('Failed to create investment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing investment
  Future<void> updateInvestment(String id, Investment updatedInvestment, {BuildContext? context}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('InvestmentService: Updating investment: $id');
      
      final response = await _httpClient.put('/investment/$id', updatedInvestment.toJson(), context: context);
      
      if (response['success'] == true && response['data'] != null) {
        final updatedInvestmentData = Investment.fromJson(response['data']);
        final index = _investments.indexWhere((investment) => investment.id == id);
        
        if (index != -1) {
          _investments[index] = updatedInvestmentData;
          debugPrint('InvestmentService: Investment updated successfully');
          notifyListeners();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update investment');
      }
    } catch (e) {
      debugPrint('InvestmentService: Error updating investment: $e');
      _setError('Failed to update investment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an investment
  Future<void> deleteInvestment(String id, {BuildContext? context}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('InvestmentService: Deleting investment: $id');
      
      final response = await _httpClient.delete('/investment/$id', context: context);
      
      if (response['success'] == true) {
        _investments.removeWhere((investment) => investment.id == id);
        
        debugPrint('InvestmentService: Investment deleted successfully');
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to delete investment');
      }
    } catch (e) {
      debugPrint('InvestmentService: Error deleting investment: $e');
      _setError('Failed to delete investment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get investment by ID
  Investment? getInvestmentById(String id) {
    try {
      return _investments.firstWhere((investment) => investment.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get investments by type
  List<Investment> getInvestmentsByType(String type) {
    return _investments.where((investment) => investment.type == type).toList();
  }

  /// Get investments by platform
  List<Investment> getInvestmentsByPlatform(String platform) {
    return _investments.where((investment) => investment.platform == platform).toList();
  }

  /// Get active investments
  List<Investment> getActiveInvestments() {
    return _investments.where((investment) => investment.status == 'active').toList();
  }

  /// Calculate total investment amount
  double getTotalInvestmentAmount() {
    return _investments.fold(0.0, (sum, investment) => sum + investment.amount);
  }

  /// Calculate total current value
  double getTotalCurrentValue() {
    return _investments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? 0.0));
  }

  /// Calculate total profit/loss
  double getTotalProfitLoss() {
    return _investments.fold(0.0, (sum, investment) => sum + (investment.profitLoss ?? 0.0));
  }

  /// Calculate portfolio performance percentage
  double getPortfolioPerformance() {
    final totalAmount = getTotalInvestmentAmount();
    final totalCurrentValue = getTotalCurrentValue();
    
    if (totalAmount == 0) return 0.0;
    return ((totalCurrentValue - totalAmount) / totalAmount) * 100;
  }

  /// Get investments by risk level
  List<Investment> getInvestmentsByRiskLevel(String riskLevel) {
    return _investments.where((investment) => investment.riskLevel == riskLevel).toList();
  }

  /// Get top performing investments
  List<Investment> getTopPerformingInvestments({int limit = 5}) {
    final sortedInvestments = List<Investment>.from(_investments);
    sortedInvestments.sort((a, b) => (b.profitLoss ?? 0).compareTo(a.profitLoss ?? 0));
    return sortedInvestments.take(limit).toList();
  }

  /// Get investments purchased in date range
  List<Investment> getInvestmentsInDateRange(DateTime startDate, DateTime endDate) {
    return _investments.where((investment) => 
      investment.purchaseDate.isAfter(startDate) && 
      investment.purchaseDate.isBefore(endDate)
    ).toList();
  }

  /// Forecast future investment performance
  Future<Map<String, dynamic>> forecastInvestment({
    required double amount,
    required int duration,
    String durationType = 'years',
    required String investmentType,
    required String riskAppetite,
    double? expectedReturn,
    String currency = 'USD',
    BuildContext? context,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _httpClient.post(
        '/investment/forecast',
        {
          'amount': amount,
          'duration': duration,
          'durationType': durationType,
          'investmentType': investmentType,
          'riskAppetite': riskAppetite,
          if (expectedReturn != null) 'expectedReturn': expectedReturn,
          'currency': currency,
        },
        context: context,
      );
      if (response['status'] == 'success' && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to forecast investment');
      }
    } catch (e) {
      _setError('Failed to forecast investment: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
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

  /// Clear all data (useful for logout)
  void clear() {
    _investments.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
} 