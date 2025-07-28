import 'dart:convert';

class ForecastEntry {
  final DateTime timestamp;
  final Map<String, dynamic> userInput;
  final Map<String, dynamic> forecastResult;

  ForecastEntry({
    required this.timestamp,
    required this.userInput,
    required this.forecastResult,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'userInput': userInput,
    'forecastResult': forecastResult,
  };

  static ForecastEntry fromJson(Map<String, dynamic> json) {
    // Accept both 'timestamp' and 'createdAt' for compatibility
    final ts = json['timestamp'] ?? json['createdAt'];
    if (ts == null) {
      print('ForecastEntry.fromJson: missing timestamp/createdAt in $json');
      throw Exception('ForecastEntry missing timestamp/createdAt');
    }
    return ForecastEntry(
      timestamp: DateTime.parse(ts),
      userInput: Map<String, dynamic>.from(json['userInput'] ?? {}),
      forecastResult: Map<String, dynamic>.from(json['forecastResult'] ?? {}),
    );
  }

  static List<ForecastEntry> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => ForecastEntry.fromJson(e)).toList();
  }

  static String listToJson(List<ForecastEntry> entries) {
    return json.encode(entries.map((e) => e.toJson()).toList());
  }
} 