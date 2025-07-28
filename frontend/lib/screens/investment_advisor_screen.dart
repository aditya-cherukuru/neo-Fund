import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart'; // Import to access environmentVariables
import '../services/ai_service.dart'; // Import AIService

class InvestmentAdvisorScreen extends StatefulWidget {
  const InvestmentAdvisorScreen({super.key});

  @override
  State<InvestmentAdvisorScreen> createState() =>
      _InvestmentAdvisorScreenState();
}

class _InvestmentAdvisorScreenState extends State<InvestmentAdvisorScreen> {
  String _selectedGoal = 'Short-Term';
  String _selectedRisk = 'Medium';
  final TextEditingController _budgetController = TextEditingController();
  bool _isStrategyLoading = false;
  List<Map<String, String>>? _strategySteps;
  String? _strategyError;

  final List<String> _goals = [
    'Short-Term',
    'Long-Term',
    'Passive Income',
    'Retirement',
  ];
  final List<String> _risks = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _getStrategy() async {
    final budget = _budgetController.text.trim();
    if (budget.isEmpty) {
      setState(() {
        _strategyError = 'Please enter your investment budget.';
      });
      return;
    }
    setState(() {
      _isStrategyLoading = true;
      _strategyError = null;
      _strategySteps = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    // Simulate a friendly, interactive strategy breakdown
    setState(() {
      _isStrategyLoading = false;
      _strategySteps = [
        {
          'title': 'Set Your Goal 🎯',
          'desc':
              'You chose $_selectedGoal as your investment goal. This helps us tailor your plan.'
        },
        {
          'title': 'Assess Risk 🧩',
          'desc':
              'Your risk appetite is $_selectedRisk. We will balance safety and growth accordingly.'
        },
        {
          'title': 'Budget Allocation 💸',
          'desc':
              'With a budget of ₹$budget, we recommend splitting your funds across different asset classes.'
        },
        {
          'title': 'Personalized Steps 🚀',
          'desc': _personalizedSteps(_selectedGoal, _selectedRisk, budget)
        },
        {
          'title': 'Review & Start 📈',
          'desc':
              'Review your plan and start investing! Remember, consistency is key.'
        },
      ];
    });
  }

  String _personalizedSteps(String goal, String risk, String budget) {
    if (risk == 'Low') {
      return '• Put 60% (₹${(int.tryParse(budget) ?? 0) * 0.6 ~/ 1}) in high-yield savings or bonds 🏦\n• 30% (₹${(int.tryParse(budget) ?? 0) * 0.3 ~/ 1}) in index funds 📊\n• 10% (₹${(int.tryParse(budget) ?? 0) * 0.1 ~/ 1}) in gold or REITs 🪙';
    } else if (risk == 'Medium') {
      return '• 50% (₹${(int.tryParse(budget) ?? 0) * 0.5 ~/ 1}) in index funds 📊\n• 30% (₹${(int.tryParse(budget) ?? 0) * 0.3 ~/ 1}) in blue-chip stocks 💼\n• 20% (₹${(int.tryParse(budget) ?? 0) * 0.2 ~/ 1}) in bonds or REITs 🏦';
    } else {
      return '• 60% (₹${(int.tryParse(budget) ?? 0) * 0.6 ~/ 1}) in stocks 🚀\n• 20% (₹${(int.tryParse(budget) ?? 0) * 0.2 ~/ 1}) in sector/thematic funds 🌐\n• 20% (₹${(int.tryParse(budget) ?? 0) * 0.2 ~/ 1}) in crypto/alternatives ₿';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalized AI Strategy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight -
                40, // 40 for padding
          ),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text('Personalized AI Strategy',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Investment Goal Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGoal,
                    items: _goals
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: _isStrategyLoading
                        ? null
                        : (val) {
                            setState(() => _selectedGoal = val!);
                          },
                    decoration: const InputDecoration(
                      labelText: 'Investment Goal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Risk Appetite Section
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Risk Appetite',
                      border: OutlineInputBorder(),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _risks
                          .map((risk) => ChoiceChip(
                                label: Text(risk),
                                selected: _selectedRisk == risk,
                                onSelected: _isStrategyLoading
                                    ? null
                                    : (selected) {
                                        if (selected)
                                          setState(() => _selectedRisk = risk);
                                      },
                                selectedColor: risk == 'Low'
                                    ? Colors.green[100]
                                    : risk == 'Medium'
                                        ? Colors.orange[100]
                                        : Colors.red[100],
                                labelStyle: TextStyle(
                                  color: _selectedRisk == risk
                                      ? Colors.black
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    enabled: !_isStrategyLoading,
                    decoration: const InputDecoration(
                      labelText: 'Investment Budget',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_graph),
                      label: Text(_isStrategyLoading
                          ? 'Generating...'
                          : 'Get Strategy'),
                      onPressed: _isStrategyLoading ? null : _getStrategy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (_strategyError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_strategyError!,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.red[700])),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_isStrategyLoading)
                    Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 12),
                        Text('Generating your personalized strategy...'),
                      ],
                    ),
                  if (_strategySteps != null && !_isStrategyLoading)
                    _buildStrategySteps(_strategySteps!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrategySteps(List<Map<String, String>> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Step-by-Step Strategy:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          return ExpansionTile(
            key: PageStorageKey('strategy_step_$idx'),
            initiallyExpanded: idx == 0,
            leading: CircleAvatar(child: Text('${idx + 1}')),
            title: Text(
              step['title'] ?? '',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Text(
                  step['desc'] ?? '',
                  style: TextStyle(fontSize: 15),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
