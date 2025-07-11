import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool _isLoading = false;
  String _currentPage = 'home';
  
  bool get isLoading => _isLoading;
  String get currentPage => _currentPage;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setCurrentPage(String page) {
    _currentPage = page;
    notifyListeners();
  }
}
