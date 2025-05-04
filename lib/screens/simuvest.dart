import 'package:flutter/material.dart';

class SimuVestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SimuVest')),
      body: Center(
        child: Text(
          'SimuVest simulation UI goes here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
