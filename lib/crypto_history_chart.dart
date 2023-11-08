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
  String selectedInterval = "24H";
  int from = 0;
  int to = 0;

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
          final double closePrice = candle['c'] as double;

          return {
            'timestamp': timestamp,
            'close': closePrice,
          };
        }).toList();
      });
    }
  }

  String _getApiUrlForInterval(String interval) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (interval == "24H") {
      from = now - 86400;
      to = now;
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=5&from=$from&to=$to&symbol=USDTUSD';
    } else if (interval == "1W") {
      from = now - 604800;
      to = now;
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=60&from=$from&to=$to&symbol=USDTUSD';
    } else if (interval == "1M") {
      from = now - 2592000;
      to = now;
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=240&from=$from&to=$to&symbol=USDTUSD';
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
                          .map<double>((candle) => candle['close'] as double)
                          .reduce(
                              (min, current) => min < current ? min : current),
                      maxY: cryptoData
                          .map<double>((candle) => candle['close'] as double)
                          .reduce(
                              (max, current) => max > current ? max : current),
                      minX: 1699363200,
                      maxX: 1699345500,
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: false,
                          color: Colors.blue,
                          spots: cryptoData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final candle = entry.value;
                            return FlSpot(candle['timestamp']!.toDouble(),
                                candle['close'] as double);
                          }).toList(),
                          dotData: FlDotData(show: false),
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
                changeInterval("24H");
              },
              child: Text('24H'),
            ),
            ElevatedButton(
              onPressed: () {
                changeInterval("1W");
              },
              child: Text('1W'),
            ),
            ElevatedButton(
              onPressed: () {
                changeInterval("1M");
              },
              child: Text('1M'),
            ),
          ],
        ),
      ],
    );
  }
}
