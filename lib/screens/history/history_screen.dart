import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showSquadData = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between Solo and Squad
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showSquadData = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showSquadData ? AppTheme.primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Solo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_showSquadData ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showSquadData = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showSquadData ? AppTheme.primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Squad',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showSquadData ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance Chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _showSquadData ? _getSquadChartData() : _getSoloChartData(),
                      isCurved: true,
                      color: _showSquadData ? AppTheme.accentBlue : AppTheme.accentGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (_showSquadData ? AppTheme.accentBlue : AppTheme.accentGreen)
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Investment History
            Text(
              'Past Mock Investments',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            ..._buildInvestmentHistory(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  List<FlSpot> _getSoloChartData() {
    return [
      const FlSpot(0, 100),
      const FlSpot(1, 120),
      const FlSpot(2, 110),
      const FlSpot(3, 140),
      const FlSpot(4, 160),
      const FlSpot(5, 150),
      const FlSpot(6, 180),
    ];
  }

  List<FlSpot> _getSquadChartData() {
    return [
      const FlSpot(0, 100),
      const FlSpot(1, 115),
      const FlSpot(2, 125),
      const FlSpot(3, 135),
      const FlSpot(4, 145),
      const FlSpot(5, 155),
      const FlSpot(6, 170),
    ];
  }

  List<Widget> _buildInvestmentHistory() {
    final investments = [
      {
        'type': 'Crypto',
        'amount': 100,
        'result': 120,
        'date': '2 days ago',
        'icon': Icons.currency_bitcoin,
      },
      {
        'type': 'Stocks',
        'amount': 50,
        'result': 45,
        'date': '1 week ago',
        'icon': Icons.trending_up,
      },
      {
        'type': 'Funds',
        'amount': 75,
        'result': 82,
        'date': '2 weeks ago',
        'icon': Icons.account_balance,
      },
    ];

    return investments.map((investment) {
      final isProfit = (investment['result'] as int) > (investment['amount'] as int);
      final percentage = (((investment['result'] as int) - (investment['amount'] as int)) / 
          (investment['amount'] as int) * 100);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isProfit ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                investment['icon'] as IconData,
                color: isProfit ? AppTheme.accentGreen : AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment['type'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '₹${investment['amount']} → ₹${investment['result']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    investment['date'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isProfit ? AppTheme.accentGreen : AppTheme.accentRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
