import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/squad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/bottom_nav_bar.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final squadProvider = Provider.of<SquadProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        squadProvider.loadSquads(authProvider.user!.uid);
      }
    });
  }