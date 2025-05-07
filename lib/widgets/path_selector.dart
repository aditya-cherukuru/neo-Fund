// lib/widgets/path_selector.dart
import 'package:flutter/material.dart';
import '../models/investment_path.dart';

class PathSelector extends StatelessWidget {
  final List<InvestmentPath> paths;
  final List<String> selectedPathIds;
  final Function(String) onToggleSelection;

  const PathSelector({
    Key? key,
    required this.paths,
    required this.selectedPathIds,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Investment Paths',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            itemBuilder: (context, index) {
              final path = paths[index];
              final isSelected = selectedPathIds.contains(path.name);
              
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: () => onToggleSelection(path.name),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                path.iconPath,
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    _getIconForPath(path.name),
                                    color: Theme.of(context).primaryColor,
                                  );
                                },
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            path.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Risk: ${_getRiskText(path.riskScore)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getRiskText(double riskScore) {
    if (riskScore < 3) return 'Low';
    if (riskScore < 7) return 'Medium';
    return 'High';
  }

  IconData _getIconForPath(String pathName) {
    switch (pathName.toLowerCase()) {
      case 'tech':
        return Icons.computer;
      case 'green':
      case 'esg':
        return Icons.eco;
      case 'meme':
        return Icons.trending_up;
      case 'risk':
      case 'aggressive':
        return Icons.speed;
      case 'conservative':
      case 'balanced':
        return Icons.account_balance;
      default:
        return Icons.show_chart;
    }
  }
}