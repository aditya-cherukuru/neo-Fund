import 'package:flutter/material.dart';
import '../utils/theme.dart';

class MilestoneCard extends StatelessWidget {
  final Map<String, dynamic> milestone;
  final VoidCallback onClaim;

  const MilestoneCard({
    super.key,
    required this.milestone,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = milestone['targetAmount'] > 0
        ? (milestone['currentAmount'] / milestone['targetAmount']).clamp(0.0, 1.0)
        : 0.0;

    final deadline = milestone['deadline'] as DateTime;
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(milestone['type']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  milestone['type'],
                  style: TextStyle(
                    color: _getTypeColor(milestone['type']),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            milestone['title'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            milestone['description'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (milestone['targetAmount'] > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${milestone['currentAmount'].toStringAsFixed(0)} / ₹${milestone['targetAmount'].toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Sponsored by ${milestone['sponsor']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                daysLeft > 0 ? '$daysLeft days left' : 'Expired',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: daysLeft > 0 ? AppTheme.textSecondary : AppTheme.accentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Reward: ₹${milestone['reward']}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Savings Goal':
        return AppTheme.accentGreen;
      case 'Investment Challenge':
        return AppTheme.primaryPurple;
      case 'Risk Management':
        return AppTheme.accentBlue;
      case 'Learning Achievement':
        return Colors.amber;
      default:
        return AppTheme.textSecondary;
    }
  }
}
