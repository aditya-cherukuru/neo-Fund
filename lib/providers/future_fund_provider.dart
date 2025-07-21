import 'package:flutter/material.dart';

class FutureFundProvider extends ChangeNotifier {
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
}
