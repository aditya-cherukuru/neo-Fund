import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecentTransactionsPreview extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentTransactionsPreview({
    super.key,
    required this.transactions,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full transactions list
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No recent transactions',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: transactions.take(3).map((transaction) => _buildTransactionItem(context, transaction)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = transaction['type'] == 'expense';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(transaction['category']),
              color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'],
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  transaction['date'],
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}\$${transaction['amount'].toStringAsFixed(2)}',
            style: TextStyle(
              color: isExpense ? Colors.red : Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.receipt;
    }
  }
} 