import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../main.dart'; // Import to access environmentVariables
import '../services/ai_service.dart'; // Import AIService

class VoiceQAScreen extends StatefulWidget {
  const VoiceQAScreen({super.key});

  @override
  State<VoiceQAScreen> createState() => _VoiceQAScreenState();
}

/// Custom widget for animated text typing effect
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 50),
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}

class _VoiceQAScreenState extends State<VoiceQAScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isLoadingAI = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;
  bool _isBotTyping = false;
  bool _isVoiceMessage = false; // Track if current message is from voice
  String _currentQuestion = '';
  String _aiResponse = '';
  String? _aiError;
  
  // Speech to text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  
  // AI Service
  final AIService _aiService = AIService();
  
  // Animations
  late AnimationController _messageAnimationController;
  late AnimationController _micAnimationController;
  late AnimationController _typingAnimationController;
  late Animation<double> _messageSlideAnimation;
  late Animation<double> _messageFadeAnimation;
  late Animation<double> _micScaleAnimation;
  
  List<Map<String, dynamic>> _conversationHistory = [];
  final List<Map<String, String>> _chatHistory = [];
  List<Map<String, dynamic>> _voiceCommands = [];
  List<Map<String, dynamic>> _quickQuestions = [];
  List<Map<String, String>> _recentQA = [];
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadVoiceData();
    _initializeTTS();
    _initializeSpeechToText();
    _loadRecentQA();
    _initializeAnimations();
    _textController.addListener(() {
      setState(() {
        // This will trigger a rebuild when text changes
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _messageAnimationController.dispose();
    _micAnimationController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceData() async {
    setState(() {
      _voiceCommands = [
        {
          'command': 'What is my current balance?',
          'description': 'Check your account balance',
          'icon': Icons.account_balance,
          'color': Colors.blue,
        },
        {
          'command': 'How much did I spend this month?',
          'description': 'Get monthly spending summary',
          'icon': Icons.receipt_long,
          'color': Colors.red,
        },
        {
          'command': 'What is my credit score?',
          'description': 'Check your credit health',
          'icon': Icons.credit_score,
          'color': Colors.green,
        },
        {
          'command': 'Show my budget status',
          'description': 'Get budget overview',
          'icon': Icons.account_balance_wallet,
          'color': Colors.orange,
        },
        {
          'command': 'What are my investment returns?',
          'description': 'Check portfolio performance',
          'icon': Icons.trending_up,
          'color': const Color(0xFF6B2B6B),
        },
        {
          'command': 'Set a reminder for bill payment',
          'description': 'Create financial reminder',
          'icon': Icons.notifications,
          'color': Colors.teal,
        },
      ];

      _quickQuestions = [
        {
          'question': 'How do I start investing?',
          'category': 'Investment',
          'icon': Icons.trending_up,
          'color': Colors.green,
        },
        {
          'question': 'What is a good credit score?',
          'category': 'Credit',
          'icon': Icons.credit_score,
          'color': Colors.blue,
        },
        {
          'question': 'How much should I save?',
          'category': 'Savings',
          'icon': Icons.savings,
          'color': Colors.orange,
        },
        {
          'question': 'What is compound interest?',
          'category': 'Education',
          'icon': Icons.school,
          'color': const Color(0xFF6B2B6B),
        },
      ];

      _conversationHistory = [
        {
          'type': 'user',
          'message': 'What is my current balance?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'isVoice': true,
        },
        {
          'type': 'ai',
          'message': 'Your current balance across all accounts is \$12,450. Your checking account has \$3,200, savings has \$8,500, and investment account has \$750.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          'isVoice': false,
        },
        {
          'type': 'user',
          'message': 'How much did I spend on food this month?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          'isVoice': true,
        },
        {
          'type': 'ai',
          'message': 'You\'ve spent \$450 on food and dining this month, which is 15% of your total spending. This is within your budget of \$500.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
          'isVoice': false,
        },
      ];
    });
  }

  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slower rate for clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set up completion callback
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
      
      // Set up error callback
      _flutterTts.setErrorHandler((msg) {
        setState(() {
          _isSpeaking = false;
        });
        debugPrint('TTS Error: $msg');
      });
      
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _initializeSpeechToText() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      debugPrint('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
    }
  }

  Future<void> _loadRecentQA() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentQAJson = prefs.getStringList('recent_qa') ?? [];
      setState(() {
        _recentQA = recentQAJson.map((json) {
          final data = jsonDecode(json);
          return {
            'question': data['question'] as String,
            'answer': data['answer'] as String,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent Q&A: $e');
    }
  }

  Future<void> _saveRecentQA(String question, String answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newQA = {
        'question': question,
        'answer': answer,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _recentQA.insert(0, {
        'question': question,
        'answer': answer,
      });
      
      // Keep only last 3 Q&A
      if (_recentQA.length > 3) {
        _recentQA = _recentQA.take(3).toList();
      }
      
      final recentQAJson = _recentQA.map((qa) => jsonEncode(qa)).toList();
      await prefs.setStringList('recent_qa', recentQAJson);
    } catch (e) {
      debugPrint('Error saving recent Q&A: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      debugPrint('Speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
      _currentQuestion = 'Listening... (Tap to stop)';
    });
    
    _micAnimationController.repeat();
    
    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _currentQuestion = result.recognizedWords;
          });
          
          if (result.finalResult) {
            _stopListening();
            if (_currentQuestion.trim().isNotEmpty) {
              _processQuestion(_currentQuestion);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
    });
    
    _micAnimationController.stop();
    _micAnimationController.reset();
    
    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  Future<void> _processQuestion(String question) async {
    if (question.trim().isEmpty) return;

    // Stop any existing TTS before processing new question
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    setState(() {
      _isProcessing = true;
      _isLoadingAI = true;
      _aiError = null;
      _isVoiceMessage = _isListening; // Set voice flag based on current input method
    });

    // Add user question to history
    _conversationHistory.add({
      'type': 'user',
      'message': question,
      'timestamp': DateTime.now(),
      'isVoice': _isListening,
    });

    // Add user message to chat history
    _chatHistory.add({
      'role': 'user',
      'message': question,
    });

    // Trigger message animation
    _messageAnimationController.forward();

    // Scroll to bottom to show new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Use the AIService for better financial responses
      final aiResponse = await _aiService.getAIResponse(question);
      
      setState(() {
        _aiResponse = aiResponse;
        _conversationHistory.add({
          'type': 'ai',
          'message': aiResponse,
          'timestamp': DateTime.now(),
          'isVoice': false,
        });
        // Add AI response to chat history
        _chatHistory.add({
          'role': 'assistant',
          'message': aiResponse,
        });
        _currentQuestion = '';
        _isLoadingAI = false;
      });

      // Save to recent Q&A
      await _saveRecentQA(question, aiResponse);

      // Speak the AI response ONLY if it was a voice message
      if (_isVoiceMessage && _ttsEnabled && aiResponse.isNotEmpty) {
        await _speakResponse(aiResponse);
      }

      // Scroll to bottom to show AI response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } catch (e) {
      setState(() {
        _aiError = e.toString();
        _aiResponse = 'Sorry, I encountered an error processing your question. Please try again or check your connection.';
        _conversationHistory.add({
          'type': 'ai',
          'message': _aiResponse,
          'timestamp': DateTime.now(),
          'isVoice': false,
        });
        // Add error response to chat history
        _chatHistory.add({
          'role': 'assistant',
          'message': _aiResponse,
        });
        _isLoadingAI = false;
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _isVoiceMessage = false; // Reset voice flag
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    try {
      await _flutterTts.speak(text);
      setState(() {
        _isSpeaking = true;
      });
    } catch (e) {
      debugPrint('Error speaking response: $e');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  void _toggleTTS() {
    setState(() {
      _ttsEnabled = !_ttsEnabled;
    });
  }

  void _clearChat() {
    setState(() {
      _chatHistory.clear();
    });
  }

  /// Handle text input messages with real Groq AI integration
  Future<void> _handleTextMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to chat history
    setState(() {
      _chatHistory.add({
        'role': 'user',
        'message': message,
      });
      _isVoiceMessage = false; // Ensure text messages don't trigger voice
    });

    // Trigger message animation
    _messageAnimationController.forward();

    // Scroll to bottom to show user message
    _scrollToBottom();

    // Show typing indicator
    setState(() {
      _isBotTyping = true;
    });

    // Scroll to show typing indicator
    _scrollToBottom();

    // Fetch real AI response from AIService
    String aiResponse = await _aiService.getAIResponse(message);

    // Hide typing indicator
    setState(() {
      _isBotTyping = false;
    });

    // Add AI response to chat history
    setState(() {
      _chatHistory.add({
        'role': 'assistant',
        'message': aiResponse,
      });
    });

    // Save to recent Q&A
    await _saveRecentQA(message, aiResponse);

    // Scroll to show AI response
    _scrollToBottom();

    // Don't speak text responses - only voice responses should be spoken
  }

  /// Generate fake responses for demo purposes
  String _generateFakeResponse(String question) {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('balance') || lowerQuestion.contains('account')) {
      return 'Your current balance across all accounts is \$12,450. Your checking account has \$3,200, savings has \$8,500, and investment account has \$750.';
    } else if (lowerQuestion.contains('spend') || lowerQuestion.contains('expense')) {
      return 'You\'ve spent \$2,850 this month. Your top spending categories are: Food (\$450), Transportation (\$380), and Entertainment (\$320).';
    } else if (lowerQuestion.contains('credit') || lowerQuestion.contains('score')) {
      return 'Your current credit score is 750, which is considered good. You\'ve improved by 15 points this month. Keep up the good work!';
    } else if (lowerQuestion.contains('budget') || lowerQuestion.contains('budgeting')) {
      return 'You\'re currently at 71% of your monthly budget. You have \$1,150 remaining. You\'re on track to stay within budget this month.';
    } else if (lowerQuestion.contains('invest') || lowerQuestion.contains('portfolio')) {
      return 'Your investment portfolio is valued at \$15,200. You\'ve earned \$850 this year, a 5.9% return. Your top performing investment is the S&P 500 index fund.';
    } else if (lowerQuestion.contains('save') || lowerQuestion.contains('savings')) {
      return 'You\'ve saved \$1,200 this month, which is 20% of your income. Your emergency fund is fully funded at \$8,500. Great job!';
    } else if (lowerQuestion.contains('remind') || lowerQuestion.contains('bill')) {
      return 'I\'ll set a reminder for your credit card payment due on March 25th. You\'ll receive a notification 3 days before the due date.';
    } else {
      return 'Here\'s a tip: Track your expenses daily to stay on top of your finances! I can help you with budgeting, investing, credit scores, and more.';
    }
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeAnimations() {
    _messageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _messageSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _messageAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _messageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _messageAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _micScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Voice Q&A',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history - takes most of the space
            Expanded(
              child: _buildChatHistory(),
            ),
            // Voice input section at the bottom
            _buildVoiceInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.all(16),
      child: _chatHistory.isEmpty && !_isBotTyping
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ask me anything about your finances',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use voice or text to get financial advice',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Show typing indicator at the end if bot is typing
                if (_isBotTyping && index == _chatHistory.length) {
                  return _buildTypingIndicator();
                }

                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                
                return _buildMessageBubble(message, isUser);
              },
            ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MintMate AI is thinking',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
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

  Widget _buildMessageBubble(Map<String, String> message, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isUser 
                        ? null
                        : Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message['message']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isUser 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUser ? 'You' : 'AI Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voice status indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentQuestion.isEmpty ? 'Listening...' : _currentQuestion,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isListening) const SizedBox(height: 16),
          
          // Input row
          Row(
            children: [
              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        _handleTextMessage(text);
                        _textController.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Send button
              GestureDetector(
                onTap: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    _handleTextMessage(text);
                    _textController.clear();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Voice button
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: AnimatedBuilder(
                  animation: _micAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _micScaleAnimation.value,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.red, Colors.red.shade400]
                                : [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.red : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            _isListening ? 'Tap to stop recording' : 'Tap mic for voice input',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
} 