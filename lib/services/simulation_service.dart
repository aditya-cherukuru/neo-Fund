// lib/services/simulation_service.dart
import 'dart:math';

class SimulationService {
  // Risk-based annual return rates
  static final Map<String, double> _multipliers = {
    "Tech": 0.18,
    "Meme": 0.25,
    "ESG": 0.12,
    "Crypto": 0.35,
    "Bluechip": 0.09,
    "Safe Bonds": 0.04
  };

  /// Returns a nested map with months -> theme -> projected value
  static Map<int, Map<String, double>> simulate(double amount) {
    final durations = [6, 12, 24];
    Map<int, Map<String, double>> result = {};

    for (int month in durations) {
      Map<String, double> themeReturns = {};
      _multipliers.forEach((theme, rate) {
        double r = pow((1 + rate), month / 12).toDouble();
        themeReturns[theme] = double.parse((amount * r).toStringAsFixed(2));
      });
      result[month] = themeReturns;
    }

    return result;
  }

  static List<String> get themes => _multipliers.keys.toList();
}
