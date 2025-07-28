import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'http_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart'; // Import to access environmentVariables

class AIInsight {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type;
  final double? impact;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    this.impact,
    this.data,
    required this.createdAt,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      type: json['type'],
      impact: json['impact']?.toDouble(),
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      if (impact != null) 'impact': impact,
      if (data != null) 'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SmartRecommendation {
  final String id;
  final String title;
  final String description;
  final String type;
  final String category;
  final double? potentialSavings;
  final double? confidence;
  final Map<String, dynamic>? actionItems;
  final DateTime createdAt;

  SmartRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.potentialSavings,
    this.confidence,
    this.actionItems,
    required this.createdAt,
  });

  factory SmartRecommendation.fromJson(Map<String, dynamic> json) {
    return SmartRecommendation(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      category: json['category'],
      potentialSavings: json['potentialSavings']?.toDouble(),
      confidence: json['confidence']?.toDouble(),
      actionItems: json['actionItems'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      if (potentialSavings != null) 'potentialSavings': potentialSavings,
      if (confidence != null) 'confidence': confidence,
      if (actionItems != null) 'actionItems': actionItems,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AIService extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  
  // State variables
  bool _isLoading = false;
  String? _error;
  List<AIInsight> _insights = [];
  final List<SmartRecommendation> _recommendations = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AIInsight> get insights => _insights;
  List<SmartRecommendation> get recommendations => _recommendations;

  /// Get AI insights
  Future<List<AIInsight>> getAIInsights({BuildContext? context}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('AIService: Fetching AI insights...');
      
      final response = await _httpClient.get('/ai/insights', context: context);
      
      if (response['success'] == true && response['data'] != null) {
        _insights = (response['data'] as List)
            .map((json) => AIInsight.fromJson(json))
            .toList();
        
        debugPrint('AIService: Fetched ${_insights.length} insights');
        notifyListeners();
        return _insights;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch AI insights');
      }
    } catch (e) {
      debugPrint('AIService: Error fetching AI insights: $e');
      _setError('Failed to load AI insights: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Create smart recommendation
  Future<SmartRecommendation> createSmartRecommendation({
    required String type,
    String? contextData,
    Map<String, dynamic>? preferences,
    BuildContext? context,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('AIService: Creating smart recommendation...');
      
      final data = {
        'type': type,
        if (contextData != null) 'context': contextData,
        if (preferences != null) 'preferences': preferences,
      };
      
      final response = await _httpClient.post('/ai/recommendations', data, context: context);
      
      if (response['success'] == true && response['data'] != null) {
        final recommendation = SmartRecommendation.fromJson(response['data']);
        _recommendations.add(recommendation);
        
        debugPrint('AIService: Smart recommendation created successfully');
        notifyListeners();
        return recommendation;
      } else {
        throw Exception(response['message'] ?? 'Failed to create smart recommendation');
      }
    } catch (e) {
      debugPrint('AIService: Error creating smart recommendation: $e');
      _setError('Failed to create smart recommendation: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get insights by category
  List<AIInsight> getInsightsByCategory(String category) {
    return _insights.where((insight) => insight.category == category).toList();
  }

  /// Get insights by type
  List<AIInsight> getInsightsByType(String type) {
    return _insights.where((insight) => insight.type == type).toList();
  }

  /// Get recommendations by type
  List<SmartRecommendation> getRecommendationsByType(String type) {
    return _recommendations.where((rec) => rec.type == type).toList();
  }

  /// Get recommendations by category
  List<SmartRecommendation> getRecommendationsByCategory(String category) {
    return _recommendations.where((rec) => rec.category == category).toList();
  }

  /// Get high impact insights (impact > 0.7)
  List<AIInsight> getHighImpactInsights() {
    return _insights.where((insight) => insight.impact != null && insight.impact! > 0.7).toList();
  }

  /// Get high confidence recommendations (confidence > 0.8)
  List<SmartRecommendation> getHighConfidenceRecommendations() {
    return _recommendations.where((rec) => rec.confidence != null && rec.confidence! > 0.8).toList();
  }

  /// Get recent insights (last 30 days)
  List<AIInsight> getRecentInsights() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _insights.where((insight) => insight.createdAt.isAfter(thirtyDaysAgo)).toList();
  }

  /// Get recent recommendations (last 30 days)
  List<SmartRecommendation> getRecentRecommendations() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _recommendations.where((rec) => rec.createdAt.isAfter(thirtyDaysAgo)).toList();
  }

  /// Calculate total potential savings from recommendations
  double getTotalPotentialSavings() {
    return _recommendations.fold(0.0, (sum, rec) => sum + (rec.potentialSavings ?? 0.0));
  }

  /// Get average confidence of recommendations
  double getAverageConfidence() {
    if (_recommendations.isEmpty) return 0.0;
    final totalConfidence = _recommendations.fold(0.0, (sum, rec) => sum + (rec.confidence ?? 0.0));
    return totalConfidence / _recommendations.length;
  }

  /// Fetch a single AI insight for a given prompt
  Future<String> getAIInsight(String prompt, {BuildContext? context}) async {
    try {
      final response = await _httpClient.post('/ai/response', { 'prompt': prompt }, context: context);
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as String;
      } else if (response['data'] != null) {
        // Some backends may not use 'success' field
        return response['data'] as String;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch AI insight');
      }
    } catch (e) {
      debugPrint('AIService: Error fetching AI insight: $e');
      throw Exception('Failed to fetch AI insight: $e');
    }
  }

  /// Get AI response directly from Groq API
  Future<String> getAIResponse(String message) async {
    try {
      final apiKey = environmentVariables['GROQ_API_KEY'] ?? '';
      final model = environmentVariables['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct';
      
      if (apiKey.isEmpty) {
        debugPrint('AIService: GROQ_API_KEY not found, trying backend...');
        // Try backend as fallback
        return await getAIInsight(message);
      }

      debugPrint('AIService: Calling Groq API directly with message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content is String) {
          debugPrint('AIService: Groq API response received successfully');
          return content.trim();
        } else {
          debugPrint('AIService: Invalid response format from Groq API');
          throw Exception('Invalid response format from Groq API');
        }
      } else {
        debugPrint('AIService: Groq API error: ${response.statusCode} - ${response.body}');
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AIService: Error calling Groq API: $e');
      // Try backend as fallback
      try {
        debugPrint('AIService: Trying backend as fallback...');
        return await getAIInsight(message);
      } catch (backendError) {
        debugPrint('AIService: Backend also failed: $backendError');
        throw Exception('Failed to get AI response: $e');
      }
    }
  }

  /// Analyze arbitrary text (e.g., OCR output) with Groq API and a custom prompt
  Future<String> analyzeTextWithGroq({
    required String ocrText,
    required String prompt,
  }) async {
    final apiKey = environmentVariables['GROQ_API_KEY'] ?? '';
    final model = environmentVariables['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct';
    
    if (apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in environment variables');
    }
    
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final fullPrompt = prompt.replaceAll('[OCR_TEXT]', ocrText);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': fullPrompt,
          }
        ],
        'max_tokens': 512,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      if (content != null && content is String) {
        return content;
      } else {
        throw Exception('Invalid response format from Groq API');
      }
    } else {
      throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get AI investment tips from Groq API
  Future<List<Map<String, dynamic>>> getInvestmentTips({
    String? context,
    Map<String, dynamic>? userProfile,
    BuildContext? buildContext,
  }) async {
    try {
      debugPrint('AIService: Fetching investment tips...');
      
      final data = {
        if (context != null) 'context': context,
        if (userProfile != null) 'userProfile': userProfile,
      };
      
      final response = await _httpClient.post('/ai/investment-tips', data, context: buildContext);
      
      if (response['success'] == true && response['data'] != null) {
        final tips = List<Map<String, dynamic>>.from(response['data']['tips'] ?? []);
        debugPrint('AIService: Fetched ${tips.length} investment tips');
        return tips;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch investment tips');
      }
    } catch (e) {
      debugPrint('AIService: Error fetching investment tips: $e');
      throw Exception('Failed to load investment tips: $e');
    }
  }

  /// Get trending investments from Groq API
  Future<List<Map<String, dynamic>>> getTrendingInvestments({
    String? marketContext,
    Map<String, dynamic>? userPreferences,
    BuildContext? buildContext,
  }) async {
    try {
      debugPrint('AIService: Fetching trending investments...');
      
      final data = {
        if (marketContext != null) 'marketContext': marketContext,
        if (userPreferences != null) 'userPreferences': userPreferences,
      };
      
      final response = await _httpClient.post('/ai/trending-investments', data, context: buildContext);
      
      if (response['success'] == true && response['data'] != null) {
        final investments = List<Map<String, dynamic>>.from(response['data']['trendingInvestments'] ?? []);
        debugPrint('AIService: Fetched ${investments.length} trending investments');
        return investments;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch trending investments');
      }
    } catch (e) {
      debugPrint('AIService: Error fetching trending investments: $e');
      throw Exception('Failed to load trending investments: $e');
    }
  }

  /// Get daily investment tip from Groq API
  Future<Map<String, dynamic>> getDailyInvestmentTip({
    String? userContext,
    BuildContext? buildContext,
  }) async {
    try {
      debugPrint('AIService: Fetching daily investment tip...');
      
      final data = {
        if (userContext != null) 'userContext': userContext,
      };
      
      final response = await _httpClient.post('/ai/daily-tip', data, context: buildContext);
      
      if (response['success'] == true && response['data'] != null) {
        final tip = Map<String, dynamic>.from(response['data']['tip'] ?? {});
        debugPrint('AIService: Fetched daily investment tip');
        return tip;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch daily investment tip');
      }
    } catch (e) {
      debugPrint('AIService: Error fetching daily investment tip: $e');
      throw Exception('Failed to load daily investment tip: $e');
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
    _insights.clear();
    _recommendations.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
} 