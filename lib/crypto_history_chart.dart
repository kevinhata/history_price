import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class CryptoHistoryChart extends StatefulWidget {
  @override
  _CryptoHistoryChartState createState() => _CryptoHistoryChartState();
}

class _CryptoHistoryChartState extends State<CryptoHistoryChart> {
  List<Map<String, double>> cryptoData = [];
  String selectedInterval = "1m"; 

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    String apiUrl = _getApiUrlForInterval(selectedInterval);
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final candleData =
          List<Map<String, dynamic>>.from(jsonData['data']['candles']);

      setState(() {
        cryptoData = candleData.map((candle) {
          final double timestamp = (candle['t'] as int).toDouble();
          final double openPrice = candle['o'] as double;
          final double highPrice = candle['h'] as double;
          final double lowPrice = candle['l'] as double;
          final double closePrice = candle['c'] as double;

          return {
            'timestamp': timestamp,
            'open': openPrice,
            'high': highPrice,
            'low': lowPrice,
            'close': closePrice,
          };
        }).toList();
      });
    }
  }

  String _getApiUrlForInterval(String interval) {
    if (interval == "1m") {
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=1&from=1698986878&to=1698987358&symbol=USDTUSD';
    } else if (interval == "5m") {
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=5&from=1698986878&to=1698987358&symbol=USDTUSD';
    } else if (interval == "15m") {
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=15&from=1698986878&to=1698987358&symbol=USDTUSD';
    }
    return '';
  }

  void changeInterval(String interval) {
    setState(() {
      selectedInterval = interval;
      fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 250,
            child: cryptoData.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      minY: cryptoData
                          .map<double>((candle) => candle['low'] as double)
                          .reduce(
                              (min, current) => min < current ? min : current),
                      maxY: cryptoData
                          .map<double>((candle) => candle['high'] as double)
                          .reduce(
                              (max, current) => max > current ? max : current),
                      minX: 0,
                      maxX: cryptoData.length.toDouble() - 1,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: false,
                          color: Colors.blue,
                          spots: cryptoData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final candle = entry.value;
                            return FlSpot(
                                index.toDouble(), candle['close'] as double);
                          }).toList(),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                changeInterval("1m");
              },
              child: Text('1m'),
            ),
            ElevatedButton(
              onPressed: () {
                changeInterval("5m");
              },
              child: Text('5m'),
            ),
            ElevatedButton(
              onPressed: () {
                changeInterval("15m");
              },
              child: Text('15m'),
            ),
          ],
        ),
      ],
    );
  }
}
