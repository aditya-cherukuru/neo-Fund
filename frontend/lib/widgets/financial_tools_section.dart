import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tool_card.dart';

class FinancialToolsSection extends StatelessWidget {
  final VoidCallback? onForecast;
  final VoidCallback? onPortfolio;
  final VoidCallback? onInsights;
  final VoidCallback? onVoiceQA;

  const FinancialToolsSection({
    super.key,
    this.onForecast,
    this.onPortfolio,
    this.onInsights,
    this.onVoiceQA,
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
              'Financial Tools',
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
                  child: ToolCard(
                    title: 'AI Forecast',
                    subtitle: 'Investment predictions',
                    icon: Icons.trending_up,
                    onTap: onForecast,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ToolCard(
                    title: 'Portfolio',
                    subtitle: 'Manage investments',
                    icon: Icons.pie_chart,
                    onTap: onPortfolio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ToolCard(
                    title: 'Insights',
                    subtitle: 'Performance analysis',
                    icon: Icons.analytics,
                    onTap: onInsights,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ToolCard(
                    title: 'Voice QA',
                    subtitle: 'Ask questions',
                    icon: Icons.mic,
                    onTap: onVoiceQA,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 