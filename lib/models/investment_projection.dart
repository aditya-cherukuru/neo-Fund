class InvestmentProjection {
  final double initialAmount;
  final String pathName;
  final List<TimeProjection> projections;
  final double potentialReturn; // Percentage
  final double confidence; // AI confidence 0-1

  InvestmentProjection({
    required this.initialAmount,
    required this.pathName,
    required this.projections,
    required this.potentialReturn,
    required this.confidence,
  });
}

class TimeProjection {
  final int months;
  final double projectedAmount;
  final List<AssetPerformance> assetPerformance;

  TimeProjection({
    required this.months,
    required this.projectedAmount,
    required this.assetPerformance,
  });
}

class AssetPerformance {
  final String assetName;
  final double initialValue;
  final double projectedValue;
  final double growth; // Percentage
  final List<HistoricalPoint> historicalData;

  AssetPerformance({
    required this.assetName,
    required this.initialValue,
    required this.projectedValue,
    required this.growth,
    required this.historicalData,
  });
}

class HistoricalPoint {
  final DateTime date;
  final double value;

  HistoricalPoint({required this.date, required this.value});
}
