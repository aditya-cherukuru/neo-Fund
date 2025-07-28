import 'dart:async';
import 'package:flutter/foundation.dart';

class ForecastNotificationService extends ChangeNotifier {
  static final ForecastNotificationService _instance = ForecastNotificationService._internal();
  factory ForecastNotificationService() => _instance;
  ForecastNotificationService._internal();

  final StreamController<Map<String, dynamic>> _forecastController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get forecastStream => _forecastController.stream;

  // Notify when a new forecast is generated
  void notifyNewForecast(Map<String, dynamic> forecastData) {
    debugPrint('ForecastNotificationService: New forecast generated');
    _forecastController.add(forecastData);
    notifyListeners();
  }

  // Notify when forecasts are updated
  void notifyForecastsUpdated() {
    debugPrint('ForecastNotificationService: Forecasts updated');
    _forecastController.add({'type': 'forecasts_updated'});
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _forecastController.close();
    super.dispose();
  }
} 