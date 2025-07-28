import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/user_service.dart';
import 'services/investment_service.dart';
import 'services/investment_forecast_service.dart';
import 'services/ai_service.dart';
import 'services/forecast_notification_service.dart';
import 'services/http_client.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'providers.dart';

// Simple environment variables map
final Map<String, String> environmentVariables = {
  'GROQ_API_KEY': '',
  'GROQ_MODEL': 'meta-llama/llama-4-scout-17b-16e-instruct',
  'BACKEND_URL': 'http://localhost:3000/api',
};

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Load environment variables from .env file
    if (kIsWeb) {
      await dotenv.load(fileName: ".env");
    } else {
      await dotenv.load(fileName: ".env");
    }
    // Populate environment variables map
    environmentVariables.addAll({
      'GROQ_API_KEY': dotenv.env['GROQ_API_KEY'] ?? '',
      'GROQ_MODEL': dotenv.env['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct',
      'BACKEND_URL': dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api',
    });
    debugPrint('MintMate: Environment variables loaded successfully');
    debugPrint('MintMate: GROQ_API_KEY loaded: ${environmentVariables['GROQ_API_KEY']?.isNotEmpty == true ? 'Yes' : 'No'}');
    debugPrint('MintMate: GROQ_API_KEY length: ${environmentVariables['GROQ_API_KEY']?.length ?? 0}');
    debugPrint('MintMate: GROQ_MODEL: ${environmentVariables['GROQ_MODEL']}');
    debugPrint('MintMate: Flutter binding initialized');
    debugPrint('MintMate: Environment - Web: $kIsWeb, Debug: $kDebugMode');
    // Initialize SharedPreferences for web before running the app
    if (kIsWeb) {
      debugPrint('MintMate: Initializing SharedPreferences for web');
      await SharedPreferences.getInstance();
      debugPrint('MintMate: SharedPreferences initialized for web');
      
      if (kDebugMode) {
        debugPrint('MintMate: Running in DEVELOPMENT mode');
        debugPrint('MintMate: Note: Use production build for persistent session testing');
      } else {
        debugPrint('MintMate: Running in PRODUCTION mode');
        debugPrint('MintMate: SharedPreferences will persist across browser sessions');
      }
    }
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('MintMate: Error during initialization: $e');
    debugPrint('MintMate: Stack trace: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error initializing app',
                style: GoogleFonts.poppins(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Stack trace:',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                stackTrace.toString(),
                style: GoogleFonts.poppins(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<DashboardService>(create: (_) => DashboardService()),
        ChangeNotifierProvider<UserService>(create: (_) => UserService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<InvestmentService>(create: (_) => InvestmentService()),
        ChangeNotifierProvider<InvestmentForecastService>(create: (_) => InvestmentForecastService()),
        ChangeNotifierProvider<AIService>(create: (_) => AIService()),
        ChangeNotifierProvider<ForecastNotificationService>(create: (_) => ForecastNotificationService()),
        Provider<HttpClient>(create: (_) => HttpClient()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MintMate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  String? _initializationError;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('MintMate: Starting app initialization');
      final authService = context.read<AuthService>();
      debugPrint('MintMate: Waiting for AuthService initialization...');
      while (!authService.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        debugPrint('MintMate: AuthService still initializing...');
      }
      debugPrint('MintMate: AuthService initialized successfully');
      debugPrint('MintMate: Session info: ${authService.getSessionInfo()}');
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('MintMate: App initialization completed');
      // Check onboarding flag
      final prefs = await SharedPreferences.getInstance();
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('MintMate: Error during app initialization: $e');
      setState(() {
        _isInitializing = false;
        _initializationError = e.toString();
      });
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() {
      _onboardingComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        debugPrint('AuthWrapper: Rebuilding with auth state - isAuthenticated: ${authService.isAuthenticated}');
        debugPrint('AuthWrapper: Current session info: ${authService.getSessionInfo()}');
        if (_isInitializing) {
          return _buildInitializationScreen();
        }
        if (_initializationError != null) {
          return _buildErrorScreen();
        }
        if (authService.isLoading) {
          return _buildLoadingScreen();
        }
        
        // Check if onboarding is complete first
        if (!_onboardingComplete) {
          debugPrint('AuthWrapper: Showing onboarding screen');
          return WelcomeScreen(
            key: const ValueKey('onboarding'),
            onGetStarted: () {
              _completeOnboarding();
            },
          );
        }
        
        // After onboarding, check authentication
        if (authService.isAuthenticated) {
          debugPrint('AuthWrapper: User is authenticated, routing to dashboard');
          debugPrint('AuthWrapper: Session info: ${authService.getSessionInfo()}');
          return const DashboardScreen();
        } else {
          debugPrint('AuthWrapper: User not authenticated, routing to login');
          debugPrint('AuthWrapper: Session info: ${authService.getSessionInfo()}');
          return const SignInScreen();
        }
      },
    );
  }

  Widget _buildInitializationScreen() {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Initialization Error',
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _initializationError ?? 'Unknown error',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 