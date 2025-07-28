class Investment {
  final String? id;
  final String name;
  final String type;
  final double amount;
  final String? platform;
  final DateTime purchaseDate;
  final double? expectedReturn;
  final String? riskLevel;
  final double? currentValue;
  final double? profitLoss;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Investment({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.platform,
    required this.purchaseDate,
    this.expectedReturn,
    this.riskLevel,
    this.currentValue,
    this.profitLoss,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      type: json['type'],
      amount: (json['amount'] ?? 0).toDouble(),
      platform: json['platform'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      expectedReturn: json['expectedReturn']?.toDouble(),
      riskLevel: json['riskLevel'],
      currentValue: json['currentValue']?.toDouble(),
      profitLoss: json['profitLoss']?.toDouble(),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      if (platform != null) 'platform': platform,
      'purchaseDate': purchaseDate.toIso8601String(),
      if (expectedReturn != null) 'expectedReturn': expectedReturn,
      if (riskLevel != null) 'riskLevel': riskLevel,
      if (currentValue != null) 'currentValue': currentValue,
      if (profitLoss != null) 'profitLoss': profitLoss,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Investment copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? platform,
    DateTime? purchaseDate,
    double? expectedReturn,
    String? riskLevel,
    double? currentValue,
    double? profitLoss,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      platform: platform ?? this.platform,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      riskLevel: riskLevel ?? this.riskLevel,
      currentValue: currentValue ?? this.currentValue,
      profitLoss: profitLoss ?? this.profitLoss,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Investment(id: $id, name: $name, type: $type, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Investment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 