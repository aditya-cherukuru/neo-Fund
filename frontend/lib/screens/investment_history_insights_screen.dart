import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/investment_forecast_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class InvestmentHistoryInsightsScreen extends StatefulWidget {
  const InvestmentHistoryInsightsScreen({super.key});

  @override
  State<InvestmentHistoryInsightsScreen> createState() => _InvestmentHistoryInsightsScreenState();
}

class _InvestmentHistoryInsightsScreenState extends State<InvestmentHistoryInsightsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _investmentAmountController = TextEditingController();
  final _durationController = TextEditingController();
  final _expectedReturnController = TextEditingController();
  final _symbolController = TextEditingController();
  
  String _selectedRiskAppetite = 'Medium';
  String _selectedInvestmentType = 'Stocks';
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  Map<String, dynamic>? _forecastResult;
  List<Map<String, dynamic>> _symbolSuggestions = [];
  bool _showSuggestions = false;
  FocusNode _symbolFocusNode = FocusNode();
  Timer? _debounceTimer;

  final List<String> _riskAppetites = ['Low', 'Medium', 'High'];
  final List<String> _investmentTypes = ['Stocks', 'Mutual Funds', 'Crypto', 'Bonds', 'ETFs', 'Real Estate'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();
    _investmentAmountController.text = '10000';
    _durationController.text = '5';
    _expectedReturnController.text = '8';
    
    _symbolFocusNode.addListener(() {
      if (!_symbolFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _investmentAmountController.dispose();
    _durationController.dispose();
    _expectedReturnController.dispose();
    _symbolController.dispose();
    _symbolFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchSymbols(String query) async {
    if (query.length < 2) {
      setState(() {
        _symbolSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final investmentForecastService = context.read<InvestmentForecastService>();
      final suggestions = await investmentForecastService.searchSymbols(
        query,
        type: _selectedInvestmentType.toLowerCase(),
      );

      setState(() {
        _symbolSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error searching symbols: $e');
    }
  }

  void _selectSymbol(Map<String, dynamic> symbol) {
    setState(() {
      _symbolController.text = symbol['symbol'];
      _showSuggestions = false;
    });
    _symbolFocusNode.unfocus();
  }

  void _onSymbolChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchSymbols(query);
    });
  }

  IconData _getInvestmentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'stock':
      case 'common stock':
        return Icons.trending_up;
      case 'crypto':
      case 'cryptocurrency':
        return Icons.currency_bitcoin;
      case 'etf':
        return Icons.show_chart;
      case 'mutual fund':
        return Icons.account_balance;
      case 'bond':
        return Icons.security;
      default:
        return Icons.attach_money;
    }
  }

  Future<void> _generateForecast() async {
    if (!_formKey.currentState!.validate()) return;

          setState(() {
      _isLoading = true;
    });

    try {
      final investmentForecastService = context.read<InvestmentForecastService>();

      final result = await investmentForecastService.generateForecast(
        investmentAmount: double.parse(_investmentAmountController.text),
        duration: int.parse(_durationController.text),
        riskAppetite: _selectedRiskAppetite,
        investmentType: _selectedInvestmentType,
        expectedReturn: double.parse(_expectedReturnController.text),
        currency: _selectedCurrency,
      );
      
      setState(() {
        _forecastResult = result;
        _isLoading = false;
      });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Forecast generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating forecast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    String? hintText,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (label.contains('Expected')) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                Tooltip(
                  message: 'Expected annual return percentage (optional)',
                  child: Container(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
              borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildForecastResult() {
    if (_forecastResult == null) return const SizedBox.shrink();

    final forecast = _forecastResult!['forecast'] as Map<String, dynamic>;
    final insights = _forecastResult!['insights'] as List<dynamic>;
    final yearWiseGrowth = _forecastResult!['yearWiseGrowth'] as List<dynamic>;
    final riskAnalysis = _forecastResult!['riskAnalysis'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Projected Value Card
                Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                      'Projected Value',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.trending_up, color: Colors.white, size: 28),
                  ],
                      ),
                      const SizedBox(height: 12),
                            Text(
                  '${_selectedCurrency} ${forecast['projectedValue'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                                fontWeight: FontWeight.bold,
                    color: Colors.white,
                              ),
                            ),
                            Text(
                  'After ${_durationController.text} years',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Text(
                          'Initial Investment',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                            ),
                            Text(
                          '${_selectedCurrency} ${_investmentAmountController.text}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                          'Total Growth',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    Text(
                          '${forecast['totalGrowth'].toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade300,
                      ),
                    ),
                  ],
                ),
              ],
                ),
            ],
          ),
        ),

          const SizedBox(height: 24),

          // Growth Chart
        Container(
            padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  'Growth Over Time',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${_selectedCurrency} ${value.toInt()}',
                                style: GoogleFonts.poppins(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < yearWiseGrowth.length) {
                                return Text(
                                  'Year ${value.toInt() + 1}',
                                  style: GoogleFonts.poppins(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: yearWiseGrowth.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['value'].toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue.shade600,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Key Insights
                  Text(
            'Key Insights',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
              ),
              const SizedBox(height: 16),
          ...insights.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                  child: Text(
                    insight,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                    ),
                  ),
                ],
              ),
          )).toList(),
              
          const SizedBox(height: 24),

          // Risk and Reward Analysis
              Container(
            padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  'Risk & Reward Analysis',
                  style: GoogleFonts.poppins(
            fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
          ),
        ),
                const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                      child: _buildRiskMetric(
                        'Risk Level',
                        _selectedRiskAppetite,
                        _getRiskColor(_selectedRiskAppetite),
                        Icons.shield,
                      ),
                    ),
                    const SizedBox(width: 16),
            Expanded(
                      child: _buildRiskMetric(
                'Volatility',
                        '${riskAnalysis['volatility'].toStringAsFixed(1)}%',
                Colors.orange,
                        Icons.trending_up,
              ),
            ),
          ],
        ),
                const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                      child: _buildRiskMetric(
                        'Expected Return',
                        '${riskAnalysis['expectedReturn'].toStringAsFixed(1)}%',
                        Colors.green,
                        Icons.attach_money,
                      ),
                    ),
                    const SizedBox(width: 16),
            Expanded(
                      child: _buildRiskMetric(
                        'Risk-Reward Ratio',
                        riskAnalysis['riskRewardRatio'].toStringAsFixed(2),
                        Colors.purple,
                        Icons.balance,
              ),
            ),
          ],
        ),
              ],
            ),
          ),

        const SizedBox(height: 24),

          // Year-wise Summary
        Container(
            padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                  'Year-wise Growth Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...yearWiseGrowth.asMap().entries.map((entry) {
                  final year = entry.key + 1;
                  final data = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
              Text(
                          'Year $year',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_selectedCurrency} ${data['value'].toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '${data['growth'].toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Disclaimer: This forecast is for educational purposes only. Past performance does not guarantee future results. Always consult with a financial advisor before making investment decisions.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                        ),
                      ),
                    ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildRiskMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSymbolInputField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Investment Symbol (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              Tooltip(
                message: 'Search for specific stocks, crypto, or ETFs to get more accurate forecasts',
                child: Container(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _symbolController,
              focusNode: _symbolFocusNode,
              onChanged: _onSymbolChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter symbol (e.g., AAPL, TSLA, BTC)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _symbolController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          setState(() {
                            _symbolController.clear();
                            _symbolSuggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_showSuggestions && _symbolSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _symbolSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _symbolSuggestions[index];
                  return ListTile(
                    leading: Icon(
                      _getInvestmentTypeIcon(suggestion['type'] ?? 'stock'),
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    title: Text(
                      suggestion['symbol'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      suggestion['name'] ?? suggestion['symbol'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: suggestion['exchange'] != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              suggestion['exchange'],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _selectSymbol(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Investment Forecast',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Colors.white),
            onPressed: _forecastResult != null ? () {
              // TODO: Implement PDF export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF export coming soon!')),
              );
            } : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              // Header
        Text(
                'AI-Powered Investment Forecast',
                style: GoogleFonts.poppins(
                  fontSize: 24,
            fontWeight: FontWeight.bold,
                  color: Colors.white,
          ),
        ),
              const SizedBox(height: 8),
        Text(
                'Get personalized investment forecasts based on your preferences and market analysis',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              _buildInputField(
                label: 'Investment Amount',
                icon: Icons.attach_money,
                controller: _investmentAmountController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter investment amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                hintText: 'Enter amount',
                keyboardType: TextInputType.number,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _selectedCurrency,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              _buildInputField(
                label: 'Duration (years)',
                icon: Icons.access_time,
                controller: _durationController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0 || duration > 30) {
                    return 'Please enter a valid duration (1-30 years)';
                  }
                  return null;
                },
                hintText: 'Enter years (1-30)',
                keyboardType: TextInputType.number,
              ),

              _buildDropdownField(
                label: 'Risk Appetite',
                icon: Icons.shield,
                value: _selectedRiskAppetite,
                items: _riskAppetites,
                onChanged: (value) {
                  setState(() {
                    _selectedRiskAppetite = value!;
                  });
                },
              ),

              _buildDropdownField(
                label: 'Investment Type',
                icon: Icons.show_chart,
                value: _selectedInvestmentType,
                items: _investmentTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedInvestmentType = value!;
                  });
                },
              ),

              _buildSymbolInputField(),

              _buildInputField(
                label: 'Expected Annual Return',
                icon: Icons.trending_up,
                controller: _expectedReturnController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Optional field
                  }
                  final returnRate = double.tryParse(value);
                  if (returnRate == null || returnRate < 0 || returnRate > 100) {
                    return 'Please enter a valid percentage (0-100)';
                  }
                  return null;
                },
                hintText: 'Enter percentage (optional)',
                keyboardType: TextInputType.number,
                suffixIcon: Padding(
      padding: const EdgeInsets.all(16),
                  child: Text(
                    '%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              _buildDropdownField(
                label: 'Currency',
                icon: Icons.currency_exchange,
                value: _selectedCurrency,
                items: _currencies,
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Generate Forecast Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateForecast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
        children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Generating Forecast...',
                              style: GoogleFonts.poppins(
              fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Generate AI Forecast',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Forecast Result
              _buildForecastResult(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement voice Q&A
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice Q&A coming soon!')),
          );
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
} 