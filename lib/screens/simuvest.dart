import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/investment_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/scenario_card.dart';

class SimuVestScreen extends StatefulWidget {
  const SimuVestScreen({super.key});

  @override
  State<SimuVestScreen> createState() => _SimuVestScreenState();
}

class _SimuVestScreenState extends State<SimuVestScreen> {
  List<Map<String, dynamic>> _scenarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    final investmentProvider = Provider.of<InvestmentProvider>(context, listen: false);
    
    // Simulate loading scenarios
    await Future.delayed(const Duration(seconds: 2));
    
    final scenarios = await investmentProvider.simulateInvestment(100, 'Mixed Portfolio');
    
    setState(() {
      _scenarios = scenarios.isNotEmpty ? scenarios : [
        {
          "scenario": "Bullish",
          "value": 123.0,
          "description": "could become",
          "newsEvent": "Tech sector rally boosts portfolio"
        },
        {
          "scenario": "Neutral",
          "value": 112.0,
          "description": "might become",
          "newsEvent": "Steady market conditions prevail"
        },
        {
          "scenario": "Bearish",
          "value": 88.0,
          "description": "may become",
          "newsEvent": "Market correction affects growth"
        }
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimuVest Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/invest'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating investment scenarios...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Investment Amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '₹100',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 48,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Investment',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scenarios Title
                  Text(
                    'Possible Outcomes',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-generated scenarios based on market analysis',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Scenario Cards
                  ..._scenarios.map((scenario) => ScenarioCard(
                    scenario: scenario,
                    onSelect: () => _selectScenario(scenario),
                  )),
                  
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/invest'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: AppTheme.textSecondary),
                          ),
                          child: const Text('Try Again'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _selectScenario(Map<String, dynamic> scenario) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${scenario['scenario']} scenario'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
