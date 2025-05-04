import 'package:flutter/material.dart';

class SquadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Squad')),
      body: Center(
        child: Text(
          'Squad collaboration UI goes here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
