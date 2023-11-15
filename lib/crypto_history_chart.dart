import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class CryptoHistoryChart extends StatefulWidget {
  final Function(String?) onTouchedYChanged;
  final double? highestClose;
  final double? lowestClose;

  CryptoHistoryChart({
    required this.onTouchedYChanged,
    required this.highestClose,
    required this.lowestClose,
  });
  @override
  _CryptoHistoryChartState createState() => _CryptoHistoryChartState();
}

class _CryptoHistoryChartState extends State<CryptoHistoryChart> {
  List<Map<String, double>> cryptoData = [];
  String selectedInterval = "24H";
  int from = 0;
  int to = 0;
  String? touchedY;
  double? highestClose;
  double? lowestClose;

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
      final candleData = jsonData['data']['candles'];

      if (candleData != null && candleData is Iterable) {
        setState(() {
          cryptoData = List<Map<String, double>>.from(candleData.map((candle) {
            final double timestamp = (candle['t'] as num).toDouble();
            final double closePrice = (candle['c'] as num).toDouble();

            return {
              'timestamp': timestamp,
              'close': closePrice,
            };
          }));
          if (cryptoData.isNotEmpty) {
            final closeValues = cryptoData
                .map<double?>((candle) => candle['close'])
                .whereType<double>()
                .toList();

            if (closeValues.isNotEmpty) {
              setState(() {
                highestClose = closeValues.reduce(math.max);
                lowestClose = closeValues.reduce(math.min);
              });
            }
          }

          print("cryptoData: $cryptoData");
          print("highestClose: $highestClose");
          print("lowestClose: $lowestClose");
        });
      } else {
        print('Error: Candle data is null or not iterable');
      }
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
      return 'https://dev-api.hata.io/orderbook/api/candles/history?resolution=30&from=$from&to=$to&symbol=USDTUSD';
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
      if (highestClose != null && lowestClose != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Highest Price: $highestClose',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'Lowest Price: $lowestClose',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        SizedBox(height: 16),
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
                      minX: cryptoData.isNotEmpty
                          ? cryptoData.first['timestamp']!.toDouble()
                          : 0,
                      maxX: cryptoData.isNotEmpty
                          ? cryptoData.last['timestamp']!.toDouble()
                          : 1,
                      lineTouchData: LineTouchData(
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            final spot = barData.spots[spotIndex];
                            if (spot.x == 0 || spot.x == 6) {
                              return null;
                            }
                            return TouchedSpotIndicatorData(
                              const FlLine(
                                color: Colors.red,
                                strokeWidth: 4,
                              ),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 0,
                                    color: Colors.white,
                                    strokeWidth: 5,
                                    strokeColor: Colors.red,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.transparent,
                          tooltipRoundedRadius: 0,
                          getTooltipItems: (touchedSpots) => touchedSpots
                              .map(
                                (e) => const LineTooltipItem(
                                  '',
                                  TextStyle(color: Colors.transparent),
                                ),
                              )
                              .toList(),
                        ),
                        touchCallback: (p0, p1) {
                          debugPrint(p1?.lineBarSpots?.first.x.toString());
                          debugPrint(p1?.lineBarSpots?.first.y.toString());
                          widget.onTouchedYChanged(
                              p1?.lineBarSpots?.first.y.toString());

                          setState(() {
                            touchedY = p1?.lineBarSpots?.first.y.toString();
                          });
                        },
                        handleBuiltInTouches: true,
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: false,
                          color: Colors.green,
                          spots: cryptoData.asMap().entries.map((entry) {
                            final candle = entry.value;
                            return FlSpot(
                              candle['timestamp']!.toDouble(),
                              candle['close']!.toDouble(),
                            );
                          }).toList()
                            ..sort((a, b) => a.x.compareTo(b.x)),
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
            TextButton(
              onPressed: () {
                changeInterval("24H");
              },
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
              child: Text('24H'),
            ),
            TextButton(
              onPressed: () {
                changeInterval("1W");
              },
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
              child: Text('1W'),
            ),
            TextButton(
              onPressed: () {
                changeInterval("1M");
              },
              style: TextButton.styleFrom(
                primary: Colors.white,
              ),
              child: Text('1M'),
            ),
          ],
        ),
      ],
    );
  }
}
