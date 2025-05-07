// lib/widgets/time_selector.dart
import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final List<int> selectedTimeframes;
  final Function(List<int>) onChanged;
  final List<int> availableTimeframes;

  const TimeSelector({
    Key? key,
    required this.selectedTimeframes,
    required this.onChanged,
    required this.availableTimeframes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Horizon (Months)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTimeframes.map((months) {
            final isSelected = selectedTimeframes.contains(months);
            
            return GestureDetector(
              onTap: () {
                List<int> newSelection = List.from(selectedTimeframes);
                
                if (isSelected) {
                  newSelection.remove(months);
                } else {
                  newSelection.add(months);
                }
                
                if (newSelection.isNotEmpty) {
                  onChanged(newSelection);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  months == 1 ? '1 Month' : '$months Months',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}