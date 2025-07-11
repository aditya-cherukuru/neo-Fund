import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ai_service.dart';

class FutureYouProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  
  Map<String, dynamic> _currentPersonality = {};
  List<FlSpot> _personalityEvolution = [];
  double _projectedNetWorth = 0;
  String _projectedRiskProfile = '';
  int _investmentMaturityScore = 0;
  List<String> _recommendations = [];
  bool _isLoading = false;
  
  Map<String, dynamic> get currentPersonality => _currentPersonality;
  List<FlSpot> get personalityEvolution => _personalityEvolution;
  double get projectedNetWorth => _projectedNetWorth;
  String get projectedRiskProfile => _projectedRiskProfile;
  int get investmentMaturityScore => _investmentMaturityScore;
  List<String> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  
  Future<void> analyzePersonality() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Simulate AI analysis
      await Future.delayed(const Duration(seconds: 3));
      
      _currentPersonality = {
        'type': 'Cautious Optimist',
        'description': 'You prefer steady growth with calculated risks. Your investment style shows patience and long-term thinking.',
        'traits': ['Patient', 'Analytical', 'Risk-Aware', 'Growth-Focused'],
        'riskScore': 6.5,
        'confidenceLevel': 78,
      };
      
      _personalityEvolution = [
        const FlSpot(0, 4.0), // Started cautious
        const FlSpot(1, 4.5),
        const FlSpot(2, 5.2),
        const FlSpot(3, 6.0),
        const FlSpot(4, 6.5), // Current
        const FlSpot(5, 7.2), // Projected
      ];
      
      _projectedNetWorth = 250000;
      _projectedRiskProfile = 'Balanced Growth';
      _investmentMaturityScore = 78;
      
      _recommendations = [
        'Consider increasing your crypto allocation to 15% for higher growth potential',
        'Your consistent investment pattern suggests you\'re ready for medium-risk ETFs',
        'Based on your age and goals, consider adding international diversification',
        'Your patience with long-term investments is a strength - maintain this approach',
      ];
      
    } catch (e) {
      print('Error analyzing personality: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
