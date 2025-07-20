import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment_model.dart';
import '../services/ai_service.dart';

class InvestmentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  
  List<InvestmentModel> _investments = [];
  double _totalBalance = 0;
  bool _isLoading = false;
  
  List<InvestmentModel> get investments => _investments;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;
  
  Future<void> loadInvestments(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('investments')
          .where('userId', isEqualTo: userId)
          .get();
      
      _investments = snapshot.docs
          .map((doc) => InvestmentModel.fromMap(doc.data()))
          .toList();
      
      _calculateTotalBalance();
    } catch (e) {
      print('Error loading investments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _calculateTotalBalance() {
    _totalBalance = _investments.fold(0, (sum, investment) => sum + investment.currentValue);
  }
  
  Future<List<Map<String, dynamic>>> simulateInvestment(double amount, String assetType) async {
    try {
      // Use AI service to generate investment scenarios
      return await _aiService.generateInvestmentScenarios(amount, assetType);
    } catch (e) {
      print('Error simulating investment: $e');
      return [];
    }
  }
  
  Future<bool> createInvestment(InvestmentModel investment) async {
    try {
      await _firestore.collection('investments').add(investment.toMap());
      _investments.add(investment);
      _calculateTotalBalance();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating investment: $e');
      return false;
    }
  }
}
