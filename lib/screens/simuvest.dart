// lib/screens/simuvest.dart
import 'package:flutter/material.dart';
import '../blocs/simuvest_bloc.dart';
import '../models/investment_path.dart';
import '../models/investment_projection.dart';
import '../widgets/path_selector.dart';
import '../widgets/projection_chart.dart';
import '../widgets/investment_amount_slider.dart';
import '../widgets/time_selector.dart';
import '../widgets/comparison_view.dart';

class SimuvestScreen extends StatefulWidget {
  const SimuvestScreen({Key? key}) : super(key: key);

  @override
  _SimuvestScreenState createState() => _SimuvestScreenState();
}

class _SimuvestScreenState extends State<SimuvestScreen> {
  final SimuvestBloc _bloc = SimuvestBloc();
  double _investmentAmount = 10.0; // Starting with ₹10
  List<String> _selectedPathIds = [];
  List<int> _selectedTimeframes = [6, 12, 24]; // 6, 12, 24 months
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupListeners();
  }

  void _loadInitialData() {
    // Sample user profile - in a real app, get this from user data
    final userProfile = {
      'age': 25,
      'risk_tolerance': 'moderate',
      'investment_goals': ['growth', 'learning'],
      'preferred_sectors': ['tech', 'green'],
    };
    
    _bloc.loadInvestmentPaths(userProfile);
  }

  void _setupListeners() {
    _bloc.state.listen((state) {
      setState(() {
        _isLoading = state == SimuvestState.loading;
      });
    });
    
    _bloc.error.listen((errorMsg) {
      setState(() {
        _error = errorMsg;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMsg')),
      );
    });
  }

  void _updateAmount(double amount) {
    setState(() {
      _investmentAmount = amount;
    });
    
    if (_selectedPathIds.isNotEmpty) {
      _bloc.getProjectionsForAmount(_investmentAmount, _selectedPathIds, _selectedTimeframes);
    }
  }

  void _togglePathSelection(String pathId) {
    setState(() {
      if (_selectedPathIds.contains(pathId)) {
        _selectedPathIds.remove(pathId);
      } else {
        _selectedPathIds.add(pathId);
      }
    });
    
    if (_selectedPathIds.isNotEmpty) {
      _bloc.getProjectionsForAmount(_investmentAmount, _selectedPathIds, _selectedTimeframes);
    }
  }

  void _updateTimeframes(List<int> timeframes) {
    setState(() {
      _selectedTimeframes = timeframes;
    });
    
    if (_selectedPathIds.isNotEmpty) {
      _bloc.getProjectionsForAmount(_investmentAmount, _selectedPathIds, _selectedTimeframes);
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimuVest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See Your ₹${_investmentAmount.toStringAsFixed(0)} in the Future',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          
          // Amount slider
          InvestmentAmountSlider(
            currentAmount: _investmentAmount,
            onChanged: _updateAmount,
            min: 1.0,
            max: 10000.0,
          ),
          
          const SizedBox(height: 20),
          
          // Timeframe selector
          TimeSelector(
            selectedTimeframes: _selectedTimeframes,
            onChanged: _updateTimeframes,
            availableTimeframes: const [3, 6, 12, 24, 36, 60],
          ),
          
          const SizedBox(height: 20),
          
          // Investment paths
          StreamBuilder<List<InvestmentPath>>(
            stream: _bloc.paths,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Text('No investment paths available'));
              }
              
              return PathSelector(
                paths: snapshot.data!,
                selectedPathIds: _selectedPathIds,
                onToggleSelection: _togglePathSelection,
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Projections
          Expanded(
            child: StreamBuilder<Map<String, InvestmentProjection>>(
              stream: _bloc.projections,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Select investment paths to see projections'),
                  );
                }
                
                return ProjectionChart(
                  projections: snapshot.data!,
                  timeframes: _selectedTimeframes,
                );
              },
            ),
          ),
          
          // Bottom CTA
          if (_selectedPathIds.length >= 2)
            ElevatedButton(
              onPressed: () => _showComparison(context),
              child: const Text('Compare Selected Paths'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About SimuVest'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'SimuVest uses advanced AI to project how your investments might perform in different scenarios.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Key features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text('• Compare multiple investment paths'),
                Text('• See projections over different time periods'),
                Text('• Understand risk and potential returns'),
                Text('• AI-powered recommendations based on your profile'),
                SizedBox(height: 10),
                Text(
                  'Note: All projections are based on market simulations and historical data. Actual results may vary.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showComparison(BuildContext context) {
    if (_selectedPathIds.length < 2) return;
    
    final pathId1 = _selectedPathIds[0];
    final pathId2 = _selectedPathIds[1];
    
    _bloc.projections.first.then((projections) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComparisonView(
            comparison: _bloc.comparePaths(pathId1, pathId2),
            projection1: projections[pathId1]!,
            projection2: projections[pathId2]!,
            timeframes: _selectedTimeframes,
          ),
        ),
      );
    });
  }
}