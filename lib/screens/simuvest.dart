// lib/screens/simuvest.dart
import 'package:flutter/material.dart';
import '../services/simulation_service.dart';
import '../widgets/projection_chart.dart';

class SimuVestScreen extends StatefulWidget {
  const SimuVestScreen({Key? key}) : super(key: key);

  @override
  State<SimuVestScreen> createState() => _SimuVestScreenState();
}

class _SimuVestScreenState extends State<SimuVestScreen> {
  String selectedTheme = SimulationService.themes.first;
  final double amount = 10.0;
  late Map<int, Map<String, double>> projection;

  @override
  void initState() {
    super.initState();
    projection = SimulationService.simulate(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SimuVest")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedTheme,
              items: SimulationService.themes
                  .map((theme) => DropdownMenuItem(
                        value: theme,
                        child: Text(theme),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedTheme = val!;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ProjectionChart(
                data: projection,
                selectedTheme: selectedTheme,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Projected value of ₹10 in $selectedTheme",
              style: Theme.of(context).textTheme.titleMedium,
            )
          ],
        ),
      ),
    );
  }
}
