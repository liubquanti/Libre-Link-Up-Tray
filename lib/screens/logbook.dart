import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart'; // Додайте імпорт
import '../services/api.dart';

class LogbookScreen extends StatefulWidget {
  final VoidCallback onBack;
  final LibreLinkService service;
  const LogbookScreen({super.key, required this.onBack, required this.service});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late Future<List<dynamic>?> _logbookFuture;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _logbookFuture = widget.service.getLogbook();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Додаємо функцію кольору як на головному екрані
  Color _getGlucoseColor(int value, double targetLow, double targetHigh) {
    const int LOW = 70;
    const int HIGH = 240;

    if (value < LOW) {
      return Colors.red;
    }
    if (value > HIGH) {
      return Colors.orange;
    }
    if ((value < targetLow && value >= LOW) || (value > targetHigh && value <= HIGH)) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  Map<String, List<dynamic>> _groupByDate(List<dynamic> entries) {
    final Map<String, List<dynamic>> grouped = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var entry in entries) {
      final ts = entry['Timestamp'] ?? '';
      DateTime? dt;
      try {
        dt = DateFormat('M/d/yyyy h:mm:ss a').parse(ts);
      } catch (_) {
        dt = DateTime.tryParse(ts);
      }
      final dateStr = dt != null ? dateFormat.format(dt) : ts;
      grouped.putIfAbsent(dateStr, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onBack();
        }
      },
      child: NavigationView(
        content: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>?>(
                future: _logbookFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: ProgressRing());
                  }
                  final logbook = snapshot.data!;
                  if (logbook.isEmpty) {
                    return const Center(child: Text('No logbook entries'));
                  }
                  final grouped = _groupByDate(logbook);
                  final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // новіші дати зверху
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                    itemCount: dateKeys.length,
                    itemBuilder: (context, dateIndex) {
                      final date = dateKeys[dateIndex];
                      final entries = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dateIndex == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 18,),
                            child: Text(
                            'Logbook',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Text(
                          DateFormat('dd.MM.yyyy').format(DateTime.parse(date)),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...entries.map((entry) {
                          final value = entry['Value'] as int? ?? 0;
                          final targetLow = entry['targetLow']?.toDouble() ?? 70.0;
                          final targetHigh = entry['targetHigh']?.toDouble() ?? 180.0;
                          final glucoseColor = _getGlucoseColor(value, targetLow, targetHigh);

                          final trendArrow = entry['TrendArrow'] as int?;
                          IconData? trendDisplayArrow;
                          switch (trendArrow) {
                          case 1: trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_down_filled; break;
                          case 2: trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_down_left_filled; break;
                          case 3: trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_right_filled; break;
                          case 4: trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_up_right_filled; break;
                          case 5: trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_up_filled; break;
                          }

                          return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: glucoseColor.withOpacity(0.2),
                            border: Border.all(
                            color: FluentTheme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1d1d1d)
                              : const Color(0xFFe5e5e5),
                            width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                            Container(
                              width: 15,
                              height: 80,
                              decoration: BoxDecoration(
                              color: glucoseColor,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 150,
                              child: Row(
                              children: [
                                Text(
                                '$value',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                children: [
                                  if (trendDisplayArrow != null)
                                  Transform(
                                  alignment: Alignment.center,
                                  transform: (trendDisplayArrow == FluentSystemIcons.ic_fluent_arrow_down_left_filled)
                                    ? Matrix4.rotationY(math.pi)
                                    : Matrix4.identity(),
                                    child: Icon(
                                      trendDisplayArrow,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    ),
                                    const Text(
                                    'mg/dL',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                ],
                                ),
                              ],
                              ),
                            ),
                            const SizedBox(width: 30),
                            if (entry['alarmType'] != null)
                            Icon(
                              FluentSystemIcons.ic_fluent_alert_regular,
                              size: 25,
                              color: FluentTheme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFffffff)
                              : const Color(0xFF1b1b1b),
                            ),
                            const Spacer(),
                            Text(
                              (() {
                              final ts = entry['Timestamp'] ?? '';
                              DateTime? dt;
                              try {
                                dt = DateFormat('M/d/yyyy h:mm:ss a').parse(ts);
                              } catch (_) {
                                dt = DateTime.tryParse(ts);
                              }
                              return dt != null ? DateFormat('HH:mm').format(dt) : ts;
                              })(),
                              style: const TextStyle(fontSize: 13),
                            ),
                            ],
                          ),
                          );
                        }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}