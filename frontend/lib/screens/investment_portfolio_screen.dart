import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/custom_app_bar.dart';
import '../models/forecast_entry.dart';
import '../services/forecast_storage_service.dart';
import '../services/forecast_notification_service.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() => _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> {
  String _selectedPeriod = '1Y';
  List<Map<String, dynamic>> _investments = [];
  List<Map<String, dynamic>> _performanceData = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _forecastHistory = [];
  bool _loadingForecasts = false;
  int _expandedForecastIndex = 0; // Track which forecast is expanded
  StreamSubscription? _forecastSubscription;

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadForecastHistory();
    _setupForecastListener();
  }

  void _setupForecastListener() {
    _forecastSubscription?.cancel();
    _forecastSubscription = ForecastNotificationService().forecastStream.listen((data) {
      if (mounted) {
        _loadForecastHistory();
      }
    });
  }

  @override
  void dispose() {
    _forecastSubscription?.cancel();
    super.dispose();
  }

  void _toggleForecastExpansion(int index) {
    setState(() {
      if (_expandedForecastIndex == index) {
        _expandedForecastIndex = -1; // Collapse
      } else {
        _expandedForecastIndex = index; // Expand this one, collapse others
      }
    });
  }

  double get _totalPortfolioValue {
    if (_forecastHistory.isEmpty) return 0.0;
    
    // Get the most recent forecast's final value
    final latestForecast = _forecastHistory.first;
    final performance = latestForecast['performance'] as Map<String, dynamic>?;
    if (performance != null) {
      final finalValueStr = performance['Final Value'] as String?;
      if (finalValueStr != null) {
        return double.tryParse(finalValueStr.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
      }
    }
    return 0.0;
  }

  double get _totalInvestmentAmount {
    if (_forecastHistory.isEmpty) return 0.0;
    
    // Get the most recent forecast's investment amount
    final latestForecast = _forecastHistory.first;
    return (latestForecast['investmentAmount'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _loadPortfolioData() async {
    setState(() => _isLoading = true);
    
    // In a real app, this would fetch from backend
    // For now, show empty state
    setState(() {
      _investments = [];
      _performanceData = [];
      _isLoading = false;
    });
  }

  Future<void> _loadForecastHistory() async {
    setState(() => _loadingForecasts = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.accessToken;
    if (token == null) {
      debugPrint('InvestmentPortfolioScreen: No auth token available');
      setState(() {
        _forecastHistory = [];
        _loadingForecasts = false;
      });
      return;
    }
    
    debugPrint('InvestmentPortfolioScreen: Loading forecast history');
    debugPrint('InvestmentPortfolioScreen: Auth token available: ${token.isNotEmpty}');
    
    try {
      final forecasts = await ForecastStorageService().getInvestmentReports();
      debugPrint('InvestmentPortfolioScreen: Loaded ${forecasts.length} forecasts');
      
      // Debug: Print first forecast structure if available
      if (forecasts.isNotEmpty) {
        debugPrint('InvestmentPortfolioScreen: First forecast keys: ${forecasts.first.keys.toList()}');
        debugPrint('InvestmentPortfolioScreen: First forecast symbol: ${forecasts.first['symbol']}');
        debugPrint('InvestmentPortfolioScreen: First forecast amount: ${forecasts.first['investmentAmount']}');
        debugPrint('InvestmentPortfolioScreen: First forecast generatedAt: ${forecasts.first['generatedAt']}');
      }
      
      setState(() {
        _forecastHistory = forecasts;
        _expandedForecastIndex = forecasts.isNotEmpty ? 0 : -1; // Expand the most recent forecast
        _loadingForecasts = false;
        // Set the most recent forecast as expanded by default
        _expandedForecastIndex = forecasts.isNotEmpty ? 0 : -1;
      });
      
      debugPrint('InvestmentPortfolioScreen: State updated with ${_forecastHistory.length} forecasts');
    } catch (e) {
      debugPrint('InvestmentPortfolioScreen: Error loading forecasts: $e');
      setState(() {
        _forecastHistory = [];
        _loadingForecasts = false;
      });
    }
  }

  // Get the most recent investment amount for portfolio balance
  double get _mostRecentInvestmentAmount {
    if (_forecastHistory.isEmpty) return 0.0;
    final latestForecast = _forecastHistory.first;
    // Extract investment amount from the new structure
    return (latestForecast['investmentAmount'] as num?)?.toDouble() ?? 0.0;
  }

  double get _totalValue => _totalPortfolioValue;
  double get _totalReturn => _investments.fold(0, (sum, inv) => sum + (inv['amount'] * inv['return'] / 100));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Holdings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Forecasts',
            onPressed: _loadForecastHistory,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Reports',
            onPressed: () async {
              debugPrint('InvestmentPortfolioScreen: Manual debug trigger');
              debugPrint('InvestmentPortfolioScreen: Current forecast count: ${_forecastHistory.length}');
              debugPrint('InvestmentPortfolioScreen: Local reports count: ${ForecastStorageService().localReportsCount}');
              
              // Force reload
              await _loadForecastHistory();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Debug: ${_forecastHistory.length} reports loaded'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading && _loadingForecasts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPortfolioHeader(),
                  const SizedBox(height: 24),
                  _buildForecastFilterBar(),
                  const SizedBox(height: 16),
                  _buildForecastHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildForecastFilterBar() {
    // For now, just show a static filter bar like the screenshot
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterChip('All', true, Color(0xFFB8D4F0), Color(0xFF2E5A88)),
        _buildFilterChip('Recent', false, Color(0xFFF0E68C), Color(0xFF8B7355)),
        _buildFilterChip('Old', false, Color(0xFFE8E8E8), Color(0xFF6B6B6B)),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? fg : bg, width: 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: fg,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPortfolioHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE8F4FD),
            Color(0xFFF0F8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Color(0xFF2E5A88), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Value',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Color(0xFF2E5A88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${_totalValue.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5A88),
                  ),
                ),
                if (_forecastHistory.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Investment: \$${_totalInvestmentAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF5A7A9A),
                    ),
                  ),
                ],
                if (_forecastHistory.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Based on latest forecast',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF5A7A9A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_forecastHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFB8D4F0).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.trending_up,
                color: Color(0xFF2E5A88),
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Performance',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: ['1M', '3M', '6M', '1Y', '5Y']
                    .map((period) => DropdownMenuItem(value: period, child: Text(period)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5000,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < _performanceData.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _performanceData[value.toInt()]['date'].substring(5),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5000,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '\$${(value / 1000).toInt()}K',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (_performanceData.length - 1).toDouble(),
                minY: 20000,
                maxY: 30000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _performanceData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['value'].toDouble());
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor.withOpacity(0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).cardColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetAllocation() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Allocation',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _investments.map((investment) {
                  return PieChartSectionData(
                    value: investment['allocation'],
                    title: '${investment['allocation'].toStringAsFixed(0)}%',
                    color: investment['color'],
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Holdings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._investments.map((investment) => _buildInvestmentItem(investment)),
      ],
    );
  }

  Widget _buildInvestmentItem(Map<String, dynamic> investment) {
    final isPositive = investment['return'] >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: investment['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up,
              color: investment['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  investment['symbol'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${investment['allocation'].toStringAsFixed(1)}% of portfolio',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${investment['amount'].toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${investment['return'].toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastHistorySection() {
    if (_loadingForecasts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_forecastHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No forecasts yet. Try forecasting your investments!',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Create a sample report for testing
                final sampleReport = {
                  'symbol': 'AAPL',
                  'type': 'Stocks',
                  'investmentAmount': 5000.0,
                  'duration': 5,
                  'riskLevel': 'Medium',
                  'historicalData': {'symbol': 'AAPL', 'data': []},
                  'metrics': {
                    'totalReturn': 15.5,
                    'volatility': 12.3,
                    'currentPrice': 175.0,
                    'dataPoints': 12,
                  },
                  'insights': [
                    'Sample analysis based on 5 years of historical data.',
                    'The investment has shown positive growth over the analyzed period.',
                    'Moderate volatility suggests stable but variable performance.',
                  ],
                  'generatedAt': DateTime.now().toIso8601String(),
                  'reportType': 'investment_history',
                };
                
                final success = await ForecastStorageService().storeInvestmentReport(sampleReport);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sample report created! Refresh to see it.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadForecastHistory();
                }
              },
              child: Text('Create Sample Report (Test)'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast Holdings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5A88),
          ),
        ),
        const SizedBox(height: 16),
        ..._forecastHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final forecast = entry.value;
          return _buildForecastCard(forecast, index);
        }).toList(),
      ],
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> entry, int index) {
    String dateStr = 'Unknown date';
    try {
      dateStr = DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.parse(entry['generatedAt']));
    } catch (_) {}
    
    final insights = entry['insights'] as List<dynamic>? ?? [];
    final highlights = insights.whereType<String>().toList();
    final isExpanded = index == _expandedForecastIndex;
    final isMostRecent = index == 0;
    
    // Get investment amount from the new structure
    final investmentAmount = (entry['investmentAmount'] as num?)?.toDouble() ?? 0.0;
    
    final bgColors = [
      Color(0xFFE8F4FD), // Soft pastel blue
      Color(0xFFF0F8FF), // Alice blue
      Color(0xFFF5F5DC), // Beige
      Color(0xFFF0FFF0), // Honeydew
      Color(0xFFFFF0F5), // Lavender blush
      Color(0xFFF0F8FF), // Light cyan
      Color(0xFFFFFACD), // Lemon chiffon
      Color(0xFFE6E6FA), // Lavender
      Color(0xFFFDF5E6), // Old lace
      Color(0xFFF0FFFF), // Azure
    ];
    final colorIdx = DateTime.parse(entry['generatedAt']).millisecondsSinceEpoch % bgColors.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColors[colorIdx],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMostRecent ? Color(0xFFB8D4F0) : Colors.transparent,
          width: isMostRecent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _expandedForecastIndex = index;
            });
          }
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMostRecent ? Color(0xFFB8D4F0) : Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isMostRecent ? Icons.star : Icons.analytics,
            color: isMostRecent ? Color(0xFF2E5A88) : Color(0xFF6B6B6B),
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E5A88),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isMostRecent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFB8D4F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Latest',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5A88),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${investmentAmount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5A88),
              ),
            ),
          ],
        ),
        subtitle: highlights.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  highlights.first,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.indigo[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        children: [
          _buildExpandedForecastContent(entry),
        ],
      ),
    );
  }

  Widget _buildExpandedForecastContent(Map<String, dynamic> entry) {
    final insights = entry['insights'] as List<dynamic>? ?? [];
    final highlights = insights.whereType<String>().toList();
    final investmentAmount = (entry['investmentAmount'] as num?)?.toDouble() ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Investment Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem('Amount', '\$${investmentAmount.toStringAsFixed(0)}', Icons.account_balance_wallet),
                  ),
                  Expanded(
                    child: _buildSummaryItem('Risk Level', entry['riskLevel']?.toString() ?? 'N/A', Icons.shield),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // AI Insights
        if (highlights.isNotEmpty) ...[
          Text(
            'AI-Generated Insights',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          const SizedBox(height: 8),
          ...highlights.map((h) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    h,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.amber[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 16),
        ],
        
        // Risk Analysis
                        if (entry['metrics'] != null) ...[
          Text(
            'Risk Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
                              'Volatility: ${entry['metrics']['volatility']?.toStringAsFixed(2)}%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.red[900],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // User Input Details
        Text(
          'Forecast Parameters',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50]!.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.entries.where((e) => e.key != 'historicalData' && e.key != 'metrics' && e.key != 'insights').map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${e.key}: ${e.value}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.indigo[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.indigo[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
      ],
    );
  }
} 