import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/copy_future_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/investment_card.dart';

class CopyFutureScreen extends StatefulWidget {
  const CopyFutureScreen({super.key});

  @override
  State<CopyFutureScreen> createState() => _CopyFutureScreenState();
}

class _CopyFutureScreenState extends State<CopyFutureScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Top Performers', 'Recent', 'Similar Risk'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CopyFutureProvider>(context, listen: false).loadTopInvestments();
    });
  }