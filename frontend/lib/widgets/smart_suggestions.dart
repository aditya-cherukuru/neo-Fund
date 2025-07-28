import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/http_client.dart';

class SmartSuggestions extends StatefulWidget {
  final int maxItems;
  const SmartSuggestions({super.key, this.maxItems = 3});

  @override
  State<SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends State<SmartSuggestions> {
  final AIService _aiService = AIService();
  final HttpClient _httpClient = HttpClient();
  
  // Updated prompts for different categories
  final List<Map<String, String>> _prompts = [
    {
      'category': 'Personal Finance Strategy',
      'prompt': 'Give me one practical personal finance strategy tip for teenagers and young adults. Focus on building good money habits early. Keep it to one sentence, actionable and specific.',
      'icon': '🎯',
      'color': 'blue'
    },
    {
      'category': 'Financial Health',
      'prompt': 'Give me one tip to improve personal financial health and wellness. Focus on budgeting, saving, or debt management. Keep it to one sentence, practical and actionable.',
      'icon': '💪',
      'color': 'green'
    },
    {
      'category': 'Global Finance',
      'prompt': 'Give me one insight about current global finance conditions or market trends that affects personal finance decisions. Keep it to one sentence, informative and relevant.',
      'icon': '🌍',
      'color': 'orange'
    },
    {
      'category': 'Investment Opportunity',
      'prompt': 'Give me one smart investment opportunity or strategy for young people. Focus on accessible, low-risk options. Keep it to one sentence, practical and educational.',
      'icon': '📈',
      'color': 'purple'
    }
  ];
  
  List<String>? _suggestions;
  bool _isLoading = false;
  String? _error;
  String? _lastFetchedPrompt;

  // Enhanced fallback suggestions
  final List<String> _fallbackSuggestions = [
    "Start tracking your daily expenses to build awareness of your spending habits and identify areas for improvement.",
    "Create an emergency fund with at least 3-6 months of living expenses in a high-yield savings account.",
    "Stay informed about inflation rates and how they affect your purchasing power and long-term financial planning.",
    "Consider starting with index funds for long-term wealth building - they offer diversification and low fees.",
    "Pay yourself first by automating savings transfers before you see your paycheck in your account.",
    "Review your subscription services monthly and cancel any you don't use regularly to reduce recurring expenses.",
    "Use credit cards wisely by paying off the full balance each month to avoid interest charges and build credit.",
    "Set specific, measurable financial goals with deadlines to stay motivated and track your progress.",
    "Diversify your investments across different asset classes to reduce risk and improve potential returns.",
    "Educate yourself about personal finance through books, podcasts, and reliable financial resources.",
    "Live below your means by spending less than you earn to build wealth over time.",
    "Automate your finances with automatic bill payments and savings transfers to avoid late fees and ensure consistency."
  ];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Test if AI service is available
      final isAIAvailable = await _testAIService();
      
      if (!isAIAvailable) {
        // Use fallback suggestions when AI is not available
        _useFallbackSuggestions();
        return;
      }

      // Generate suggestions for each category
      final List<String> allSuggestions = [];
      
      for (int i = 0; i < _prompts.length && i < widget.maxItems; i++) {
        try {
          final aiResponse = await _aiService.getAIResponse(_prompts[i]['prompt']!);
          
          // Clean up the response - take the first sentence
          final cleanResponse = aiResponse
              .split(RegExp(r'[.!?]'))
              .first
              .trim();
          
          if (cleanResponse.isNotEmpty) {
            allSuggestions.add(cleanResponse);
          } else {
            // Add fallback if AI response is empty
            allSuggestions.add(_getFallbackSuggestion(i));
          }
        } catch (e) {
          debugPrint('Error fetching suggestion ${i + 1}: $e');
          // Add a fallback suggestion for this category
          allSuggestions.add(_getFallbackSuggestion(i));
        }
      }
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      if (allSuggestions.isNotEmpty) {
        setState(() {
          _suggestions = allSuggestions;
        });
      } else {
        // If no suggestions were generated, use fallback
        _useFallbackSuggestions();
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      // Use fallback suggestions when AI is unavailable
      if (mounted) {
        _useFallbackSuggestions();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _testAIService() async {
    try {
      // Simple test to see if AI service responds
      await _aiService.getAIResponse("test");
      return true;
    } catch (e) {
      debugPrint('AI Service test failed: $e');
      return false;
    }
  }

  String _getFallbackSuggestion(int index) {
    return _fallbackSuggestions[index < _fallbackSuggestions.length ? index : 0];
  }

  void _useFallbackSuggestions() {
    if (!mounted) return;
    
    // Shuffle fallback suggestions to provide variety
    final shuffledFallbacks = List<String>.from(_fallbackSuggestions);
    shuffledFallbacks.shuffle();
    
    setState(() {
      _suggestions = shuffledFallbacks.take(widget.maxItems).toList();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B2B6B), Color(0xFF06D6A0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B2B6B).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '💡',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalized Smart Suggestions',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _suggestions != null && _suggestions!.isNotEmpty 
                            ? 'AI-powered financial insights tailored for you'
                            : 'Smart financial tips to improve your money management',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  IconButton(
                    onPressed: _isLoading ? null : _fetchSuggestions,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Refresh suggestions',
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (_suggestions != null && _suggestions!.isNotEmpty)
              ..._suggestions!.asMap().entries.map((entry) => _SmartSuggestionCard(
                    suggestion: entry.value,
                    index: entry.key,
                    isLast: entry.key == _suggestions!.length - 1,
                    category: _prompts[entry.key]['category'] ?? '',
                    icon: _prompts[entry.key]['icon'] ?? '💡',
                  )),
          ],
        ),
      ),
    );
  }
}

class _SmartSuggestionCard extends StatelessWidget {
  final String suggestion;
  final int index;
  final bool isLast;
  final String category;
  final String icon;
  const _SmartSuggestionCard({required this.suggestion, required this.index, required this.isLast, required this.category, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorList = [Colors.blue, Colors.green, Colors.orange, const Color(0xFF6B2B6B), Colors.teal];
    final color = colorList[index % colorList.length];
    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B2B6B), Color(0xFF06D6A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B2B6B).withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              suggestion,
              style: GoogleFonts.poppins(
                fontSize: 17, 
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 