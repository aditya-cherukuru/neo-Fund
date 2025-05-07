// lib/blocs/simuvest_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/investment_path.dart';
import '../models/investment_projection.dart';
import '../services/ai_investment_service.dart';

enum SimuvestState { initial, loading, loaded, error }

class SimuvestBloc {
  final AIInvestmentService _aiService = AIInvestmentService();
  
  // Controllers
  final _stateController = StreamController<SimuvestState>.broadcast();
  final _pathsController = StreamController<List<InvestmentPath>>.broadcast();
  final _projectionsController = StreamController<Map<String, InvestmentProjection>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Streams
  Stream<SimuvestState> get state => _stateController.stream;
  Stream<List<InvestmentPath>> get paths => _pathsController.stream;
  Stream<Map<String, InvestmentProjection>> get projections => _projectionsController.stream;
  Stream<String> get error => _errorController.stream;
  
  // Current data
  List<InvestmentPath> _currentPaths = [];
  Map<String, InvestmentProjection> _currentProjections = {};
  
  // Load initial investment paths
  Future<void> loadInvestmentPaths(Map<String, dynamic> userProfile) async {
    _stateController.add(SimuvestState.loading);
    
    try {
      final paths = await _aiService.getRecommendedPaths(userProfile);
      _currentPaths = paths;
      _pathsController.add(paths);
      _stateController.add(SimuvestState.loaded);
    } catch (e) {
      _errorController.add(e.toString());
      _stateController.add(SimuvestState.error);
    }
  }
  
  // Get projections for a specified amount across multiple paths
  Future<void> getProjectionsForAmount(double amount, List<String> pathIds, List<int> timeframes) async {
    _stateController.add(SimuvestState.loading);
    
    try {
      final Map<String, InvestmentProjection> results = {};
      
      for (String pathId in pathIds) {
        final projection = await _aiService.getProjection(pathId, amount, timeframes);
        results[pathId] = projection;
      }
      
      _currentProjections = results;
      _projectionsController.add(results);
      _stateController.add(SimuvestState.loaded);
    } catch (e) {
      _errorController.add(e.toString());
      _stateController.add(SimuvestState.error);
    }
  }
  
  // Compare two specific paths
  Map<String, dynamic> comparePaths(String pathId1, String pathId2) {
    if (!_currentProjections.containsKey(pathId1) || 
        !_currentProjections.containsKey(pathId2)) {
      throw Exception('One or both paths not found in current projections');
    }
    
    final proj1 = _currentProjections[pathId1]!;
    final proj2 = _currentProjections[pathId2]!;
    
    // Compare performance at different timeframes
    final comparison = <String, dynamic>{
      'difference_percentage': (proj1.potentialReturn - proj2.potentialReturn),
      'timeframe_comparison': <int, Map<String, dynamic>>{},
    };
    
    // Map timeframes for easy comparison
    final proj1TimeMap = {for (var tp in proj1.projections) tp.months: tp};
    final proj2TimeMap = {for (var tp in proj2.projections) tp.months: tp};
    
    // Compare each timeframe that exists in both projections
    for (final month in proj1TimeMap.keys.toSet().intersection(proj2TimeMap.keys.toSet())) {
      final tp1 = proj1TimeMap[month]!;
      final tp2 = proj2TimeMap[month]!;
      
      comparison['timeframe_comparison'][month] = {
        'path1_amount': tp1.projectedAmount,
        'path2_amount': tp2.projectedAmount,
        'difference': tp1.projectedAmount - tp2.projectedAmount,
        'difference_percentage': 
            ((tp1.projectedAmount / tp2.projectedAmount) - 1) * 100,
      };
    }
    
    return comparison;
  }
  
  void dispose() {
    _stateController.close();
    _pathsController.close();
    _projectionsController.close();
    _errorController.close();
  }
}