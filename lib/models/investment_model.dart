import 'package:flutter/material.dart';

enum AssetType {
  crypto,
  stocks,
  etf,
  bonds,
  nft,
  realEstate,
  commodities,
  forex,
  mutualFunds,
  greenBonds,
  education,
  startup,
  other
}

enum InvestmentStatus {
  active,
  completed,
  cancelled,
  pending,
  failed
}

enum RiskLevel {
  low,
  medium,
  high,
  veryHigh
}

class InvestmentModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final AssetType assetType;
  final double amount;
  final double currentValue;
  final double initialValue;
  final double returns;
  final double returnPercentage;
  final RiskLevel riskLevel;
  final InvestmentStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int durationDays;
  final Map<String, dynamic> simulationData;
  final List<Map<String, dynamic>> priceHistory;
  final Map<String, dynamic> aiPredictions;
  final List<String> tags;
  final bool isSimulation;
  final String? copiedFromId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  InvestmentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.assetType,
    required this.amount,
    required this.currentValue,
    required this.initialValue,
    required this.returns,
    required this.returnPercentage,
    required this.riskLevel,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.durationDays,
    required this.simulationData,
    required this.priceHistory,
    required this.aiPredictions,
    required this.tags,
    required this.isSimulation,
    this.copiedFromId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'assetType': assetType.name,
      'amount': amount,
      'currentValue': currentValue,
      'initialValue': initialValue,
      'returns': returns,
      'returnPercentage': returnPercentage,
      'riskLevel': riskLevel.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'durationDays': durationDays,
      'simulationData': simulationData,
      'priceHistory': priceHistory,
      'aiPredictions': aiPredictions,
      'tags': tags,
      'isSimulation': isSimulation,
      'copiedFromId': copiedFromId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      assetType: AssetType.values.firstWhere(
        (e) => e.name == map['assetType'],
        orElse: () => AssetType.other,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      currentValue: (map['currentValue'] ?? 0).toDouble(),
      initialValue: (map['initialValue'] ?? 0).toDouble(),
      returns: (map['returns'] ?? 0).toDouble(),
      returnPercentage: (map['returnPercentage'] ?? 0).toDouble(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.medium,
      ),
      status: InvestmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvestmentStatus.pending,
      ),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      durationDays: map['durationDays'] ?? 0,
      simulationData: Map<String, dynamic>.from(map['simulationData'] ?? {}),
      priceHistory: List<Map<String, dynamic>>.from(map['priceHistory'] ?? []),
      aiPredictions: Map<String, dynamic>.from(map['aiPredictions'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      isSimulation: map['isSimulation'] ?? true,
      copiedFromId: map['copiedFromId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
  
  InvestmentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    AssetType? assetType,
    double? amount,
    double? currentValue,
    double? initialValue,
    double? returns,
    double? returnPercentage,
    RiskLevel? riskLevel,
    InvestmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    Map<String, dynamic>? simulationData,
    List<Map<String, dynamic>>? priceHistory,
    Map<String, dynamic>? aiPredictions,
    List<String>? tags,
    bool? isSimulation,
    String? copiedFromId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      assetType: assetType ?? this.assetType,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      initialValue: initialValue ?? this.initialValue,
      returns: returns ?? this.returns,
      returnPercentage: returnPercentage ?? this.returnPercentage,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      simulationData: simulationData ?? this.simulationData,
      priceHistory: priceHistory ?? this.priceHistory,
      aiPredictions: aiPredictions ?? this.aiPredictions,
      tags: tags ?? this.tags,
      isSimulation: isSimulation ?? this.isSimulation,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper methods
  bool get isProfitable => returns > 0;
  bool get isActive => status == InvestmentStatus.active;
  bool get isCompleted => status == InvestmentStatus.completed;
  int get daysElapsed => DateTime.now().difference(startDate).inDays;
  double get dailyReturn => durationDays > 0 ? returnPercentage / durationDays : 0;
  
  // Create a new simulation investment
  factory InvestmentModel.createSimulation({
    required String userId,
    required String name,
    required String description,
    required AssetType assetType,
    required double amount,
    required RiskLevel riskLevel,
    List<String> tags = const [],
    Map<String, dynamic> simulationData = const {},
  }) {
    final now = DateTime.now();
    return InvestmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      description: description,
      assetType: assetType,
      amount: amount,
      currentValue: amount,
      initialValue: amount,
      returns: 0,
      returnPercentage: 0,
      riskLevel: riskLevel,
      status: InvestmentStatus.active,
      startDate: now,
      durationDays: 0,
      simulationData: simulationData,
      priceHistory: [
        {
          'date': now.toIso8601String(),
          'value': amount,
          'change': 0,
          'changePercentage': 0,
        }
      ],
      aiPredictions: {},
      tags: tags,
      isSimulation: true,
      metadata: {
        'createdVia': 'simulation',
        'aiGenerated': false,
        'userNotes': '',
      },
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Create a copy investment
  factory InvestmentModel.createCopy({
    required String userId,
    required InvestmentModel original,
    required double amount,
  }) {
    final now = DateTime.now();
    return InvestmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: 'Copy: ${original.name}',
      description: original.description,
      assetType: original.assetType,
      amount: amount,
      currentValue: amount,
      initialValue: amount,
      returns: 0,
      returnPercentage: 0,
      riskLevel: original.riskLevel,
      status: InvestmentStatus.active,
      startDate: now,
      durationDays: 0,
      simulationData: original.simulationData,
      priceHistory: [
        {
          'date': now.toIso8601String(),
          'value': amount,
          'change': 0,
          'changePercentage': 0,
        }
      ],
      aiPredictions: original.aiPredictions,
      tags: original.tags,
      isSimulation: true,
      copiedFromId: original.id,
      metadata: {
        'createdVia': 'copy',
        'originalInvestment': original.id,
        'originalUser': original.userId,
        'copiedAt': now.toIso8601String(),
      },
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Update investment with new value
  InvestmentModel updateValue(double newValue) {
    final newReturns = newValue - initialValue;
    final newReturnPercentage = initialValue > 0 ? ((newReturns / initialValue) * 100).toDouble() : 0.0;
    
    return copyWith(
      currentValue: newValue,
      returns: newReturns,
      returnPercentage: newReturnPercentage,
      updatedAt: DateTime.now(),
      priceHistory: [
        ...priceHistory,
        {
          'date': DateTime.now().toIso8601String(),
          'value': newValue,
          'change': newReturns,
          'changePercentage': newReturnPercentage,
        }
      ],
    );
  }
  
  // Complete investment
  InvestmentModel complete() {
    return copyWith(
      status: InvestmentStatus.completed,
      endDate: DateTime.now(),
      durationDays: DateTime.now().difference(startDate).inDays,
      updatedAt: DateTime.now(),
    );
  }
  
  // Cancel investment
  InvestmentModel cancel() {
    return copyWith(
      status: InvestmentStatus.cancelled,
      endDate: DateTime.now(),
      durationDays: DateTime.now().difference(startDate).inDays,
      updatedAt: DateTime.now(),
    );
  }
}

// Asset type utilities
class AssetTypeUtils {
  static String getDisplayName(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return 'Cryptocurrency';
      case AssetType.stocks:
        return 'Stocks';
      case AssetType.etf:
        return 'ETF';
      case AssetType.bonds:
        return 'Bonds';
      case AssetType.nft:
        return 'NFT';
      case AssetType.realEstate:
        return 'Real Estate';
      case AssetType.commodities:
        return 'Commodities';
      case AssetType.forex:
        return 'Forex';
      case AssetType.mutualFunds:
        return 'Mutual Funds';
      case AssetType.greenBonds:
        return 'Green Bonds';
      case AssetType.education:
        return 'Education';
      case AssetType.startup:
        return 'Startup';
      case AssetType.other:
        return 'Other';
    }
  }
  
  static IconData getIcon(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return Icons.currency_bitcoin;
      case AssetType.stocks:
        return Icons.trending_up;
      case AssetType.etf:
        return Icons.analytics;
      case AssetType.bonds:
        return Icons.account_balance;
      case AssetType.nft:
        return Icons.image;
      case AssetType.realEstate:
        return Icons.home;
      case AssetType.commodities:
        return Icons.inventory;
      case AssetType.forex:
        return Icons.currency_exchange;
      case AssetType.mutualFunds:
        return Icons.pie_chart;
      case AssetType.greenBonds:
        return Icons.eco;
      case AssetType.education:
        return Icons.school;
      case AssetType.startup:
        return Icons.rocket_launch;
      case AssetType.other:
        return Icons.more_horiz;
    }
  }
  
  static Color getColor(AssetType type) {
    switch (type) {
      case AssetType.crypto:
        return const Color(0xFFF7931A);
      case AssetType.stocks:
        return const Color(0xFF10B981);
      case AssetType.etf:
        return const Color(0xFF3B82F6);
      case AssetType.bonds:
        return const Color(0xFF8B5CF6);
      case AssetType.nft:
        return const Color(0xFFEC4899);
      case AssetType.realEstate:
        return const Color(0xFFF59E0B);
      case AssetType.commodities:
        return const Color(0xFF06B6D4);
      case AssetType.forex:
        return const Color(0xFF84CC16);
      case AssetType.mutualFunds:
        return const Color(0xFF6366F1);
      case AssetType.greenBonds:
        return const Color(0xFF22C55E);
      case AssetType.education:
        return const Color(0xFFEF4444);
      case AssetType.startup:
        return const Color(0xFF8B5CF6);
      case AssetType.other:
        return const Color(0xFF6B7280);
    }
  }
}
