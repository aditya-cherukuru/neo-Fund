import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double totalBudget;
  final double spent;
  final double remaining;
  final String period;

  const BudgetOverviewCard({
    super.key,
    required this.totalBudget,
    required this.spent,
    required this.remaining,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spentPercentage = totalBudget > 0 ? spent / totalBudget : 0.0;
    final isOverBudget = spent > totalBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Overview',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetItem(
                    context,
                    'Spent',
                    spent,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetItem(
                    context,
                    'Remaining',
                    remaining,
                    isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(spentPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: spentPercentage > 1 ? 1 : spentPercentage,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : AppTheme.lightModePurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
} 