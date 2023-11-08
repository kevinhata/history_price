import 'package:flutter/material.dart';
import 'crypto_history_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('USDT Price History'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Center(child: CryptoHistoryChart()),
        ),
      ),
    );
  }
}
