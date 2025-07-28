import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/investment_history_service.dart';
import '../services/investment_forecast_service.dart';
import '../services/forecast_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class InvestmentForecastScreen extends StatefulWidget {
  const InvestmentForecastScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentForecastScreen> createState() => _InvestmentForecastScreenState();
}

class _InvestmentForecastScreenState extends State<InvestmentForecastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _investmentAmountController = TextEditingController();
  final _durationController = TextEditingController();
  final _symbolController = TextEditingController();
  
  String _selectedRiskAppetite = 'Medium';
  String _selectedInvestmentType = 'Stocks';
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  List<Map<String, dynamic>> _symbolSuggestions = [];
  bool _showSuggestions = false;
  FocusNode _symbolFocusNode = FocusNode();
  Timer? _debounceTimer;

  final List<String> _riskAppetites = ['Low', 'Medium', 'High'];
  final List<String> _investmentTypes = ['Stocks', 'Bonds', 'Mutual Funds', 'ETFs', 'Crypto', 'Real Estate'];

  @override
  void initState() {
    super.initState();
    
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

    // Always show suggestions for testing
    setState(() {
      _symbolSuggestions = [
        {'symbol': 'AAPL', 'name': 'Apple Inc.', 'type': 'stock', 'exchange': 'NASDAQ'},
        {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'type': 'stock', 'exchange': 'NASDAQ'},
        {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'type': 'stock', 'exchange': 'NASDAQ'},
        {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'type': 'stock', 'exchange': 'NASDAQ'},
        {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'type': 'stock', 'exchange': 'NASDAQ'},
        {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'type': 'stock', 'exchange': 'NASDAQ'},
      ];
      _showSuggestions = true;
    });

    // Try to get real suggestions if backend is available
    try {
      final investmentForecastService = context.read<InvestmentForecastService>();
      final suggestions = await investmentForecastService.searchSymbols(
        query,
        type: _selectedInvestmentType.toLowerCase(),
      );

      print('Found ${suggestions.length} suggestions for query: $query');
      
      if (suggestions.isNotEmpty) {
        setState(() {
          _symbolSuggestions = suggestions;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      print('Error searching symbols: $e - Using fallback suggestions');
    }
  }

  void _selectSymbol(Map<String, dynamic> symbol) {
    print('Selecting symbol: ${symbol['symbol']}');
    
    setState(() {
      _symbolController.text = symbol['symbol'];
      _symbolSuggestions = [];
      _showSuggestions = false;
    });
    
    // Unfocus after a small delay to ensure the text is set
    Future.delayed(Duration(milliseconds: 100), () {
      _symbolFocusNode.unfocus();
    });
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${symbol['symbol']} - ${symbol['name'] ?? symbol['symbol']}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  Future<void> _analyzeInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final investmentForecastService = context.read<InvestmentForecastService>();
      
      // Use the symbol if provided, otherwise use a default symbol
      final symbol = _symbolController.text.isNotEmpty 
          ? _symbolController.text 
          : _getDefaultSymbol(_selectedInvestmentType);

      final result = await investmentForecastService.analyzeInvestmentHistory(
        investmentAmount: double.parse(_investmentAmountController.text),
        duration: int.parse(_durationController.text),
        riskPreference: _selectedRiskAppetite,
        investmentType: _selectedInvestmentType,
        symbol: symbol,
      );
      
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });

      // Store the forecast in portfolio
      await _storeForecastInPortfolio(result, symbol);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Investment analysis completed and saved to portfolio!'),
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
            content: Text('Error analyzing investment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDefaultSymbol(String investmentType) {
    switch (investmentType.toLowerCase()) {
      case 'stocks':
        return 'TSLA';
      case 'crypto':
        return 'BTC';
      case 'bonds':
        return 'TLT';
      case 'etfs':
        return 'SPY';
      case 'mutual funds':
        return 'VTSAX';
      default:
        return 'TSLA';
    }
  }

  Future<void> _storeForecastInPortfolio(Map<String, dynamic> result, String symbol) async {
    try {
      final forecastData = {
        'symbol': symbol.toUpperCase(),
        'type': _selectedInvestmentType,
        'investmentAmount': double.parse(_investmentAmountController.text),
        'duration': int.parse(_durationController.text),
        'riskLevel': _selectedRiskAppetite,
        'historicalData': result['rawData'],
        'metrics': result['rawData']['metrics'],
        'insights': result['insights'],
        'performance': result['performance'],
        'generatedAt': DateTime.now().toIso8601String(),
        'reportType': 'investment_forecast',
      };

      final success = await ForecastStorageService().storeInvestmentReport(forecastData);
      if (success) {
        print('Forecast stored successfully in portfolio');
      } else {
        print('Failed to store forecast in portfolio');
      }
    } catch (e) {
      print('Error storing forecast in portfolio: $e');
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
                  color: const Color.fromARGB(255, 232, 225, 225),
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
            child: TextFormField(
              style: TextStyle(color: Colors.black),
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
              style: TextStyle(color: Colors.black),
              value: value,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: TextStyle(color: Colors.black)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
                'Investment Symbol *',
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
                message: 'Search for specific stocks, crypto, or ETFs to get more accurate analysis',
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
              style: TextStyle(color: Colors.black),
              controller: _symbolController,
              focusNode: _symbolFocusNode,
              onChanged: _onSymbolChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an investment symbol';
                }
                return null;
              },
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
              constraints: BoxConstraints(maxHeight: 200),
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
                physics: ClampingScrollPhysics(),
                itemCount: _symbolSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _symbolSuggestions[index];
                  return ListTile(
                    onTap: () {
                      print('Tapped on symbol: ${suggestion['symbol']}');
                      setState(() {
                        _symbolController.text = suggestion['symbol'];
                        _symbolSuggestions = [];
                        _showSuggestions = false;
                      });
                      _symbolFocusNode.unfocus();
                      
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected: ${suggestion['symbol']} - ${suggestion['name'] ?? suggestion['symbol']}'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
                        color: Colors.black87,
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final performance = _analysisResult!['performance'] as Map<String, dynamic>;
    final insights = _analysisResult!['insights'] as List<dynamic>;
    final rawData = _analysisResult!['rawData'] as Map<String, dynamic>;
    final metrics = rawData['metrics'] as Map<String, dynamic>;

    // Parse performance values
    final initialInvestment = double.parse(performance['Initial Investment'].replaceAll('\$', '').replaceAll(',', ''));
    final finalValue = double.parse(performance['Final Value'].replaceAll('\$', '').replaceAll(',', ''));
    final profitLoss = performance['Profit/Loss'];
    final returnPercentage = double.parse(performance['Return %'].replaceAll('%', ''));
    final volatility = double.parse(performance['Volatility'].replaceAll('%', ''));
    final currentPrice = double.parse(performance['Current Price'].replaceAll('\$', '').replaceAll(',', ''));

    // Calculate loss/gain
    final loss = initialInvestment - finalValue;
    final isLoss = returnPercentage < 0;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "What If You Had Invested" Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What If You Had Invested ${_durationController.text} Years Ago?',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Initial Investment',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '\$${initialInvestment.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoss ? 'Loss' : 'Gain',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            isLoss ? '-\$${loss.toStringAsFixed(0)}' : profitLoss,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLoss ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLoss ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLoss ? Colors.red.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Value',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '\$${finalValue.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isLoss ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Performance Metrics Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
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
                      child: _buildMetricCard(
                        'Total Return',
                        '${returnPercentage.toStringAsFixed(1)}%',
                        isLoss ? Colors.red : Colors.green,
                        'Over ${_durationController.text} years',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Volatility',
                        '${volatility.toStringAsFixed(1)}%',
                        Colors.orange,
                        'Price fluctuation',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Current Price',
                        '\$${currentPrice.toStringAsFixed(2)}',
                        Colors.blue,
                        'Today\'s value',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Starting Price',
                        '\$${metrics['oldestPrice']?.toStringAsFixed(2) ?? '0.00'}',
                        Colors.purple.shade300,
                        '${_durationController.text} years ago',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced Price Journey Chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Journey Over ${_durationController.text} Years',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 50,
                        verticalInterval: 12,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 12,
                            getTitlesWidget: (value, meta) {
                              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              final currentYear = DateTime.now().year;
                              final startYear = currentYear - int.parse(_durationController.text);
                              final monthIndex = (value.toInt() % 12).toInt();
                              final year = startYear + (value.toInt() ~/ 12);
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${months[monthIndex]}/${year.toString().substring(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateChartData(currentPrice, metrics['oldestPrice'] ?? currentPrice),
                          isCurved: true,
                          color: isLoss ? Colors.red : Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: isLoss ? Colors.red : Colors.green,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isLoss ? Colors.red : Colors.green).withOpacity(0.1),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isLoss ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isLoss ? Colors.red : Colors.green).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isLoss ? Colors.red : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_symbolController.text.isNotEmpty ? _symbolController.text.toUpperCase() : _getDefaultSymbol(_selectedInvestmentType)} Price Movement',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isLoss ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Growth/Loss Progression Chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investment Value Progression',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: finalValue * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: finalValue / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Initial', 'Year 1', 'Year 2', 'Year 3', 'Final'];
                              if (value.toInt() < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                      barGroups: _generateBarChartData(initialInvestment, finalValue),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: finalValue / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Concise Key Insights Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ...insights.take(3).map((insight) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Past performance doesn\'t guarantee future results. Educational purposes only.',
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

  Widget _buildMetricCard(String label, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateChartData(double currentPrice, double startPrice) {
    final spots = <FlSpot>[];
    final duration = int.parse(_durationController.text);
    
    // Generate realistic price progression
    double price = startPrice;
    for (int i = 0; i < duration * 12; i++) { // Monthly data points
      spots.add(FlSpot(i.toDouble(), price));
      
      // Add some realistic price movement
      final change = (price * (0.02 - 0.04 * (i / (duration * 12)))); // Decreasing volatility over time
      price += (change * (0.5 - (i % 3) * 0.3)); // Some randomness
      price = price.clamp(startPrice * 0.5, startPrice * 2.0); // Reasonable bounds
    }
    
    // Ensure the last point matches current price
    if (spots.isNotEmpty) {
      spots[spots.length - 1] = FlSpot((duration * 12 - 1).toDouble(), currentPrice);
    }
    
    return spots;
  }

  List<BarChartGroupData> _generateBarChartData(double initialValue, double finalValue) {
    final duration = int.parse(_durationController.text);
    final isLoss = finalValue < initialValue;
    
    List<BarChartGroupData> barGroups = [];
    
    // Initial value
    barGroups.add(BarChartGroupData(
      x: 0,
      barRods: [
        BarChartRodData(
          toY: initialValue,
          color: Colors.blue.shade600,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    ));
    
    // Intermediate years
    for (int i = 1; i < duration; i++) {
      final progress = i / duration;
      final intermediateValue = initialValue + (finalValue - initialValue) * progress;
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: intermediateValue,
            color: isLoss ? Colors.red.shade400 : Colors.green.shade400,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ));
    }
    
    // Final value
    barGroups.add(BarChartGroupData(
      x: duration,
      barRods: [
        BarChartRodData(
          toY: finalValue,
          color: isLoss ? Colors.red.shade600 : Colors.green.shade600,
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    ));
    
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B2B6B),
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
            onPressed: _analysisResult != null ? () {
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
                hintText: 'Enter amount in USD',
                keyboardType: TextInputType.number,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'USD',
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

              const SizedBox(height: 24),

              // Generate Forecast Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _analyzeInvestment,
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
                              'Analyzing Investment...',
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

              // Analysis Result
              _buildAnalysisResult(),
            ],
          ),
        ),
      ),
    );
  }
}