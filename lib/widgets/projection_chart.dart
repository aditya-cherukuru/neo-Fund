// lib/widgets/projection_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProjectionChart extends StatelessWidget {
  final Map<int, Map<String, double>> data;
  final String selectedTheme;

  const ProjectionChart({
    Key? key,
    required this.data,
    required this.selectedTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    final months = [6, 12, 24];

    for (int i = 0; i < months.length; i++) {
      double value = data[months[i]]![selectedTheme]!;
      spots.add(FlSpot(months[i].toDouble(), value));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) => Text("${val.toInt()}m"),
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
