import 'package:flutter/material.dart';
import 'crypto_history_chart.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CryptoHistoryApp(),
      
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A132E)
        ),
        scaffoldBackgroundColor:  const Color(0xFF0A132E),
      ),
    );
  }
}

class CryptoHistoryApp extends StatefulWidget {
  @override
  _CryptoHistoryAppState createState() => _CryptoHistoryAppState();
}

class _CryptoHistoryAppState extends State<CryptoHistoryApp> {
  String? touchedY;
  List<Map<String, double>> cryptoData = [];
  double? highestClose;
  double? lowestClose;

  @override
  void initState() {
    super.initState();
    
  }


  @override
  Widget build(BuildContext context) {
    double percentageChange = 0.0;

    if (cryptoData.isNotEmpty) {
      double earliestPrice = cryptoData.first['close']!;
      double latestPrice = cryptoData.last['close']!;
      percentageChange = ((latestPrice - earliestPrice) / earliestPrice) * 100;
    }

    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        title: Text('USDTUSD'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        
        child: Padding(
          
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    touchedY != null ? '\$$touchedY' : '\$100',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {},
                      child: Icon(
                        Icons.info,
                        color: const Color(0xFF02A7FF),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                percentageChange != 0.0
                    ? '${percentageChange.toStringAsFixed(2)}%'
                    : '0.00%',
                style: TextStyle(
                  fontSize: 16,
                  color: percentageChange > 0 ? const Color(0xFF1FBC7B) : const Color(0xFFE54545),
                ),
              ),
              
              
              SizedBox(height: 16),
              CryptoHistoryChart(
                onTouchedYChanged: (String? newY) {
                  setState(() {
                    touchedY = newY;
                  });
                },
                highestClose: highestClose,
                lowestClose: lowestClose,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xFF1FBC7B),
                      onPrimary: Colors.white,
                      fixedSize: Size(155, 45),
                    ),
                    child: Text(
                      'Buy',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xFFE54545),
                      onPrimary: Colors.white,
                      fixedSize: Size(155, 45),
                    ),
                    child: Text(
                      'Sell',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      
    );
  }
}
