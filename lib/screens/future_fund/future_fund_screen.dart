import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/future_fund_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/milestone_card.dart';
import '../../widgets/sponsor_card.dart';

class FutureFundScreen extends StatefulWidget {
  const FutureFundScreen({super.key});

  @override
  State<FutureFundScreen> createState() => _FutureFundScreenState();
}

class _FutureFundScreenState extends State<FutureFundScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FutureFundProvider>(context, listen: false).loadMilestones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureFund Me'),
        subtitle: const Text('Get sponsored for your investment journey'),
      ),
      body: Consumer<FutureFundProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Sponsored Amount
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sponsored',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${provider.totalSponsored.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From ${provider.activeSponsorships} active sponsorships',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Active Milestones
                Text(
                  'Active Milestones',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                ...provider.activeMilestones.map((milestone) => 
                  MilestoneCard(
                    milestone: milestone,
                    onClaim: () => _claimMilestone(milestone), 
                  ),
                ),
                const SizedBox(height: 24),

                // Create New Milestone Button 
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateMilestoneDialog(), 
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Milestone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                //Current Sponsors 
                Text(
                  'Your Sponsors',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                if (provider.sponsors.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sponsors yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share your milestones with family and friends to get sponsored',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.sponsors.map((sponsor) => 
                    SponsorCard(sponsor: sponsor),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
