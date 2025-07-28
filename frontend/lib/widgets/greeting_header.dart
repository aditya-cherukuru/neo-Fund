import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;
  final String timeOfDay;

  const GreetingHeader({
    super.key,
    required this.userName,
    required this.timeOfDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good $timeOfDay,',
            style: TextStyle(
              color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: TextStyle(
              color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 