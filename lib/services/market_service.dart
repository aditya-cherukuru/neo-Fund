// lib/services/market_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  static const baseUrl = "https://api.coingecko.com/api/v3";

  static Future<List<Map<String, dynamic>>> fetchTopCryptos() async {
    final response = await http.get(Uri.parse("$baseUrl/coins/markets?vs_currency=inr&order=market_cap_desc&per_page=5"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => {
        "name": e["name"],
        "price": e["current_price"],
        "change": e["price_change_percentage_24h"],
        "symbol": e["symbol"]
      }).toList();
    } else {
      throw Exception("API Failed");
    }
  }
}
