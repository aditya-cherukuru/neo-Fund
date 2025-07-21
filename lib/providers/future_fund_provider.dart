import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FutureFundProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _activeMilestones = [];
  List<Map<String, dynamic>> _sponsors = [];
  double _totalSponsored = 0;
  int _activeSponsorships = 0;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get activeMilestones => _activeMilestones;
  List<Map<String, dynamic>> get sponsors => _sponsors;
  double get totalSponsored => _totalSponsored;
  int get activeSponsorships => _activeSponsorships;
  bool get isLoading => _isLoading;
  
  Future<void> loadMilestones() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Mock data for demonstration
      _activeMilestones = [
        {
          'id': '1',
          'title': 'Save ₹1000 in 30 days',
          'type': 'Savings Goal',
          'targetAmount': 1000,
          'currentAmount': 750,
          'reward': 100,
          'deadline': DateTime.now().add(const Duration(days: 10)),
          'sponsor': 'Mom',
          'description': 'Build your emergency fund',
        },
        {
          'id': '2',
          'title': 'Avoid high-risk investments for 2 weeks',
          'type': 'Risk Management',
          'targetAmount': 0,
          'currentAmount': 0,
          'reward': 50,
          'deadline': DateTime.now().add(const Duration(days: 5)),
          'sponsor': 'Dad',
          'description': 'Learn patience and risk management',
        },
      ];
      
      _sponsors = [
        {
          'id': '1',
          'name': 'Mom',
          'avatar': '👩',
          'totalSponsored': 500,
          'activeMilestones': 2,
        },
        {
          'id': '2',
          'name': 'Dad',
          'avatar': '👨',
          'totalSponsored': 300,
          'activeMilestones': 1,
        },
      ];
      
      _totalSponsored = 800;
      _activeSponsorships = 2;
      
    } catch (e) {
      print('Error loading milestones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createMilestone(String title, String type, double amount, String description) async {
    try {
      final milestone = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'type': type,
        'targetAmount': amount,
        'currentAmount': 0,
        'reward': amount * 0.1, // 10% reward
        'deadline': DateTime.now().add(const Duration(days: 30)),
        'sponsor': 'Pending',
        'description': description,
      };
      
      _activeMilestones.add(milestone);
      notifyListeners();
      
      await _firestore.collection('milestones').add(milestone);
      
    } catch (e) {
      print('Error creating milestone: $e');
    }
  }
  
  Future<void> claimMilestone(String milestoneId) async {
    try {
      _activeMilestones.removeWhere((milestone) => milestone['id'] == milestoneId);
      notifyListeners();
 
    } catch (e) {
      print('Error claiming milestone: $e');
    }
  }
}
