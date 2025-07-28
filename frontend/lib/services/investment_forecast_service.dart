import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class InvestmentForecastService extends ChangeNotifier {
  final String _backendBaseUrl = 'http://127.0.0.1:3000/api';

  // Generate AI-powered investment forecast
  Future<Map<String, dynamic>> generateForecast({
    required double investmentAmount,
    required int duration,
    required String riskAppetite,
    required String investmentType,
    required double expectedReturn,
    required String currency,
  }) async {
    try {
      debugPrint('InvestmentForecastService: Generating forecast...');
      
      // Call backend API for AI-powered forecast
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/investment/forecast'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'investmentAmount': investmentAmount,
          'duration': duration,
          'riskAppetite': riskAppetite,
          'investmentType': investmentType,
          'expectedReturn': expectedReturn,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          debugPrint('InvestmentForecastService: Forecast generated successfully');
          return data['data'];
        }
      }

      // If API fails, generate mock forecast data
      debugPrint('InvestmentForecastService: Using mock forecast data');
      return _generateMockForecast(
        investmentAmount: investmentAmount,
        duration: duration,
        riskAppetite: riskAppetite,
        investmentType: investmentType,
        expectedReturn: expectedReturn,
        currency: currency,
      );
    } catch (e) {
      debugPrint('InvestmentForecastService: Error generating forecast: $e');
      // Return mock data on error
      return _generateMockForecast(
        investmentAmount: investmentAmount,
        duration: duration,
        riskAppetite: riskAppetite,
        investmentType: investmentType,
        expectedReturn: expectedReturn,
        currency: currency,
      );
    }
  }

  // Generate mock forecast data for development/testing
  Map<String, dynamic> _generateMockForecast({
    required double investmentAmount,
    required int duration,
    required String riskAppetite,
    required String investmentType,
    required double expectedReturn,
    required String currency,
  }) {
    // Calculate risk-adjusted return based on risk appetite
    double baseReturn = expectedReturn;
    double volatility = 0;
    
    switch (riskAppetite.toLowerCase()) {
      case 'low':
        baseReturn = math.min(expectedReturn, 6.0);
        volatility = 8.0;
        break;
      case 'medium':
        baseReturn = expectedReturn;
        volatility = 15.0;
        break;
      case 'high':
        baseReturn = math.max(expectedReturn, 12.0);
        volatility = 25.0;
        break;
    }

    // Generate year-wise growth data
    List<Map<String, dynamic>> yearWiseGrowth = [];
    double currentValue = investmentAmount;
    
    for (int year = 1; year <= duration; year++) {
      // Add some randomness to make it more realistic
      double annualReturn = baseReturn + (math.Random().nextDouble() - 0.5) * volatility;
      annualReturn = math.max(annualReturn, -20.0); // Cap losses at 20%
      annualReturn = math.min(annualReturn, 50.0); // Cap gains at 50%
      
      currentValue = currentValue * (1 + annualReturn / 100);
      
      yearWiseGrowth.add({
        'year': year,
        'value': currentValue,
        'growth': annualReturn,
        'cumulativeGrowth': ((currentValue - investmentAmount) / investmentAmount) * 100,
      });
    }

    // Calculate final metrics
    double projectedValue = yearWiseGrowth.last['value'];
    double totalGrowth = ((projectedValue - investmentAmount) / investmentAmount) * 100;
    
    // Generate insights based on the forecast
    List<String> insights = _generateInsights(
      investmentAmount: investmentAmount,
      projectedValue: projectedValue,
      totalGrowth: totalGrowth,
      riskAppetite: riskAppetite,
      investmentType: investmentType,
      duration: duration,
    );

    // Risk analysis
    Map<String, dynamic> riskAnalysis = {
      'volatility': volatility,
      'expectedReturn': baseReturn,
      'riskRewardRatio': baseReturn / volatility,
      'maxDrawdown': volatility * 0.5, // Estimated max drawdown
      'sharpeRatio': baseReturn / volatility, // Simplified Sharpe ratio
    };

    return {
      'forecast': {
        'projectedValue': projectedValue,
        'totalGrowth': totalGrowth,
        'annualizedReturn': math.pow(projectedValue / investmentAmount, 1.0 / duration) - 1,
        'initialInvestment': investmentAmount,
        'duration': duration,
      },
      'yearWiseGrowth': yearWiseGrowth,
      'insights': insights,
      'riskAnalysis': riskAnalysis,
      'parameters': {
        'investmentAmount': investmentAmount,
        'duration': duration,
        'riskAppetite': riskAppetite,
        'investmentType': investmentType,
        'expectedReturn': expectedReturn,
        'currency': currency,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  // Generate AI-like insights based on forecast data
  List<String> _generateInsights({
    required double investmentAmount,
    required double projectedValue,
    required double totalGrowth,
    required String riskAppetite,
    required String investmentType,
    required int duration,
  }) {
    List<String> insights = [];

    // Basic growth insight
    if (totalGrowth > 0) {
      insights.add('Your investment is projected to grow by ${totalGrowth.toStringAsFixed(1)}% over $duration years, potentially reaching ${_formatCurrency(projectedValue)}.');
    } else {
      insights.add('Based on current market conditions, your investment may experience a decline of ${totalGrowth.abs().toStringAsFixed(1)}% over $duration years.');
    }

    // Risk level insight
    switch (riskAppetite.toLowerCase()) {
      case 'low':
        insights.add('Your conservative approach with $riskAppetite risk appetite provides stability but may limit growth potential.');
        break;
      case 'medium':
        insights.add('Your balanced $riskAppetite risk approach offers a good mix of growth potential and stability.');
        break;
      case 'high':
        insights.add('Your aggressive $riskAppetite risk strategy has higher growth potential but also increased volatility.');
        break;
    }

    // Investment type insight
    switch (investmentType.toLowerCase()) {
      case 'stocks':
        insights.add('Stock investments typically offer higher returns but come with market volatility. Consider diversifying across sectors.');
        break;
      case 'mutual funds':
        insights.add('Mutual funds provide diversification and professional management, making them suitable for most investors.');
        break;
      case 'crypto':
        insights.add('Cryptocurrency investments are highly volatile and speculative. Only invest what you can afford to lose.');
        break;
      case 'bonds':
        insights.add('Bonds offer stability and regular income, making them ideal for conservative investors.');
        break;
      case 'etfs':
        insights.add('ETFs combine the benefits of stocks and mutual funds with lower fees and better liquidity.');
        break;
      case 'real estate':
        insights.add('Real estate investments provide tangible assets and potential rental income, but require significant capital.');
        break;
    }

    // Duration insight
    if (duration >= 10) {
      insights.add('Long-term investments ($duration+ years) typically benefit from compound growth and can weather market fluctuations.');
    } else if (duration >= 5) {
      insights.add('Medium-term investments ($duration years) balance growth potential with manageable risk.');
    } else {
      insights.add('Short-term investments ($duration years) may be more suitable for specific financial goals or if you need liquidity.');
    }

    // Compound interest insight
    if (totalGrowth > 50) {
      insights.add('The power of compound interest is evident in your forecast, showing how small annual returns can lead to significant long-term growth.');
    }

    // Market timing insight
    insights.add('Remember that market timing is difficult. Regular investments (dollar-cost averaging) often perform better than trying to time the market.');

    // Diversification insight
    insights.add('Consider diversifying your portfolio across different asset classes to reduce risk and improve potential returns.');

    return insights;
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Search for investment symbols with auto-suggestions
  Future<List<Map<String, dynamic>>> searchSymbols(String query, {String? type}) async {
    try {
      if (query.length < 2) return [];

      debugPrint('InvestmentForecastService: Searching symbols for: $query, type: $type');
      
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/investment/search-symbols?query=${Uri.encodeComponent(query)}&type=${type ?? 'stocks'}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          debugPrint('InvestmentForecastService: Found ${data['data'].length} symbols');
          return List<Map<String, dynamic>>.from(data['data'].map((item) => 
            item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item)
          ));
        }
      }
      return [];
    } catch (e) {
      debugPrint('InvestmentForecastService: Error searching symbols: $e');
      return [];
    }
  }

  // Analyze investment history with historical data
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
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/investment/historical-data'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'symbol': analysisSymbol,
          'type': investmentType.toLowerCase(),
          'duration': duration,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return _processHistoricalData(data['data'], investmentAmount, duration, riskPreference, investmentType, analysisSymbol);
        }
      }

      // If API fails, generate mock analysis
      return _generateMockAnalysis(investmentAmount, duration, riskPreference, investmentType, analysisSymbol);
    } catch (e) {
      debugPrint('InvestmentForecastService: Error analyzing investment history: $e');
      return _generateMockAnalysis(investmentAmount, duration, riskPreference, investmentType, symbol ?? _getDefaultSymbol(investmentType));
    }
  }

  Map<String, dynamic> _processHistoricalData(
    Map<String, dynamic> historicalData,
    double investmentAmount,
    int duration,
    String riskPreference,
    String investmentType,
    String symbol,
  ) {
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
    final insights = _generateHistoricalInsights(metrics, profitPercentage, riskPreference, duration);

    return {
      'summary': 'Investment analysis for $symbol over $duration years',
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
        'symbol': symbol,
        'type': investmentType,
        'duration': duration,
        'riskPreference': riskPreference,
        'metrics': metrics,
      },
    };
  }

  Map<String, dynamic> _generateMockAnalysis(
    double investmentAmount,
    int duration,
    String riskPreference,
    String investmentType,
    String symbol,
  ) {
    // Generate realistic mock data based on investment type
    double baseReturn = 0;
    double volatility = 0;
    
    switch (investmentType.toLowerCase()) {
      case 'stocks':
        baseReturn = 8.0;
        volatility = 15.0;
        break;
      case 'crypto':
        baseReturn = 12.0;
        volatility = 35.0;
        break;
      case 'bonds':
        baseReturn = 4.0;
        volatility = 5.0;
        break;
      case 'etfs':
        baseReturn = 7.0;
        volatility = 12.0;
        break;
      case 'mutual funds':
        baseReturn = 6.5;
        volatility = 10.0;
        break;
      default:
        baseReturn = 6.0;
        volatility = 12.0;
    }

    // Adjust based on risk preference
    switch (riskPreference.toLowerCase()) {
      case 'low':
        baseReturn *= 0.7;
        volatility *= 0.8;
        break;
      case 'high':
        baseReturn *= 1.3;
        volatility *= 1.2;
        break;
    }

    // Calculate mock performance
    final initialPrice = 100.0;
    final finalPrice = initialPrice * (1 + baseReturn / 100);
    final shares = investmentAmount / initialPrice;
    final finalValue = shares * finalPrice;
    final profit = finalValue - investmentAmount;
    final profitPercentage = (profit / investmentAmount) * 100;

    final metrics = {
      'currentPrice': finalPrice,
      'oldestPrice': initialPrice,
      'totalReturn': baseReturn,
      'volatility': volatility,
      'avgReturn': baseReturn,
      'dataPoints': 12,
      'timeSpan': '$duration years',
    };

    final insights = _generateHistoricalInsights(metrics, profitPercentage, riskPreference, duration);

    return {
      'summary': 'Investment analysis for $symbol over $duration years',
      'performance': {
        'Initial Investment': '\$${investmentAmount.toStringAsFixed(2)}',
        'Final Value': '\$${finalValue.toStringAsFixed(2)}',
        'Profit/Loss': profit >= 0 ? '+\$${profit.toStringAsFixed(2)}' : '-\$${profit.abs().toStringAsFixed(2)}',
        'Return %': '${profitPercentage.toStringAsFixed(1)}%',
        'Volatility': '${volatility.toStringAsFixed(1)}%',
        'Current Price': '\$${finalPrice.toStringAsFixed(2)}',
      },
      'insights': insights,
      'rawData': {
        'symbol': symbol,
        'type': investmentType,
        'duration': duration,
        'riskPreference': riskPreference,
        'metrics': metrics,
      },
    };
  }

  List<String> _generateHistoricalInsights(Map<String, dynamic> metrics, double profitPercentage, String riskPreference, int duration) {
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

  String _getDefaultSymbol(String investmentType) {
    switch (investmentType.toLowerCase()) {
      case 'stocks':
        return 'TSLA';
      case 'crypto':
        return 'BTC';
      case 'bonds':
        return 'TLT';
      case 'etfs':
        return 'SPY';
      case 'mutual funds':
        return 'VTSAX';
      default:
        return 'TSLA';
    }
  }
} 