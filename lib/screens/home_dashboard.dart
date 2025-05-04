import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _selectedIndex = 0;

  final List<String> _routes = [
    '/',
    '/invest',
    '/simuvest',
    '/squad',
    '/profile',
  ];

  void _onItemTapped(int index) {
    if (index != 0) {
      Navigator.pushNamed(context, _routes[index]);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Home Dashboard UI here', style: TextStyle(fontSize: 22)),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
