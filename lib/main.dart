import 'package:flutter/material.dart';
import 'screens/home_dashboard.dart';
import 'screens/invest.dart';
import 'screens/simuvest.dart';
import 'screens/squad.dart';
import 'screens/profile.dart';

void main() {
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
