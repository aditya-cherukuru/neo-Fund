import 'package:flutter/material.dart';

// Simple test widget to verify auto-suggestion functionality
class AutoSuggestionTest extends StatefulWidget {
  const AutoSuggestionTest({Key? key}) : super(key: key);

  @override
  State<AutoSuggestionTest> createState() => _AutoSuggestionTestState();
}

class _AutoSuggestionTestState extends State<AutoSuggestionTest> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _isLoading = false;

  // Sample suggestions for testing
  final List<String> _popularStocks = [
    'AAPL - Apple Inc.',
    'MSFT - Microsoft Corporation',
    'GOOGL - Alphabet Inc.',
    'AMZN - Amazon.com Inc.',
    'TSLA - Tesla Inc.',
    'META - Meta Platforms Inc.',
    'NVDA - NVIDIA Corporation',
    'BRK.A - Berkshire Hathaway Inc.',
    'JNJ - Johnson & Johnson',
    'V - Visa Inc.',
  ];

  final List<String> _popularCrypto = [
    'BTCUSDT - Bitcoin',
    'ETHUSDT - Ethereum',
    'BNBUSDT - Binance Coin',
    'ADAUSDT - Cardano',
    'SOLUSDT - Solana',
    'DOTUSDT - Polkadot',
    'DOGEUSDT - Dogecoin',
    'AVAXUSDT - Avalanche',
    'MATICUSDT - Polygon',
    'LINKUSDT - Chainlink',
  ];

  void _searchSuggestions(String query) {
    if (query.length < 2) {
      setState(() {
        _suggestions.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final queryLower = query.toLowerCase();
      List<String> results = [];

      // Search in popular stocks
      results.addAll(_popularStocks.where((stock) => 
        stock.toLowerCase().contains(queryLower)
      ));

      // Search in popular crypto
      results.addAll(_popularCrypto.where((crypto) => 
        crypto.toLowerCase().contains(queryLower)
      ));

      setState(() {
        _suggestions = results.take(10).toList();
        _isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() {
              _suggestions.clear();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Suggestion Test'),
      ),
      body: GestureDetector(
        onTap: () {
          if (_suggestions.isNotEmpty) {
            setState(() {
              _suggestions.clear();
            });
          }
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Auto-Suggestion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type "AAPL", "BTC", "TSLA", etc. to see suggestions:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: 'Search Symbols',
                      hintText: 'e.g. AAPL, BTCUSDT, TSLA',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLoading ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ) : null,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && value.length >= 2) {
                        _searchSuggestions(value);
                      } else {
                        setState(() {
                          _suggestions.clear();
                        });
                      }
                    },
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              setState(() {
                                _controller.text = suggestion;
                                _suggestions.clear();
                              });
                            },
                            tileColor: Colors.transparent,
                            hoverColor: Colors.grey.shade100,
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Expected Behavior:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('• Type 2+ characters to see suggestions'),
              const Text('• Suggestions appear in a dropdown below the field'),
              const Text('• Click a suggestion to select it'),
              const Text('• Click outside to close suggestions'),
              const Text('• Loading indicator shows while searching'),
            ],
          ),
        ),
      ),
    );
  }
} 