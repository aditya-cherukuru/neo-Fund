import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Center(
        child: Text(
          'Profile and settings UI goes here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
