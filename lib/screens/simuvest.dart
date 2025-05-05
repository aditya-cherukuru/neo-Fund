// lib/screens/invest.dart
import 'package:flutter/material.dart';
import '../services/market_service.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({Key? key}) : super(key: key);

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  late Future<List<Map<String, dynamic>>> _marketFuture;

  @override
  void initState() {
    super.initState();
    _marketFuture = MarketService.fetchTopCryptos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Investment Engine")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _marketFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final best = data.reduce((a, b) =>
                a["change"] > b["change"] ? a : b);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "📈 Best Pick Today: ${best["name"]} (${best["symbol"]})\nChange: ${best["change"]}%",
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        title: Text(data[i]["name"]),
                        subtitle: Text("₹${data[i]["price"]}"),
                        trailing: Text(
                          "${data[i]["change"]}%",
                          style: TextStyle(
                            color: data[i]["change"] > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("API Error: ${snapshot.error}"));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
