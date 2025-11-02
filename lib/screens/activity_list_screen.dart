import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_activity_screen.dart';
import 'activity_card_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ActivityListScreen({super.key, required this.selectedDate});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  List<Map<String, dynamic>> activities = [];

  String get formattedDate {
    return "${widget.selectedDate.day} ${_monthName(widget.selectedDate.month)}, ${widget.selectedDate.year}";
  }

  static String _monthName(int month) {
    const monthNames = [
      '', // dummy for 1-based index
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month];
  }

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.selectedDate.toIso8601String().split("T")[0];
    final savedData = prefs.getString(key);

    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        activities = decoded.map((item) {
          return {
            "time": TimeOfDay(
              hour: item["time"]["hour"],
              minute: item["time"]["minute"],
            ),
            "description": item["description"],
            "tutorial": item["tutorial"],
          };
        }).toList();
        _sortActivities();
      });
    }
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.selectedDate.toIso8601String().split("T")[0];

    final List encoded = activities.map((item) {
      final time = item["time"] as TimeOfDay;
      return {
        "time": {"hour": time.hour, "minute": time.minute},
        "description": item["description"],
        "tutorial": item["tutorial"],
      };
    }).toList();

    await prefs.setString(key, jsonEncode(encoded));
  }

  void _navigateToCreateActivity({Map<String, dynamic>? activity, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityScreen(activity: activity),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (activity != null && index != null) {
          activities[index] = result;
        } else {
          activities.add(result);
        }
        _sortActivities();
      });
      _saveActivities(); // ✅ save after change
    }
  }

  void _sortActivities() {
    activities.sort((a, b) {
      final aTime = a['time'] as TimeOfDay;
      final bTime = b['time'] as TimeOfDay;
      return aTime.hour.compareTo(bTime.hour) != 0
          ? aTime.hour.compareTo(bTime.hour)
          : aTime.minute.compareTo(bTime.minute);
    });
  }

  Future<void> _navigateToActivityDetail(Map<String, dynamic> activity, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityCardScreen(
          activity: activity,
          index: index,
        ),
      ),
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        setState(() {
          activities.removeAt(index);
        });
        _saveActivities();
      } else if (result['action'] == 'edit') {
        setState(() {
          activities[index] = result['activity'];
          _sortActivities();
        });
        _saveActivities();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plan for $formattedDate"),
        backgroundColor: const Color(0xFFDED3F2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => _navigateToCreateActivity(),
                child: const Text("Create Activity"),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: activities.isEmpty
                  ? Center(
                child: Text(
                  "Activity cards will appear here",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final time = activity['time'] as TimeOfDay;
                  final description = activity['description'] as String;
                  final tutorialLink = activity['tutorial'] as String?;

                  return GestureDetector(
                    onTap: () => _navigateToActivityDetail(activity, index),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  time.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (tutorialLink != null && tutorialLink.isNotEmpty)
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
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
