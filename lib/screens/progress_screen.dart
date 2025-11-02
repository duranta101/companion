import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, List<Map<String, dynamic>>> allActivities = {};
  Map<String, double> last7DaysPerformance = {};
  int streak = 0;
  bool isLoading = true; // <-- loading flag

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    Map<String, List<Map<String, dynamic>>> tempData = {};

    for (var key in keys) {
      final dataString = prefs.getString(key);
      if (dataString != null) {
        final List decoded = jsonDecode(dataString);
        tempData[key] = decoded.map<Map<String, dynamic>>((item) {
          return {
            "title": item["title"],
            "done": item["done"] ?? false,
          };
        }).toList();
      }
    }

    setState(() {
      allActivities = tempData;
      _calculatePerformance();
      _calculateStreak();
      isLoading = false; // <-- mark loading complete
    });
  }

  void _calculatePerformance() {
    final today = DateTime.now();
    last7DaysPerformance.clear();

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final activities = allActivities[key] ?? [];

      double percent = 0;
      if (activities.isNotEmpty) {
        final doneCount = activities.where((a) => a['done'] == true).length;
        percent = doneCount / activities.length * 100;
      }
      last7DaysPerformance[key] = percent;
    }
  }

  void _calculateStreak() {
    final today = DateTime.now();
    int currentStreak = 0;

    for (int i = 0; i < 100; i++) {
      final day = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final activities = allActivities[key] ?? [];
      if (activities.isEmpty) continue;

      final allDone = activities.every((a) => a['done'] == true);
      if (allDone) {
        currentStreak++;
      } else {
        break;
      }
    }

    streak = currentStreak;
  }

  @override
  Widget build(BuildContext context) {
    final keys = last7DaysPerformance.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
        centerTitle: true,
        backgroundColor: const Color(0xFFDED3F2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "100% streak: $streak days",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              "Last 7 days performance",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: last7DaysPerformance.isEmpty
                  ? const Center(
                child: Text(
                  "No activity data available",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget:
                            (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= keys.length) {
                            return const SizedBox();
                          }
                          final dateKey = keys[index];
                          final date = DateFormat('E')
                              .format(DateTime.parse(dateKey));
                          return Text(date,
                              style: const TextStyle(fontSize: 12));
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    keys.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: last7DaysPerformance[keys[index]]!,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
