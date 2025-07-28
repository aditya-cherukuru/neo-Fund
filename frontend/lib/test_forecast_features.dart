import 'package:flutter/material.dart';
import 'models/forecast_entry.dart';
import 'services/forecast_notification_service.dart';

/// Test file to demonstrate the new forecast features
/// This file shows how the new features work:
/// 
/// 1. Portfolio Review Page - Forecast History Handling:
///    - Each forecast is stored as a "holding" in the portfolio
///    - Holdings have expandable history with previous forecasts collapsed by default
///    - Most recent holding's forecast is expanded by default
///    - When a new forecast is made, it becomes the new most recent report
/// 
/// 2. Portfolio Balance Display:
///    - Shows the most recent investment amount based on the latest forecast
///    - Updates automatically when new forecasts are generated
/// 
/// 3. Homepage - Recent Insight Preview:
///    - Displays AI-generated insights of the most recent holding
///    - Refreshes automatically when new forecasts are generated
///    - Shows investment amount and key insights

class ForecastFeaturesTest {
  static void testForecastNotification() {
    // Simulate a new forecast being generated
    final testForecast = ForecastEntry(
      timestamp: DateTime.now(),
      userInput: {
        'investmentAmount': 50000,
        'riskProfile': 'Moderate',
        'timeHorizon': '5 years',
        'investmentType': 'Stocks',
      },
      forecastResult: {
        'keyTakeaways': [
          'Your moderate risk profile suggests a balanced portfolio approach',
          'Consider diversifying across different sectors for better risk management',
          'The 5-year horizon allows for compound growth potential',
        ],
        'riskAnalysis': 'Moderate risk with potential for 8-12% annual returns',
        'recommendations': [
          'Allocate 60% to stocks, 30% to bonds, 10% to alternatives',
          'Rebalance portfolio quarterly',
          'Consider tax-efficient investment vehicles',
        ],
      },
    );

    // Notify the system about the new forecast
    ForecastNotificationService().notifyNewForecast({
      'type': 'new_forecast',
      'forecast': testForecast.toJson(),
    });

    print('Test forecast notification sent');
  }

  static void testForecastUpdate() {
    // Simulate forecasts being updated
    ForecastNotificationService().notifyForecastsUpdated();
    print('Test forecast update notification sent');
  }
}

/// Example usage in a widget:
/// 
/// ```dart
/// class TestWidget extends StatefulWidget {
///   @override
///   State<TestWidget> createState() => _TestWidgetState();
/// }
/// 
/// class _TestWidgetState extends State<TestWidget> {
///   StreamSubscription? _forecastSubscription;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _setupForecastListener();
///   }
/// 
///   void _setupForecastListener() {
///     _forecastSubscription = ForecastNotificationService().forecastStream.listen((data) {
///       if (mounted) {
///         // Refresh the UI with new forecast data
///         setState(() {
///           // Update UI components
///         });
///       }
///     });
///   }
/// 
///   @override
///   void dispose() {
///     _forecastSubscription?.cancel();
///     super.dispose();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ElevatedButton(
///           onPressed: () => ForecastFeaturesTest.testForecastNotification(),
///           child: Text('Test New Forecast'),
///         ),
///         ElevatedButton(
///           onPressed: () => ForecastFeaturesTest.testForecastUpdate(),
///           child: Text('Test Forecast Update'),
///         ),
///       ],
///     );
///   }
/// }
/// ``` 