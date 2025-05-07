// lib/models/investment_path.dart
class InvestmentPath {
  final String name;
  final String description;
  final String iconPath;
  final double riskScore; // 1-10
  final List<AssetAllocation> recommendedAllocation;

  InvestmentPath({
    required this.name,
    required this.description,
    required this.iconPath,
    required this.riskScore,
    required this.recommendedAllocation,
  });
}

class AssetAllocation {
  final String assetName;
  final double percentage;
  final String assetCategory; // stocks, crypto, etc.

  AssetAllocation({
    required this.assetName,
    required this.percentage, 
    required this.assetCategory,
  });
}