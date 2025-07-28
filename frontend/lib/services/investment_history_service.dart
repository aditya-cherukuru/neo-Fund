import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../main.dart';

class InvestmentHistoryService {
  static const String _backendBaseUrl = 'http://localhost:3000/api';
  
  // Simple in-memory cache for historical data
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5); // Cache for 5 minutes

  // Search for investment symbols through backend
  Future<List<Map<String, dynamic>>> searchSymbols(String query, {String? type}) async {
    try {
      if (query.length < 2) return [];

      final response = await http.get(
        Uri.parse('$_backendBaseUrl/investment/search-symbols?query=${Uri.encodeComponent(query)}&type=${type ?? 'stocks'}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          // Handle both array and object responses
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data'].map((item) => 
              item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item)
            ));
          } else {
            // If data is not a list, return empty list
            return [];
          }
        }
      }
      return [];
    } catch (e) {
      print('Error searching symbols: $e');
      return [];
    }
  }



  // Get historical data for a symbol through backend (with caching)
  Future<Map<String, dynamic>> getHistoricalData(String symbol, {String? type, String interval = 'monthly', int? duration}) async {
    // Create cache key
    final cacheKey = '${symbol}_${type}_${interval}_${duration ?? 'default'}';
    
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        print('Returning cached data for $symbol');
        return _cache[cacheKey]!;
      } else {
        // Remove expired cache entry
        _cache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }
    
    try {
      final requestBody = <String, dynamic>{
        'symbol': symbol,
        'type': type,
        'interval': interval,
      };
      
      // Add duration if provided
      if (duration != null) {
        requestBody['duration'] = duration;
      }
      
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/investment/historical-data'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final result = data['data'] as Map<String, dynamic>;
          
          // Cache the result
          _cache[cacheKey] = result;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          return result;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch historical data');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch historical data: $e');
    }
  }

  // Clear cache (useful for testing or when data becomes stale)
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Analyze investment history with given parameters
  Future<Map<String, dynamic>> analyzeInvestmentHistory({
    required double investmentAmount,
    required int duration,
    required String riskPreference,
    required String investmentType,
    String? symbol,
  }) async {
    try {
      // Use a default symbol if none provided
      final analysisSymbol = symbol ?? _getDefaultSymbol(investmentType);
      
      // Get historical data from backend
      final historicalData = await getHistoricalData(
        analysisSymbol,
        type: investmentType,
        duration: duration,
      );

      // Extract price data
      final prices = List<double>.from(historicalData['prices'] ?? []);
      final dates = List<String>.from(historicalData['dates'] ?? []);

      if (prices.isEmpty) {
        throw Exception('No historical data available for analysis');
      }

      // Calculate metrics
      final metrics = _calculateMetrics(prices, dates);
      
      // Calculate investment simulation
      final initialPrice = prices.last;
      final finalPrice = prices.first;
      final shares = investmentAmount / initialPrice;
      final finalValue = shares * finalPrice;
      final profit = finalValue - investmentAmount;
      final profitPercentage = (profit / investmentAmount) * 100;

      // Generate insights
      final insights = _generateInsights(metrics, profitPercentage, riskPreference, duration);

      return {
        'summary': 'Investment analysis for $analysisSymbol over $duration years',
        'performance': {
          'Initial Investment': '\$${investmentAmount.toStringAsFixed(2)}',
          'Final Value': '\$${finalValue.toStringAsFixed(2)}',
          'Profit/Loss': profit >= 0 ? '+\$${profit.toStringAsFixed(2)}' : '-\$${profit.abs().toStringAsFixed(2)}',
          'Return %': '${profitPercentage.toStringAsFixed(1)}%',
          'Volatility': '${metrics['volatility']?.toStringAsFixed(1) ?? 'N/A'}%',
          'Current Price': '\$${metrics['currentPrice']?.toStringAsFixed(2) ?? 'N/A'}',
        },
        'insights': insights,
        'rawData': {
          'symbol': analysisSymbol,
          'type': investmentType,
          'duration': duration,
          'riskPreference': riskPreference,
          'metrics': metrics,
        },
      };
    } catch (e) {
      throw Exception('Failed to analyze investment history: $e');
    }
  }



  // Get default symbol based on investment type
  String _getDefaultSymbol(String investmentType) {
    switch (investmentType.toLowerCase()) {
      case 'stocks':
        return 'AAPL';
      case 'crypto':
        return 'BTC';
      case 'bonds':
        return 'TLT';
      case 'etfs':
        return 'SPY';
      case 'mutual funds':
        return 'VTSAX';
      default:
        return 'AAPL';
    }
  }

  // Generate insights based on analysis
  List<String> _generateInsights(Map<String, dynamic> metrics, double profitPercentage, String riskPreference, int duration) {
    final insights = <String>[];
    
    insights.add('This analysis shows what would have happened if you invested $duration years ago.');
    
    if (profitPercentage > 0) {
      insights.add('Your investment would have increased by ${profitPercentage.toStringAsFixed(1)}% over $duration years.');
      insights.add('This represents a gain, meaning your money would have grown in value.');
    } else {
      insights.add('Your investment would have decreased by ${profitPercentage.abs().toStringAsFixed(1)}% over $duration years.');
      insights.add('This represents a loss, meaning your money would have decreased in value.');
    }

    final volatility = metrics['volatility'] ?? 0.0;
    if (volatility < 10) {
      insights.add('Low volatility (${volatility.toStringAsFixed(1)}%) indicates stable performance - lower risk and return.');
    } else if (volatility < 20) {
      insights.add('Moderate volatility (${volatility.toStringAsFixed(1)}%) shows steady but variable performance - balanced risk and return.');
    } else {
      insights.add('High volatility (${volatility.toStringAsFixed(1)}%) indicates significant price swings - higher risk and potential return.');
    }

    if (metrics['bestPeriod'] != null) {
      final bestReturn = metrics['bestPeriod']['return'] ?? 0.0;
      final bestDate = metrics['bestPeriod']['date'] ?? 'N/A';
      insights.add('Best performance: $bestDate with ${bestReturn.toStringAsFixed(1)}% return.');
    }

    insights.add('Remember: Past performance doesn\'t guarantee future results. This is for educational purposes only.');
    
    return insights;
  }

  // Calculate key investment metrics (helper function)
  Map<String, dynamic> _calculateMetrics(List<double> prices, List<String> dates) {
    if (prices.isEmpty) return {};
    final currentPrice = prices.first;
    final oldestPrice = prices.last;
    final totalReturn = ((currentPrice - oldestPrice) / oldestPrice) * 100;
    final returns = <double>[];
    for (int i = 1; i < prices.length; i++) {
      final returnRate = ((prices[i - 1] - prices[i]) / prices[i]) * 100;
      returns.add(returnRate);
    }
    final avgReturn = returns.isEmpty ? 0.0 : returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.isEmpty ? 0.0 : returns.map((r) => (r - avgReturn) * (r - avgReturn)).reduce((a, b) => a + b) / returns.length;
    final volatility = variance > 0 ? math.sqrt(variance) : 0.0;
    double maxReturn = 0;
    double minReturn = 0;
    String bestPeriod = '';
    String worstPeriod = '';
    for (int i = 1; i < prices.length; i++) {
      final returnRate = ((prices[i - 1] - prices[i]) / prices[i]) * 100;
      if (returnRate > maxReturn) {
        maxReturn = returnRate;
        bestPeriod = dates[i];
      }
      if (returnRate < minReturn) {
        minReturn = returnRate;
        worstPeriod = dates[i];
      }
    }
    return {
      'currentPrice': currentPrice,
      'oldestPrice': oldestPrice,
      'totalReturn': totalReturn,
      'volatility': volatility,
      'avgReturn': avgReturn,
      'bestPeriod': {
        'date': bestPeriod,
        'return': maxReturn,
      },
      'worstPeriod': {
        'date': worstPeriod,
        'return': minReturn,
      },
      'dataPoints': prices.length,
      'timeSpan': '${dates.length} periods',
    };
  }
} 