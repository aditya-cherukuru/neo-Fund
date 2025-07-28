import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpendingChart extends StatelessWidget {
  final List<Map<String, dynamic>> spendingData;

  const SpendingChart({
    super.key,
    required this.spendingData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Overview',
              style: TextStyle(
                color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: spendingData.isEmpty
                  ? Center(
                      child: Text(
                        'No spending data available',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                        ),
                      ),
                    )
                  : _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxAmount = spendingData.fold<double>(
      0,
      (max, item) => item['amount'] > max ? item['amount'] : max,
    );

    return Column(
      children: spendingData.map((item) {
        final percentage = maxAmount > 0 ? item['amount'] / maxAmount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  item['category'],
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '\$${item['amount'].toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 