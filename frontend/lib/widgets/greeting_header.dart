import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';

class GreetingHeader extends StatelessWidget {
  final DashboardSummary? summary;
  final String? userName;

  const GreetingHeader({
    super.key,
    this.summary,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName?.split(' ').first ?? 'User';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B2B6B), Color(0xFF06D6A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B2B6B).withOpacity(0.25),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGreetingIcon(),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getGreetingMessage(firstName),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (summary != null) ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Net Worth',
                    value: '\$${summary!.netWorth.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                    context: context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Monthly Spending',
                    value: '\$${summary!.monthlySpending.toStringAsFixed(0)}',
                    icon: Icons.trending_down,
                    color: Colors.orange,
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Savings Rate',
                    value: '${summary!.savingsRate.toStringAsFixed(1)}%',
                    icon: Icons.savings,
                    color: Colors.blue,
                    context: context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Credit Score',
                    value: summary!.creditScore.toString(),
                    icon: Icons.credit_score,
                    color: const Color(0xFF6B2B6B),
                    context: context,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AI Finance Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getAISummary(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGreetingMessage(String firstName) {
    final now = DateTime.now();
    final hour = now.hour;
    
    // More detailed time-based greetings
    if (hour >= 5 && hour < 12) {
      return 'Good morning, $firstName! ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $firstName! 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $firstName! 🌅';
    } else {
      return 'Good night, $firstName! 🌙';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    
    // More detailed time-based icons
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny;
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_sunny_outlined;
    } else if (hour >= 17 && hour < 21) {
      return Icons.wb_cloudy;
    } else {
      return Icons.nightlight_round;
    }
  }

  String _getAISummary() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Time-based AI summaries
    if (hour >= 5 && hour < 12) {
      return 'Good morning! Your financial health is looking great. Consider reviewing your daily budget to start the day on the right track.';
    } else if (hour >= 12 && hour < 17) {
      return 'Your finances are in good shape! This is a great time to check your spending patterns and make any necessary adjustments.';
    } else if (hour >= 17 && hour < 21) {
      return 'Great job managing your finances today! Consider reviewing your expenses and planning for tomorrow.';
    } else {
      return 'Your financial health is excellent! Take a moment to reflect on your spending and plan for a successful tomorrow.';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final BuildContext context;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 