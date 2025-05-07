// lib/widgets/projection_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_projection.dart';

class ProjectionChart extends StatelessWidget {
  final Map<String, InvestmentProjection> projections;
  final List<int> timeframes;
  
  const ProjectionChart({
    Key? key,
    required this.projections,
    required this.timeframes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projected Growth Over Time',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            _createChartData(context),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(context),
      ],
    );
  }

  LineChartData _createChartData(BuildContext context) {
    // Colors for different paths
    final pathColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    
    // Create a line for each projection
    final lineBarsData = <LineChartBarData>[];
    var colorIndex = 0;
    
    for (final entry in projections.entries) {
      final pathName = entry.key;
      final projection = entry.value;
      
      // Sort projections by month
      final sortedProjections = List.of(projection.projections)
        ..sort((a, b) => a.months.compareTo(b.months));
      
      // Create data points
      final spots = <FlSpot>[];
      
      // Add initial point (0, initialAmount)
      spots.add(FlSpot(0, projection.initialAmount));
      
      // Add points for each timeframe
      for (final timeProj in sortedProjections) {
        spots.add(FlSpot(
          timeProj.months.toDouble(),
          timeProj.projectedAmount,
        ));
      }
      
      // Create a line
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: pathColors[colorIndex % pathColors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: pathColors[colorIndex % pathColors.length].withOpacity(0.2),
          ),
        ),
      );
      
      colorIndex++;
    }
    
    // Find max value for Y axis
    double maxY = 0;
    for (final proj in projections.values) {
      for (final timeProj in proj.projections) {
        if (timeProj.projectedAmount > maxY) {
          maxY = timeProj.projectedAmount;
        }
      }
    }
    
    // Add 10% buffer to max Y
    maxY *= 1.1;
    
    // Find max months for X axis
    int maxMonths = 0;
    for (final month in timeframes) {
      if (month > maxMonths) {
        maxMonths = month;
      }
    }
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                meta: meta,
                angle: 0,
                child: Text(
                  value == 0 ? '0' : 
                  timeframes.contains(value.toInt()) ? '${value.toInt()}m' : '',
                  style: const TextStyle(
                    color: Color(0xff68737d),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                meta: meta,
                space: 4,
                angle: 0,
                child: Text(
                  _formatCurrency(value),
                  style: const TextStyle(
                    color: Color(0xff67727d),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: maxMonths.toDouble(),
      lineBarsData: lineBarsData,
      minY: 0,
      maxY: maxY,
    );
  }
  
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }
  
  Widget _buildLegend(BuildContext context) {
    // Colors for different paths - must match the chart colors
    final pathColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    
    final legendItems = <Widget>[];
    var colorIndex = 0;
    
    for (final entry in projections.entries) {
      final pathName = entry.key;
      final projection = entry.value;
      
      legendItems.add(
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: pathColors[colorIndex % pathColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${projection.pathName} (${projection.potentialReturn.toStringAsFixed(2)}% return)',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
      
      colorIndex++;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...legendItems,
        const SizedBox(height: 8),
        const Text(
          'Projections based on AI analysis of historical data and market trends',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
