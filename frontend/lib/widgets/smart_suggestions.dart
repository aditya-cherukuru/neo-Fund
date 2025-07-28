import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SmartSuggestions extends StatelessWidget {
  final List<String> suggestions;

  const SmartSuggestions({
    super.key,
    required this.suggestions,
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
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Suggestions',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkModeText : AppTheme.lightModeText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkModePurple : AppTheme.lightModePurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkModeTextSecondary : AppTheme.lightModeTextSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
} 