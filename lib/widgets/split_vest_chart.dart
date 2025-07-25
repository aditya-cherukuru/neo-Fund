import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../utils/theme.dart';

class SplitVestChart extends StatelessWidget {
  final Map<String, double> allocation;

  const SplitVestChart({super.key, required this.allocation});

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colorMap = {
      'Crypto': AppTheme.primaryPurple,
      'Stocks': AppTheme.accentGreen,
      'Funds': AppTheme.accentBlue,
    };

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(sections: [], sectionsSpace: 3, centerSpaceRadius: 40),
      ),
    );
  }
}
