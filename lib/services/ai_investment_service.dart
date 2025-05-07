// lib/services/ai_investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment_path.dart';
import '../models/investment_projection.dart';

class AIInvestmentService {
  static const String _baseUrl = 'https://api.youraiprovider.com/v1';
  static const String _apiKey = 'YOUR_API_KEY'; // Store securely
  
  // Fetch available investment paths based on user profile
  Future<List<InvestmentPath>> getRecommendedPaths(Map<String, dynamic> userProfile) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/investment-paths'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'user_profile': userProfile,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['paths'];
        return data.map((json) => _parseInvestmentPath(json)).toList();
      } else {
        throw Exception('Failed to load investment paths: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get AI projections for a specific investment amount in a given path
  Future<InvestmentProjection> getProjection(String pathId, double amount, List<int> timeframes) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/projections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'path_id': pathId,
          'amount': amount,
          'timeframes': timeframes, // [6, 12, 24] months
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseProjection(data);
      } else {
        throw Exception('Failed to get projection: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Projection error: $e');
    }
  }

  // Private parsing methods
  InvestmentPath _parseInvestmentPath(Map<String, dynamic> json) {
    List<AssetAllocation> allocations = (json['recommended_allocation'] as List)
        .map((allocation) => AssetAllocation(
              assetName: allocation['asset_name'],
              percentage: allocation['percentage'],
              assetCategory: allocation['asset_category'],
            ))
        .toList();

    return InvestmentPath(
      name: json['name'],
      description: json['description'],
      iconPath: json['icon_path'],
      riskScore: json['risk_score'],
      recommendedAllocation: allocations,
    );
  }

  InvestmentProjection _parseProjection(Map<String, dynamic> json) {
    List<TimeProjection> timeProjections = (json['projections'] as List)
        .map((proj) {
          List<AssetPerformance> performances = (proj['asset_performance'] as List)
              .map((perf) {
                List<HistoricalPoint> history = (perf['historical_data'] as List)
                    .map((point) => HistoricalPoint(
                          date: DateTime.parse(point['date']),
                          value: point['value'],
                        ))
                    .toList();

                return AssetPerformance(
                  assetName: perf['asset_name'],
                  initialValue: perf['initial_value'],
                  projectedValue: perf['projected_value'],
                  growth: perf['growth'],
                  historicalData: history,
                );
              })
              .toList();

          return TimeProjection(
            months: proj['months'],
            projectedAmount: proj['projected_amount'],
            assetPerformance: performances,
          );
        })
        .toList();

    return InvestmentProjection(
      initialAmount: json['initial_amount'],
      pathName: json['path_name'],
      projections: timeProjections,
      potentialReturn: json['potential_return'],
      confidence: json['confidence'],
    );
  }
}
