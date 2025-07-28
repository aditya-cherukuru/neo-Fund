import 'package:flutter/material.dart';

class FinancialToolsSection extends StatelessWidget {
  final List<Widget> tools;

  const FinancialToolsSection({
    super.key,
    required this.tools,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          return tools[index];
        },
      ),
    );
  }
} 