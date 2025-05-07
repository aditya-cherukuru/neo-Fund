// lib/widgets/comparison_view.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_projection.dart';

class ComparisonView extends StatelessWidget {
  final Map<String, dynamic> comparison;
  final InvestmentProjection projection1;
  final InvestmentProjection projection2;
  final List<int> timeframes;

  const ComparisonView({
    Key? key,
    required this.comparison,
    required this.projection1,
    required this.projection2,
    required this.timeframes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Path Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildComparisonChart(context),
            const SizedBox(height: 24),
            _buildComparisonStats(context),
            const SizedBox(height: 24),
            _buildBreakdownTable(context),
            const SizedBox(height: 24),
            _buildComparisonInsights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final differencePercentage = comparison['difference_percentage'] as double;
    final isPositive = differencePercentage > 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparing Paths',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    projection1.pathName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Text(
                  'vs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: Text(
                    projection2.pathName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isPositive ? 'Path 1 outperforms by:' : 'Path 2 outperforms by:',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isPositive ? '+' : ''}${differencePercentage.abs().toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(BuildContext context) {
    // Prepare data for chart
    final timeframeComparison = comparison['timeframe_comparison'] as Map<int, Map<String, dynamic>>;
    
    // Sort timeframes
    final sortedTimeframes = timeframeComparison.keys.toList()..sort();
    
    final List<FlSpot> spots1 = [FlSpot(0, projection1.initialAmount)];
    final List<FlSpot> spots2 = [FlSpot(0, projection2.initialAmount)];
    
    for (final month in sortedTimeframes) {
      final data = timeframeComparison[month]!;
      spots1.add(FlSpot(month.toDouble(), data['path1_amount']));
      spots2.add(FlSpot(month.toDouble(), data['path2_amount']));
    }
    
    // Find max Y value
    double maxY = 0;
    for (final data in timeframeComparison.values) {
      maxY = maxY > data['path1_amount'] ? maxY : data['path1_amount'];
      maxY = maxY > data['path2_amount'] ? maxY : data['path2_amount'];
    }
    
    // Add 10% buffer
    maxY *= 1.1;
    
    final maxMonth = sortedTimeframes.isEmpty ? 24 : sortedTimeframes.last;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
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
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value == 0 ? '0' :
                              (value.toInt() % 6 == 0 || sortedTimeframes.contains(value.toInt())) 
                                ? '${value.toInt()}m' : '',
                            style: const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: const TextStyle(
                              color: Color(0xff67727d),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: maxMonth.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots1,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    LineChartBarData(
                      spots: spots2,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, projection1.pathName),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.red, projection2.pathName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildComparisonStats(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Potential Return',
                    '${projection1.potentialReturn.toStringAsFixed(2)}%',
                    '${projection2.potentialReturn.toStringAsFixed(2)}%',
                    projection1.potentialReturn > projection2.potentialReturn
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'AI Confidence',
                    '${(projection1.confidence * 100).toStringAsFixed(0)}%',
                    '${(projection2.confidence * 100).toStringAsFixed(0)}%',
                    projection1.confidence > projection2.confidence
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value1, String value2, bool isPath1Better) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isPath1Better ? Colors.blue : Colors.transparent,
                  width: isPath1Better ? 2 : 0,
                ),
              ),
              child: Text(
                value1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'vs',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: !isPath1Better ? Colors.red : Colors.transparent,
                  width: !isPath1Better ? 2 : 0,
                ),
              ),
              child: Text(
                value2,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownTable(BuildContext context) {
    final timeframeComparison = comparison['timeframe_comparison'] as Map<int, Map<String, dynamic>>;
    final sortedTimeframes = timeframeComparison.keys.toList()..sort();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeframe Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
                style: BorderStyle.solid,
              ),
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: [
                    _buildTableCell('Timeframe', isHeader: true),
                    _buildTableCell(projection1.pathName, isHeader: true),
                    _buildTableCell(projection2.pathName, isHeader: true),
                    _buildTableCell('Difference', isHeader: true),
                  ],
                ),
                // Data rows
                for (final month in sortedTimeframes)
                  _buildTimeframeRow(month, timeframeComparison[month]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTimeframeRow(int month, Map<String, dynamic> data) {
    final path1Amount = data['path1_amount'] as double;
    final path2Amount = data['path2_amount'] as double;
    final difference = data['difference'] as double;
    final differencePercentage = data['difference_percentage'] as double;
    final isPositive = difference > 0;
    
    return TableRow(
      children: [
        _buildTableCell('$month Months'),
        _buildTableCell('₹${path1Amount.toStringAsFixed(2)}'),
        _buildTableCell('₹${path2Amount.toStringAsFixed(2)}'),
        _buildTableCell(
          '${isPositive ? '+' : ''}₹${difference.abs().toStringAsFixed(2)} (${isPositive ? '+' : ''}${differencePercentage.abs().toStringAsFixed(2)}%)',
          textColor: isPositive ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildComparisonInsights(BuildContext context) {
    final differencePercentage = comparison['difference_percentage'] as double;
    final isPath1Better = differencePercentage > 0;
    final betterPath = isPath1Better ? projection1.pathName : projection2.pathName;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Based on our AI analysis, the $betterPath path is projected to outperform over the selected timeframes.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _getInsightText(isPath1Better),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to investment screen with selected path
                // Navigator.push(...);
              },
              child: Text('Invest in $betterPath'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInsightText(bool isPath1Better) {
    final betterPath = isPath1Better ? projection1.pathName : projection2.pathName;
    final worsePath = isPath1Better ? projection2.pathName : projection1.pathName;
    
    return 'The $betterPath path shows stronger performance likely due to its asset allocation and market conditions. However, the $worsePath path might still be worth considering if you prefer its risk profile or have specific investment goals.';
  }
}