import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/investment_forecast_service.dart';
import 'providers.dart';

class TestInvestmentForecast extends StatefulWidget {
  const TestInvestmentForecast({Key? key}) : super(key: key);

  @override
  State<TestInvestmentForecast> createState() => _TestInvestmentForecastState();
}

class _TestInvestmentForecastState extends State<TestInvestmentForecast> {
  String _testResult = 'Click to test';
  bool _isLoading = false;

  Future<void> _testForecastService() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing...';
    });

    try {
      final service = context.read<InvestmentForecastService>();
      
      // Test symbol search
      final symbols = await service.searchSymbols('AAPL');
      print('Found ${symbols.length} symbols for AAPL');
      
      // Test investment analysis
      final analysis = await service.analyzeInvestmentHistory(
        investmentAmount: 1000,
        duration: 4,
        riskPreference: 'Medium',
        investmentType: 'Stocks',
        symbol: 'TSLA',
      );
      
      print('Analysis result: ${analysis['summary']}');
      
      setState(() {
        _testResult = '✅ Test successful!\n'
            'Symbols found: ${symbols.length}\n'
            'Analysis: ${analysis['summary']}\n'
            'Performance: ${analysis['performance']}';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Test failed: $e';
      });
      print('Test error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Forecast Test'),
        backgroundColor: Colors.purple.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.purple.shade900,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Investment Forecast Service Test',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testForecastService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Run Test',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Go to Dashboard',
                style: TextStyle(color: Colors.purple.shade900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 