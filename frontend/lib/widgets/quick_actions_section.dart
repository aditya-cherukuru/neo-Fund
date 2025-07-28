import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final VoidCallback? onViewPortfolio;
  final VoidCallback? onGetAdvice;
  final VoidCallback? onSetBudget;

  const QuickActionsSection({
    super.key,
    this.onAddTransaction,
    this.onViewPortfolio,
    this.onGetAdvice,
    this.onSetBudget,
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
              'Quick Actions',
              style: TextStyle(
                color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Add Transaction',
                    Icons.add,
                    onAddTransaction,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'View Portfolio',
                    Icons.pie_chart,
                    onViewPortfolio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Get Advice',
                    Icons.lightbulb,
                    onGetAdvice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Set Budget',
                    Icons.account_balance_wallet,
                    onSetBudget,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppTheme.darkModeSurface : AppTheme.lightModeSurface,
        foregroundColor: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 