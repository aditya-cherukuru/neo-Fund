class UserModel {
  final String uid;
  final String email;
  final String name;
  final double totalBalance;
  final int xpLevel;
  final int streak;
  final List<String> interests;
  final String riskTolerance;
  final DateTime createdAt;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.totalBalance,
    required this.xpLevel,
    required this.streak,
    required this.interests,
    required this.riskTolerance,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'totalBalance': totalBalance,
      'xpLevel': xpLevel,
      'streak': streak,
      'interests': interests,
      'riskTolerance': riskTolerance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      totalBalance: (map['totalBalance'] ?? 0).toDouble(),
      xpLevel: map['xpLevel'] ?? 1,
      streak: map['streak'] ?? 0,
      interests: List<String>.from(map['interests'] ?? []),
      riskTolerance: map['riskTolerance'] ?? 'Medium',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
