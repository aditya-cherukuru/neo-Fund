class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile profile;
  final VirtualWallet wallet;
  final List<String> achievementIds;
  final int xpPoints;
  final int level;
  final UserPreferences preferences;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.profile,
    required this.wallet,
    this.achievementIds = const [],
    this.xpPoints = 0,
    this.level = 1,
    required this.preferences,
  });

  String get fullName => '$firstName $lastName';
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  bool get isEligible => age >= 16;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      profile: UserProfile.fromJson(json['profile']),
      wallet: VirtualWallet.fromJson(json['wallet']),
      achievementIds: List<String>.from(json['achievementIds'] ?? []),
      xpPoints: json['xpPoints'] ?? 0,
      level: json['level'] ?? 1,
      preferences: UserPreferences.fromJson(json['preferences']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profile': profile.toJson(),
      'wallet': wallet.toJson(),
      'achievementIds': achievementIds,
      'xpPoints': xpPoints,
      'level': level,
      'preferences': preferences.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? profile,
    VirtualWallet? wallet,
    List<String>? achievementIds,
    int? xpPoints,
    int? level,
    UserPreferences? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
      wallet: wallet ?? this.wallet,
      achievementIds: achievementIds ?? this.achievementIds,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserProfile {
  final String riskTolerance; // conservative, moderate, aggressive
  final List<String> investmentGoals;
  final String? avatarUrl;
  final String? bio;
  final bool isPublic;
  final Map<String, dynamic> onboardingData;

  UserProfile({
    required this.riskTolerance,
    this.investmentGoals = const [],
    this.avatarUrl,
    this.bio,
    this.isPublic = false,
    this.onboardingData = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      riskTolerance: json['riskTolerance'],
      investmentGoals: List<String>.from(json['investmentGoals'] ?? []),
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      isPublic: json['isPublic'] ?? false,
      onboardingData: json['onboardingData'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riskTolerance': riskTolerance,
      'investmentGoals': investmentGoals,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'isPublic': isPublic,
      'onboardingData': onboardingData,
    };
  }

  UserProfile copyWith({
    String? riskTolerance,
    List<String>? investmentGoals,
    String? avatarUrl,
    String? bio,
    bool? isPublic,
    Map<String, dynamic>? onboardingData,
  }) {
    return UserProfile(
      riskTolerance: riskTolerance ?? this.riskTolerance,
      investmentGoals: investmentGoals ?? this.investmentGoals,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isPublic: isPublic ?? this.isPublic,
      onboardingData: onboardingData ?? this.onboardingData,
    );
  }
}

class VirtualWallet {
  final double balance;
  final double totalInvested;
  final double totalReturns;
  final double dayChange;
  final double dayChangePercent;
  final DateTime lastUpdated;

  VirtualWallet({
    required this.balance,
    this.totalInvested = 0.0,
    this.totalReturns = 0.0,
    this.dayChange = 0.0,
    this.dayChangePercent = 0.0,
    required this.lastUpdated,
  });

  double get totalValue => balance + totalInvested;
  double get totalReturnPercent => totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;
  bool get isPositive => totalReturns >= 0;

  factory VirtualWallet.fromJson(Map<String, dynamic> json) {
    return VirtualWallet(
      balance: json['balance']?.toDouble() ?? 0.0,
      totalInvested: json['totalInvested']?.toDouble() ?? 0.0,
      totalReturns: json['totalReturns']?.toDouble() ?? 0.0,
      dayChange: json['dayChange']?.toDouble() ?? 0.0,
      dayChangePercent: json['dayChangePercent']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'totalInvested': totalInvested,
      'totalReturns': totalReturns,
      'dayChange': dayChange,
      'dayChangePercent': dayChangePercent,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  VirtualWallet copyWith({
    double? balance,
    double? totalInvested,
    double? totalReturns,
    double? dayChange,
    double? dayChangePercent,
    DateTime? lastUpdated,
  }) {
    return VirtualWallet(
      balance: balance ?? this.balance,
      totalInvested: totalInvested ?? this.totalInvested,
      totalReturns: totalReturns ?? this.totalReturns,
      dayChange: dayChange ?? this.dayChange,
      dayChangePercent: dayChangePercent ?? this.dayChangePercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserPreferences {
  final bool darkMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final String language;
  final String currency;
  final Map<String, bool> notificationTypes;

  UserPreferences({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.language = 'en',
    this.currency = 'INR',
    this.notificationTypes = const {
      'portfolio_updates': true,
      'squad_activities': true,
      'educational_content': true,
      'achievements': true,
      'market_news': false,
    },
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['darkMode'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'INR',
      notificationTypes: Map<String, bool>.from(json['notificationTypes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'language': language,
      'currency': currency,
      'notificationTypes': notificationTypes,
    };
  }

  UserPreferences copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    String? language,
    String? currency,
    Map<String, bool>? notificationTypes,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      notificationTypes: notificationTypes ?? this.notificationTypes,
    );
  }
}
