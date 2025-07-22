import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ScenarioCard extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final VoidCallback onSelect;

  const ScenarioCard({
    super.key,
    required this.scenario,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scenarioType = scenario['scenario'] as String;
    final value = scenario['value'] as double;
    final description = scenario['description'] as String;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  '🔷',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenarioType,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$description ₹${value.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}