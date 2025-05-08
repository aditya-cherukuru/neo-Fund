import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_dashboard.dart';
import 'screens/invest.dart';
import 'screens/simuvest.dart';
import 'screens/squad.dart';
import 'screens/profile.dart';

// Make main async so we can await the dotenv loading
Future<void> main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Run the app after environment variables are loaded
  runApp(SimuVestApp());
}

class SimuVestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimuVest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C2D),
        primaryColor: Colors.deepPurple,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeDashboard(),
        '/invest': (context) => InvestScreen(),
        '/simuvest': (context) => SimuvestScreen(),
        '/squad': (context) => SquadScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}