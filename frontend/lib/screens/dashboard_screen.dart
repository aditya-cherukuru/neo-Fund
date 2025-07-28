import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'dart:async';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../widgets/greeting_header.dart';
import '../widgets/net_worth_summary.dart';
import '../widgets/spending_chart.dart';
import '../widgets/smart_suggestions.dart';
import '../widgets/recent_transactions_preview.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/financial_tools_section.dart';
import '../widgets/tool_card.dart';
import '../widgets/todays_ai_tip_widget.dart';
import '../widgets/budget_overview_card.dart';
import '../widgets/custom_app_bar.dart';
import 'investment_forecast_screen.dart';
import 'investment_portfolio_screen.dart';
import 'investment_advisor_screen.dart';
import 'voice_qa_screen.dart';
import 'investment_history_insights_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_settings_screen.dart';
import '../providers.dart';
import '../services/forecast_storage_service.dart';
import '../services/forecast_notification_service.dart';
import '../models/forecast_entry.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Container(), // Home (handled above)
    InvestmentAdvisorScreen(),
    Container(), // Voice Q&A (handled by FAB)
    InvestmentForecastScreen(), // Forecast
    InvestmentPortfolioScreen(), // My Holdings
  ];

  void _onNavBarTap(int index) {
    if (index == 2) {
      // Center FAB: Voice Q&A
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VoiceQAScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  bool _isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  void _toggleTheme() {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  @override
  void initState() {
    super.initState();
    // Wait for auth service to be fully initialized before fetching dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh forecast data when dependencies change (e.g., when returning from other screens)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedIndex == 0) {
        // Refresh the dashboard data to get latest forecasts
        context.read<DashboardService>().refresh();
      }
    });
  }

  Future<void> _initializeDashboard() async {
    try {
      // Wait for auth service to be fully initialized
      final authService = context.read<AuthService>();
      
      // Wait up to 2 seconds for auth service to be ready
      int attempts = 0;
      while (!authService.isInitialized && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      // Check if user is still authenticated after waiting
      if (authService.isAuthenticated) {
        debugPrint('Dashboard: Auth service ready, fetching dashboard data');
        await context.read<DashboardService>().fetchDashboardData();
      } else {
        debugPrint('Dashboard: User not authenticated, redirecting to login');
        // User might have been logged out during initialization
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Dashboard: Error during initialization: $e');
      // If there's an error, still try to fetch dashboard data
      if (mounted) {
        await context.read<DashboardService>().fetchDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'NEOFUND',
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode(context) ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Light/Dark Mode',
          ),
          _buildProfileAvatar(),
        ],
      ),
      body: _selectedIndex == 0
          ? Consumer<DashboardService>(
              builder: (context, dashboardService, child) {
                return RefreshIndicator(
                  onRefresh: () => dashboardService.refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                      child: Column(
                        children: [
                          // 1. User Greeting Section with Daily Investment Tip
                          _buildGreetingSection(dashboardService),
                          const SizedBox(height: 20),
                          
                          // 2. Trending Investment Types / Market Highlights
                          _buildTrendingInvestmentsSection(),
                          const SizedBox(height: 20),
                          
                          // 3. Most Recent Forecast
                          _RecentForecastInsight(
                            onRefresh: () {
                              // Trigger a refresh of the dashboard data
                              dashboardService.refresh();
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // 4. Personalized AI Suggestions (Expandable)
                          _buildPersonalizedAISuggestions(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : _pages[_selectedIndex] ?? Container(),
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VoiceQAScreen()),
            );
          },
          backgroundColor: Theme.of(context).brightness == Brightness.light 
            ? AppTheme.lightModePurple  // Deep purple for light mode
            : const Color(0xFF06D6A0), // Original seagreen for dark mode
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          child: const Icon(Icons.mic, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home, 'Home', 0),
              _buildNavBarItem(Icons.psychology, 'Advisor', 1),
              const SizedBox(width: 56), // Space for FAB
              _buildNavBarItem(Icons.trending_up, 'Forecast', 3),
              _buildNavBarItem(Icons.pie_chart, 'My Holdings', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavBarTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected 
              ? (Theme.of(context).brightness == Brightness.light 
                  ? AppTheme.lightModePurple  // Deep purple for light mode
                  : const Color(0xFF06D6A0)) // Original seagreen for dark mode
              : (Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[600]  // Dark gray for light mode
                  : Colors.white54),  // Original for dark mode
            size: 28,
          ),
          const SizedBox(height: 4),
                      Text(
              label,
              style: TextStyle(
                color: isSelected 
                  ? (Theme.of(context).brightness == Brightness.light 
                      ? AppTheme.lightModePurple  // Deep purple for light mode
                      : const Color(0xFF06D6A0)) // Original seagreen for dark mode
                  : (Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]  // Dark gray for light mode
                      : Colors.white54),  // Original for dark mode
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  // 1. User Greeting Section with Daily Investment Tip
  Widget _buildGreetingSection(DashboardService dashboardService) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final userName = user != null 
        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
        : 'User';
    final firstName = userName.split(' ').first;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B2B6B), Color(0xFF06D6A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B2B6B).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Icon(
                _getGreetingIcon(),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getGreetingMessage(firstName),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Daily Investment Tip
          _DailyInvestmentTipWidget(),
        ],
      ),
    );
  }

  // 2. Trending Investment Types Section
  Widget _buildTrendingInvestmentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Now',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9B59B6), // More vibrant purple
            ),
          ),
          const SizedBox(height: 12),
          _TrendingInvestmentsWidget(),
        ],
      ),
    );
  }

  // 4. Personalized AI Suggestions (Expandable)
  Widget _buildPersonalizedAISuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Suggestions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF9B59B6), // More vibrant purple
            ),
          ),
          const SizedBox(height: 12),
          _AISuggestionsWidget(),
        ],
      ),
    );
  }

  // Helper methods
  String _getGreetingMessage(String firstName) {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good morning, $firstName! ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $firstName! 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $firstName! 🌅';
    } else {
      return 'Good night, $firstName! 🌙';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny;
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_sunny_outlined;
    } else if (hour >= 17 && hour < 21) {
      return Icons.wb_cloudy;
    } else {
      return Icons.nightlight_round;
    }
  }



  Widget _buildProfileAvatar() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final profilePictureData = user?['profilePicture'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: _buildProfileImageWidget(profilePictureData),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageWidget(String? profilePictureData) {
    if (profilePictureData != null && profilePictureData.isNotEmpty) {
      // Check if it's a base64 data URL
      if (profilePictureData.startsWith('data:image/')) {
        try {
          // Extract base64 data from data URL
          final base64Data = profilePictureData.split(',')[1];
          final imageBytes = base64Decode(base64Data);
          
          return Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading base64 image: $error');
              return Icon(
                Icons.person,
                size: 20,
                color: Theme.of(context).primaryColor,
              );
            },
          );
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
          return Icon(
            Icons.person,
            size: 20,
            color: Theme.of(context).primaryColor,
          );
        }
      } else {
        // Legacy file path support (fallback)
        return Image.network(
          'http://localhost:3000/$profilePictureData',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 20,
              color: Theme.of(context).primaryColor,
            );
          },
        );
      }
    } else {
      // No profile picture - show default icon
      return Icon(
        Icons.person,
        size: 20,
        color: Theme.of(context).primaryColor,
      );
    }
  }
}

class _TrendingInvestmentsWidget extends StatefulWidget {
  @override
  State<_TrendingInvestmentsWidget> createState() => _TrendingInvestmentsWidgetState();
}

class _TrendingInvestmentsWidgetState extends State<_TrendingInvestmentsWidget> {
  List<Map<String, dynamic>> _trendingInvestments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingInvestments();
  }

  Future<void> _loadTrendingInvestments() async {
    setState(() => _isLoading = true);
    
    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final investments = await aiService.getTrendingInvestments(buildContext: context);
      
      setState(() {
        _trendingInvestments = investments.map((investment) {
          return {
            'name': investment['name'] ?? 'Investment',
            'description': investment['description'] ?? 'Investment opportunity',
            'returns': investment['returns'] ?? '+0.0%',
            'risk': investment['risk'] ?? 'Medium',
            'icon': _getInvestmentIcon(investment['category'] ?? 'general'),
            'color': _getInvestmentColor(investment['category'] ?? 'general'),
            'symbol': investment['symbol'] ?? '',
            'trend_reason': investment['trend_reason'] ?? '',
            'recommendation': investment['recommendation'] ?? 'watch',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading trending investments: $e');
      setState(() {
        _isLoading = false;
        _trendingInvestments = []; // Empty list instead of hardcoded data
      });
    }
  }

  IconData _getInvestmentIcon(String category) {
    switch (category.toLowerCase()) {
      case 'stocks':
      case 'equity':
        return Icons.trending_up;
      case 'etf':
      case 'funds':
        return Icons.analytics;
      case 'bonds':
      case 'fixed_income':
        return Icons.account_balance;
      case 'crypto':
      case 'cryptocurrency':
        return Icons.currency_bitcoin;
      case 'real_estate':
      case 'reits':
        return Icons.home;
      case 'commodities':
        return Icons.inventory;
      default:
        return Icons.trending_up;
    }
  }

  Color _getInvestmentColor(String category) {
    switch (category.toLowerCase()) {
      case 'stocks':
      case 'equity':
        return const Color(0xFF2ECC71); // Green
      case 'etf':
      case 'funds':
        return const Color(0xFF3498DB); // Blue
      case 'bonds':
      case 'fixed_income':
        return const Color(0xFF9B59B6); // Purple
      case 'crypto':
      case 'cryptocurrency':
        return const Color(0xFFE67E22); // Orange
      case 'real_estate':
      case 'reits':
        return const Color(0xFFE74C3C); // Red
      case 'commodities':
        return const Color(0xFFF39C12); // Yellow
      default:
        return const Color(0xFF2ECC71); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            width: 140,
            margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_trendingInvestments.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: GestureDetector(
            onTap: _loadTrendingInvestments,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to retry loading trending investments',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trendingInvestments.length,
        itemBuilder: (context, index) {
          final investment = _trendingInvestments[index];
          return Container(
            width: 130,
            margin: EdgeInsets.only(right: index < _trendingInvestments.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light 
                ? (investment['color'] as Color).withOpacity(0.15)
                : (investment['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                  ? (investment['color'] as Color).withOpacity(0.4)
                  : (investment['color'] as Color).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                          ? (investment['color'] as Color).withOpacity(0.3)
                          : (investment['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        investment['icon'] as IconData,
                        color: investment['color'] as Color,
                        size: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                          ? (investment['color'] as Color).withOpacity(0.3)
                          : (investment['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        investment['risk'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: investment['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  investment['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light 
                      ? Colors.grey[800]  // Dark gray for light mode
                      : Colors.white,     // White for dark mode
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  investment['description'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Theme.of(context).brightness == Brightness.light 
                      ? Colors.grey[600]  // Medium gray for light mode
                      : Colors.white70,   // Light white for dark mode
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  investment['returns'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: investment['color'] as Color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentForecastInsight extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const _RecentForecastInsight({this.onRefresh});
  
  @override
  State<_RecentForecastInsight> createState() => _RecentForecastInsightState();
}

class _RecentForecastInsightState extends State<_RecentForecastInsight> {
  Map<String, dynamic>? _latestForecast;
  bool _loading = true;
  StreamSubscription? _forecastSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchLatestForecast();
    _setupForecastListener();
  }

  void _setupForecastListener() {
    _forecastSubscription?.cancel();
    _forecastSubscription = ForecastNotificationService().forecastStream.listen((data) {
      if (mounted) {
        _fetchLatestForecast();
      }
    });
  }

  @override
  void dispose() {
    _forecastSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestForecast() async {
    setState(() => _loading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.accessToken;
    if (token == null) {
      setState(() {
        _latestForecast = null;
        _loading = false;
      });
      return;
    }
    debugPrint('DashboardScreen: Loading latest forecast');
    final forecasts = await ForecastStorageService().getInvestmentReports();
    debugPrint('DashboardScreen: Found ${forecasts.length} forecasts');
    
    setState(() {
      _latestForecast = forecasts.isNotEmpty ? forecasts.first : null;
      _loading = false;
    });
    
    // Notify parent widget that refresh is complete
    widget.onRefresh?.call();
  }

  // Get the most recent investment amount
  double get _mostRecentInvestmentAmount {
    if (_latestForecast == null) return 0.0;
    return (_latestForecast!['investmentAmount'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.purple[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue[200]!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_latestForecast == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.purple[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue[200]!.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.insights, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No recent investment forecast. Try forecasting your investments!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
        ),
      );
    }
    final insights = _latestForecast!['insights'] as List<dynamic>? ?? [];
    final highlights = insights.whereType<String>().toList();
    final dateStr = DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.parse(_latestForecast!['generatedAt']));
    final investmentAmount = _mostRecentInvestmentAmount;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, const Color(0xFF6B2B6B).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue[200]!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[200]!.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.insights, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Investment Forecast',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    if (investmentAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹${investmentAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[200]!,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Latest',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (highlights.isNotEmpty) ...[
            Text(
              'AI-Generated Insights',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            ...highlights.take(3).map((h) => Container(
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
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvestmentPortfolioScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[100]!,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'View Full Portfolio',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'No insights available',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.blue[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpandableSuggestionWidget extends StatefulWidget {
  final String title;
  final String shortDesc;
  final String fullDesc;
  final IconData icon;
  final Color color;

  const _ExpandableSuggestionWidget({
    required this.title,
    required this.shortDesc,
    required this.fullDesc,
    required this.icon,
    required this.color,
  });

  @override
  State<_ExpandableSuggestionWidget> createState() => _ExpandableSuggestionWidgetState();
}

class _DailyInvestmentTipWidget extends StatefulWidget {
  @override
  State<_DailyInvestmentTipWidget> createState() => _DailyInvestmentTipWidgetState();
}

class _DailyInvestmentTipWidgetState extends State<_DailyInvestmentTipWidget> {
  Map<String, dynamic>? _dailyTip;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDailyTip();
  }

  Future<void> _loadDailyTip() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final tip = await aiService.getDailyInvestmentTip(buildContext: context);
      
      setState(() {
        _dailyTip = tip;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading daily tip: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Investment Tip",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLoading)
                  Text(
                    "Loading AI tip...",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  )
                else if (_error.isNotEmpty)
                  GestureDetector(
                    onTap: _loadDailyTip,
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Tap to retry loading AI tip",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    _dailyTip?['content'] ?? "Loading AI investment tip...",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AISuggestionsWidget extends StatefulWidget {
  @override
  State<_AISuggestionsWidget> createState() => _AISuggestionsWidgetState();
}

class _AISuggestionsWidgetState extends State<_AISuggestionsWidget> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAISuggestions();
  }

  Future<void> _loadAISuggestions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final suggestions = await aiService.getInvestmentTips(buildContext: context);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading AI suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        children: List.generate(3, (index) => Container(
          margin: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        )),
      );
    }

    if (_error.isNotEmpty || _suggestions.isEmpty) {
      // Show retry option instead of hardcoded fallback
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: GestureDetector(
              onTap: _loadAISuggestions,
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap to retry loading AI suggestions',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: _suggestions.take(3).map((suggestion) {
        return Container(
          margin: EdgeInsets.only(bottom: _suggestions.indexOf(suggestion) < 2 ? 8 : 0),
          child: _ExpandableSuggestionWidget(
            title: suggestion['title'] ?? 'Investment Tip',
            shortDesc: suggestion['description'] ?? 'Investment advice',
            fullDesc: suggestion['description'] ?? 'Consider this investment strategy for better returns.',
            icon: _getSuggestionIcon(suggestion['category'] ?? 'general'),
            color: _getSuggestionColor(suggestion['category'] ?? 'general'),
          ),
        );
      }).toList(),
    );
  }

  IconData _getSuggestionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency_fund':
      case 'savings':
        return Icons.savings;
      case 'diversification':
      case 'portfolio':
        return Icons.pie_chart;
      case 'budget':
      case 'spending':
        return Icons.receipt;
      case 'investment':
      case 'stocks':
        return Icons.trending_up;
      case 'debt':
      case 'credit':
        return Icons.credit_card;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getSuggestionColor(String category) {
    switch (category.toLowerCase()) {
      case 'emergency_fund':
      case 'savings':
        return const Color(0xFF2ECC71); // Green
      case 'diversification':
      case 'portfolio':
        return const Color(0xFF3498DB); // Blue
      case 'budget':
      case 'spending':
        return const Color(0xFFE67E22); // Orange
      case 'investment':
      case 'stocks':
        return const Color(0xFF9B59B6); // Purple
      case 'debt':
      case 'credit':
        return const Color(0xFFE74C3C); // Red
      default:
        return const Color(0xFFF39C12); // Yellow
    }
  }
}

class _ExpandableSuggestionWidgetState extends State<_ExpandableSuggestionWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[800]  // Dark gray for light mode
                              : Colors.white,     // White for dark mode
                          ),
                        ),
                        Text(
                          widget.shortDesc,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey[600]  // Medium gray for light mode
                              : Colors.white70,   // Light white for dark mode
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: widget.color.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.fullDesc,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.grey[800]  // Dark gray for light mode
                    : Colors.white,     // White for dark mode
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}