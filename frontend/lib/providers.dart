import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/http_client.dart';
import 'services/user_service.dart';
import 'services/investment_service.dart';
import 'services/investment_forecast_service.dart';
import 'services/ai_service.dart';
import 'services/forecast_notification_service.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

final appProviders = [
  ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
  ChangeNotifierProvider<DashboardService>(create: (_) => DashboardService()),
  ChangeNotifierProvider<UserService>(create: (_) => UserService()),
  ChangeNotifierProvider<InvestmentService>(create: (_) => InvestmentService()),
                ChangeNotifierProvider<InvestmentForecastService>(create: (_) => InvestmentForecastService()),
  ChangeNotifierProvider<AIService>(create: (_) => AIService()),
  ChangeNotifierProvider<ForecastNotificationService>(create: (_) => ForecastNotificationService()),
  Provider<HttpClient>(create: (_) => HttpClient()),
]; 