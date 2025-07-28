import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/http_client.dart';

class TodaysAITipWidget extends StatefulWidget {
  const TodaysAITipWidget({
    super.key,
  });

  @override
  State<TodaysAITipWidget> createState() => _TodaysAITipWidgetState();
}

class _TodaysAITipWidgetState extends State<TodaysAITipWidget> {
  String _currentTip = "Loading AI tip...";
  bool _isLoading = false;
  final AIService _aiService = AIService();
  final HttpClient _httpClient = HttpClient();

  // Fallback tips when AI service is unavailable
  final List<String> _fallbackTips = [
    "Start with a budget - track every expense for 30 days to understand your spending patterns.",
    "Build an emergency fund - aim for 3-6 months of living expenses in a high-yield savings account.",
    "Pay yourself first - automate savings transfers before you see your paycheck.",
    "Diversify your investments - don't put all your eggs in one basket.",
    "Review your subscriptions monthly - cancel services you don't use regularly.",
    "Use credit cards wisely - pay off the full balance each month to avoid interest.",
    "Invest in your future - contribute to retirement accounts early and consistently.",
    "Track your net worth - monitor your assets minus liabilities monthly.",
    "Live below your means - spend less than you earn to build wealth over time.",
    "Educate yourself - read financial books and stay informed about money management.",
    "Set specific financial goals - make them measurable and time-bound.",
    "Automate your finances - set up automatic bill payments and savings transfers.",
  ];

  @override
  void initState() {
    super.initState();
    _loadAITip();
  }

  Future<void> _loadAITip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, test if backend is available
      final isBackendAvailable = await _testBackendConnection();
      
      if (!isBackendAvailable) {
        // Use fallback tip if backend is not available
        _setRandomFallbackTip();
        return;
      }

      // Get current timestamp to ensure fresh responses
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Create a diverse set of prompts for variety
      final List<String> prompts = [
        "Give me one current market trend tip for 2024. Focus on specific investment opportunities, emerging sectors, or market conditions. Keep it under 100 characters and actionable.",
        "What's one hot financial trend right now that people should know about? Mention specific opportunities or sectors. Keep it under 100 characters.",
        "Share one current investment opportunity or market insight for 2024. Be specific about sectors, technologies, or strategies. Keep it under 100 characters.",
        "What's one emerging financial trend or opportunity in today's market? Focus on current events, technologies, or market shifts. Keep it under 100 characters.",
        "Give me one actionable financial tip based on current market conditions in 2024. Mention specific opportunities or strategies. Keep it under 100 characters.",
        "What's one current market opportunity that investors should consider? Focus on specific sectors, technologies, or market conditions. Keep it under 100 characters.",
        "Share one current financial trend or investment insight for 2024. Be specific about opportunities, sectors, or market dynamics. Keep it under 100 characters.",
        "What's one emerging opportunity in today's financial markets? Focus on current trends, technologies, or market shifts. Keep it under 100 characters.",
        "What's one current AI or tech investment opportunity in 2024? Mention specific companies or sectors. Keep it under 100 characters.",
        "Give me one tip about current crypto or digital asset trends. Focus on practical opportunities. Keep it under 100 characters.",
        "What's one current ESG or sustainable investment trend? Mention specific opportunities. Keep it under 100 characters.",
        "Share one current real estate or property investment insight for 2024. Keep it under 100 characters.",
      ];
      
      // Select a random prompt to ensure variety
      final randomPrompt = prompts[timestamp % prompts.length];
      
      // Get current financial trends tip
      final tip = await _aiService.getAIResponse(randomPrompt);
      
      // Clean up the response - take first sentence and limit length
      final cleanTip = tip
          .split(RegExp(r'[.!?]'))
          .first
          .trim();
      
      final finalTip = cleanTip.length > 100 
          ? '${cleanTip.substring(0, 97)}...'
          : cleanTip;
      
      setState(() {
        _currentTip = finalTip;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AI Tip Error: $e');
      // Use fallback tip on error
      _setRandomFallbackTip();
    }
  }

  Future<bool> _testBackendConnection() async {
    try {
      final response = await _httpClient.get('/health');
      return response != null;
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }

  void _setRandomFallbackTip() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomIndex = timestamp % _fallbackTips.length;
    setState(() {
      _currentTip = _fallbackTips[randomIndex];
      _isLoading = false;
    });
  }

  void _refreshTip() {
    if (!_isLoading) {
      _loadAITip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // AI Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Today\'s AI Tip',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentTip,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Refresh button
              IconButton(
                onPressed: _isLoading ? null : _refreshTip,
                icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      size: 20,
                    ),
                tooltip: 'Get new tip',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 