import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/theme.dart';
import '../../services/ai_service.dart';

class InvestmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> investment;

  const InvestmentDetailsScreen({
    super.key,
    required this.investment,
  });

  @override
  State<InvestmentDetailsScreen> createState() => _InvestmentDetailsScreenState();
}

class _InvestmentDetailsScreenState extends State<InvestmentDetailsScreen> {
  final AIService _aiService = AIService();
  String _aiAnalysis = '';
  bool _isLoadingAnalysis = true;

  @override
  void initState() {
    super.initState();
    _loadAIAnalysis();
  }

  Future<void> _loadAIAnalysis() async {
    try {
      final analysis = await _aiService.explainAssetType(widget.investment['strategy']);
      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAnalysis = false;
      });
    } catch (e) {
      setState(() {
        _aiAnalysis = 'Analysis temporarily unavailable. Please try again later.';
        _isLoadingAnalysis = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final investment = widget.investment;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(investment['userName']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      investment['userName'][0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    investment['userName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip('${investment['followers']} Followers'),
                      const SizedBox(width: 12),
                      _buildStatChip('${investment['accuracy']}% Accuracy'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Return',
                    '+${investment['return']}%',
                    Icons.trending_up,
                    AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Risk Level',
                    investment['riskLevel'],
                    Icons.warning,
                    _getRiskColor(investment['riskLevel']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Duration',
                    investment['duration'],
                    Icons.schedule,
                    AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Invested',
                    '₹${investment['totalInvested']}',
                    Icons.account_balance_wallet,
                    AppTheme.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Performance History',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

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
                      spots: _generatePerformanceData(),
                      isCurved: true,
                      color: AppTheme.accentGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Investment Strategy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                investment['strategy'],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'AI Analysis',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGreen.withOpacity(0.3),
                ),
              ),
              child: _isLoadingAnalysis
                  ? const Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 12),
                        Text('AI is analyzing this strategy...'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: AppTheme.accentGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Powered by Gemini AI',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aiAnalysis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppTheme.accentGreen;
      case 'medium':
        return Colors.amber;
      case 'high':
        return AppTheme.accentRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  List<FlSpot> _generatePerformanceData() {
    return [
      const FlSpot(0, 100),
      const FlSpot(1, 105),
      const FlSpot(2, 110),
      const FlSpot(3, 115),
      const FlSpot(4, 125),
      const FlSpot(5, 130),
      const FlSpot(6, 145),
    ];
  }
}
