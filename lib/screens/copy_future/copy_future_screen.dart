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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CopyFuture™'),
        subtitle: const Text('Copy successful investment strategies'),
      ),
      body: Consumer<CopyFutureProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                            provider.filterInvestments(filter);
                          },
                          backgroundColor: AppTheme.cardBackground,
                          selectedColor: AppTheme.accentGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Featured Investment
                if (provider.featuredInvestment != null) ...[
                  Text(
                    'Featured Strategy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeaturedCard(provider.featuredInvestment!),
                  const SizedBox(height: 24),
                ],

                // Top Performing Investments
                Text(
                  'Top Performing Strategies',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                ...provider.topInvestments.map((investment) => 
                  InvestmentCard(
                    investment: investment,
                    onCopy: () => _copyInvestment(investment),
                    onViewDetails: () => _viewDetails(investment),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> investment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  investment['userName'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment['userName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${investment['followers']} followers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${investment['return']}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            investment['strategy'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _copyInvestment(investment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryPurple,
                  ),
                  child: const Text('Copy Strategy'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _viewDetails(investment),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyInvestment(Map<String, dynamic> investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Copy Investment Strategy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to copy ${investment['userName']}\'s strategy:'),
            const SizedBox(height: 8),
            Text(
              investment['strategy'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Expected return: +${investment['return']}%'),
            Text('Risk level: ${investment['riskLevel']}'),
            Text('Duration: ${investment['duration']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmCopy(investment);
            },
            child: const Text('Copy Now'),
          ),
        ],
      ),
    );
  }

  void _confirmCopy(Map<String, dynamic> investment) {
    Provider.of<CopyFutureProvider>(context, listen: false)
        .copyInvestment(investment);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully copied ${investment['userName']}\'s strategy!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> investment) {
    // Navigate to detailed view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentDetailsScreen(investment: investment),
      ),
    );
  }
}
