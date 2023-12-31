import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class CryptoHistoryChart extends StatefulWidget {
  final Function(String?) onTouchedYChanged;
  final double? highestClose;
  final double? lowestClose;
  final List<Color> gradientColors = [
    const Color(0xFF6BD0BE),
    const Color(0xFFD9D9D9),
  ];

   CryptoHistoryChart({
    required this.onTouchedYChanged,
    required this.highestClose,
    required this.lowestClose,
    Key? key,
  }) : super(key: key);

  @override
  State<CryptoHistoryChart> createState() => _CryptoHistoryChartState();
}

class _CryptoHistoryChartState extends State<CryptoHistoryChart> {
  List<Map<String, double>> cryptoData = [];
  List<int> showingTooltipOnSpots = [0, 1, 2, 3, 4];
  String selectedInterval = "24H";
  int from = 0;
  int to = 0;
  String? touchedY;
  double? highestClose;
  double? lowestClose;
  FlSpot? highestPoint;
  FlSpot? lowestPoint;

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
        print('Error');
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
    final lineBarsData = [
      LineChartBarData(
        isCurved: false,
        color: const Color(0xFF1FBC7B),
        barWidth: 1,
        isStrokeCapRound: false,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade700,
              const Color(0xFF0A132E),
            ],
            stops: [0.2, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        spots: cryptoData.asMap().entries.map((entry) {
          final candle = entry.value;
          final timestamp = candle['timestamp']!.toDouble();
          final close = candle['close']!.toDouble();

          if (close == highestClose) {
            highestPoint = FlSpot(timestamp, close);
          }
          if (close == lowestClose) {
            lowestPoint = FlSpot(timestamp, close);
          }

          return FlSpot(timestamp, close);
        }).toList()
          ..sort((a, b) => a.x.compareTo(b.x)),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isHighest = spot.y == highestClose;
            final isLowest = spot.y == lowestClose;

            return FlDotCirclePainter(
              radius: isHighest || isLowest ? 3 : 0,
              color: Colors.white,
              strokeWidth: isHighest || isLowest ? 1 : 0,
              strokeColor: Colors.red,
              
                  
            );
          },
        ),
      ),
    ];
    final tooltipsOnBar = lineBarsData[0];
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
        SizedBox(height: 48),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 250,
            child: cryptoData.isNotEmpty
                ? LineChart(
                    LineChartData(
                      showingTooltipIndicators:
                          showingTooltipOnSpots.map((index) {
                        return ShowingTooltipIndicators([
                          LineBarSpot(
                            tooltipsOnBar,
                            lineBarsData.indexOf(tooltipsOnBar),
                            tooltipsOnBar.spots[index],
                          ),
                        ]);
                      }).toList(),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: cryptoData
                          .map<double>((candle) => candle['close'] as double)
                          .reduce(
                              (min, current) => min < current ? min : current),
                      maxY: cryptoData
                          .map<double>((candle) => candle['close'] as double)
                          .reduce(
                              (max, current) => max > current ? max : current),
                      minX: cryptoData.isNotEmpty
                          ? cryptoData.last['timestamp']!.toDouble()
                          : 0,
                      maxX: cryptoData.isNotEmpty
                          ? cryptoData.first['timestamp']!.toDouble()
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
                          fitInsideHorizontally: true,
                          tooltipBgColor: Colors.transparent,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            if (touchedSpots.isNotEmpty) {
                              final spot = touchedSpots.first;
                              final isHighest = spot.y == highestClose;
                              final isLowest = spot.y == lowestClose;

                              if (isHighest || isLowest) {
                                return [
                                  LineTooltipItem(
                                    '${isHighest ? 'Highest' : 'Lowest'}: ${spot.y.toString()}',
                                    TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ];
                              }
                            }

                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                touchedSpot.y.toString(),
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              );
                            }).toList();
                          },
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
                      lineBarsData: lineBarsData,
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIntervalButton("24H"),
            _buildIntervalButton("1W"),
            _buildIntervalButton("1M"),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalButton(String interval) {
    bool isSelected = selectedInterval == interval;

    return Container(
      width: 55,
      height: 45,
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF315FE8)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF315FE8),
            )
          : null,
      child: TextButton(
        onPressed: () {
          changeInterval(interval);
        },
        style: TextButton.styleFrom(
          primary: isSelected ? Colors.white : Colors.white,
        ),
        child: Text(
          interval,
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
