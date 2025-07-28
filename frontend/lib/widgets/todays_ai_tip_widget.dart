import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TodaysAiTipWidget extends StatelessWidget {
  final String tip;
  final VoidCallback? onTap;

  const TodaysAiTipWidget({
    super.key,
    required this.tip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? AppTheme.darkModePurple.withOpacity(0.1) : AppTheme.lightModePurple.withOpacity(0.1),
                isDark ? AppTheme.darkModePurple.withOpacity(0.05) : AppTheme.lightModePurple.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's AI Tip",
                    style: TextStyle(
                      color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip,
                style: TextStyle(
                  color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap for more tips',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 