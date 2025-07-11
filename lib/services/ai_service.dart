// lib/services/ai_investment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/investment_path.dart';
import '../models/investment_projection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class AIInvestmentService {
  static final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  late final String _apiKey;
  late final String _model;
  
  AIInvestmentService() {
    // Load API key from environment variables or secure storage
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not found in environment variables');
    }
    
    // Allow model to be configurable, with a default
    // Use Gemini's model naming format
    _model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-pro';
    
    // Log which model we're using
    print('AIInvestmentService initialized with model: $_model');
  }
  
  // Fetch available investment paths based on user profile
  Future<List<InvestmentPath>> getRecommendedPaths(Map<String, dynamic> userProfile) async {
    const systemPrompt = '''
    You are a financial advisor assistant. Provide investment path recommendations based on the user profile.
    
    IMPORTANT: Your response must be valid JSON only, with no other text or explanation, in this exact structure:
    {
      "paths": [
        {
          "name": "Path name",
          "description": "Description of the investment path",
          "icon_path": "assets/icons/stock.png",
          "risk_score": 3,
          "recommended_allocation": [
            {
              "asset_name": "Asset name",
              "percentage": 25.0,
              "asset_category": "category"
            }
          ]
        }
      ]
    }
    ''';
    
    final userPrompt = 'Generate investment path recommendations based on this user profile: ${jsonEncode(userProfile)}. Return only JSON.';
    
    try {
      final jsonResponse = await _callGemini(systemPrompt, userPrompt);
      
      // Validate that we have the expected structure
      if (!jsonResponse.containsKey('paths') || jsonResponse['paths'] is! List) {
        throw FormatException('AI response missing or invalid "paths" array');
      }
      
      final List<dynamic> data = jsonResponse['paths'] as List;
      return data.map((json) => _parseInvestmentPath(json)).toList();
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Failed to parse AI response: $e');
    } catch (e) {
      print('Exception details: $e');
      throw Exception('Error getting investment paths: $e');
    }
  }

  // Get AI projections for a specific investment amount in a given path
  Future<InvestmentProjection> getProjection(String pathId, double amount, List<int> timeframes) async {
    const systemPrompt = '''
    You are a financial projection assistant. Provide realistic investment projections based on historical market data.
    
    IMPORTANT: Your response must be valid JSON only, with no other text or explanation, in this exact structure:
    {
      "initial_amount": 5000.0,
      "path_name": "Conservative",
      "potential_return": 7.2,
      "confidence": 80.0,
      "projections": [
        {
          "months": 12,
          "projected_amount": 5360.0,
          "asset_performance": [
            {
              "asset_name": "US Treasury Bonds",
              "initial_value": 2500.0,
              "projected_value": 2625.0,
              "growth": 5.0,
              "historical_data": [
                {"date": "2023-01-01", "value": 2500.0},
                {"date": "2023-03-01", "value": 2550.0}
              ]
            }
          ]
        }
      ]
    }
    ''';
    
    final userPrompt = 'Generate investment projections for path ID: $pathId, initial amount: $amount, and timeframes (months): $timeframes. Return only JSON.';
    
    try {
      final jsonResponse = await _callGemini(systemPrompt, userPrompt, temperature: 0.3);
      return _parseProjection(jsonResponse);
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Failed to parse AI projection response: $e');
    } catch (e) {
      print('Exception details: $e');
      throw Exception('Error getting investment projection: $e');
    }
  }
  
  // Helper method to make Gemini API calls and parse JSON
  Future<Map<String, dynamic>> _callGemini(String systemPrompt, String userPrompt, {double temperature = 0.7}) async {
    final endpoint = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
    
    // Debug log to verify API endpoint
    print('Calling Gemini API at: $endpoint');
    
    // Build the request body
    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': '$systemPrompt\n\n$userPrompt'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
      },
    };
    
    // Debug log showing the request
    print('Request body: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      
      // Extract content from Gemini response structure
      final candidates = responseBody['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No content parts in Gemini response');
      }
      
      final text = parts[0]['text'] as String?;
      if (text == null || text.isEmpty) {
        throw Exception('Empty text in Gemini response');
      }
      
      try {
        // Log the raw response for debugging
        print('Raw Gemini response text: $text');
        
        // Try to extract just the JSON part (in case there's any preamble text)
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonText = text.substring(jsonStart, jsonEnd);
          print('Extracted JSON: $jsonText');
          return jsonDecode(jsonText) as Map<String, dynamic>;
        } else {
          // If we can't find JSON delimiters, try parsing the whole text
          return jsonDecode(text) as Map<String, dynamic>;
        }
      } catch (e) {
        throw FormatException('Invalid JSON response from API: $e\nResponse was: $text');
      }
    } else {
      // Enhanced error handling
      String errorMessage = 'Unknown API error';
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['error']?['message'] ?? 'Unknown API error';
      } catch (e) {
        errorMessage = 'Error parsing error response: ${response.body}';
      }
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  // Private parsing methods
  InvestmentPath _parseInvestmentPath(Map<String, dynamic> json) {
    final List<dynamic> allocationData = json['recommended_allocation'] as List? ?? [];
    
    List<AssetAllocation> allocations = allocationData
        .map((allocation) => AssetAllocation(
              assetName: allocation['asset_name'] ?? 'Unknown Asset',
              percentage: (allocation['percentage'] ?? 0.0).toDouble(),
              assetCategory: allocation['asset_category'] ?? 'Uncategorized',
            ))
        .toList();

    return InvestmentPath(
      name: json['name'] ?? 'Unnamed Path',
      description: json['description'] ?? 'No description provided',
      iconPath: json['icon_path'] ?? 'assets/icons/default.png',
      riskScore: (json['risk_score'] ?? 3).toInt(),
      recommendedAllocation: allocations,
    );
  }

  InvestmentProjection _parseProjection(Map<String, dynamic> json) {
    final List<dynamic> projData = json['projections'] as List? ?? [];
    
    List<TimeProjection> timeProjections = projData
        .map((proj) {
          final List<dynamic> perfData = proj['asset_performance'] as List? ?? [];
          
          List<AssetPerformance> performances = perfData
              .map((perf) {
                final List<dynamic> historyData = perf['historical_data'] as List? ?? [];
                
                List<HistoricalPoint> history = historyData
                    .map((point) => HistoricalPoint(
                          date: DateTime.tryParse(point['date'] ?? '') ?? DateTime.now(),
                          value: (point['value'] ?? 0.0).toDouble(),
                        ))
                    .toList();

                return AssetPerformance(
                  assetName: perf['asset_name'] ?? 'Unknown Asset',
                  initialValue: (perf['initial_value'] ?? 0.0).toDouble(),
                  projectedValue: (perf['projected_value'] ?? 0.0).toDouble(),
                  growth: (perf['growth'] ?? 0.0).toDouble(),
                  historicalData: history,
                );
              })
              .toList();

          return TimeProjection(
            months: (proj['months'] ?? 0).toInt(),
            projectedAmount: (proj['projected_amount'] ?? 0.0).toDouble(),
            assetPerformance: performances,
          );
        })
        .toList();

    return InvestmentProjection(
      initialAmount: (json['initial_amount'] ?? 0.0).toDouble(),
      pathName: json['path_name'] ?? 'Unknown Path',
      projections: timeProjections,
      potentialReturn: (json['potential_return'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}