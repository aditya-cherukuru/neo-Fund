class InvestmentModel {
  final String id;
  final String userId;
  final String assetType;
  final double amount;
  final double currentValue;
  final String scenario;
  final DateTime createdAt;
  final bool isSimulation;
  
  InvestmentModel({
    required this.id,
    required this.userId,
    required this.assetType,
    required this.amount,
    required this.currentValue,
    required this.scenario,
    required this.createdAt,
    this.isSimulation = true,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'assetType': assetType,
      'amount': amount,
      'currentValue': currentValue,
      'scenario': scenario,
      'createdAt': createdAt.toIso8601String(),
      'isSimulation': isSimulation,
    };
  }
  
  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      assetType: map['assetType'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currentValue: (map['currentValue'] ?? 0).toDouble(),
      scenario: map['scenario'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isSimulation: map['isSimulation'] ?? true,
    );
  }
}
