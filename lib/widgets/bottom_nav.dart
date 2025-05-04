import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFF2A2A40),
      selectedItemColor: Colors.deepPurpleAccent,
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Invest'),
        BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'SimuVest'),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Squad'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
