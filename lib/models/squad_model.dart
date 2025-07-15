class SquadModel {
  final String id;
  final String name;
  final List<String> members;
  final double totalPoolValue;
  final DateTime createdAt;
  final String createdBy;
  
  SquadModel({
    required this.id,
    required this.name,
    required this.members,
    required this.totalPoolValue,
    required this.createdAt,
    required this.createdBy,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'totalPoolValue': totalPoolValue,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
  
  factory SquadModel.fromMap(Map<String, dynamic> map) {
    return SquadModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      totalPoolValue: (map['totalPoolValue'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
    );
  }
}
