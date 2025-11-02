import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'plan_a_day_screen.dart';
import 'activity_card_screen.dart';
import 'notification_screen.dart'; // <-- Import NotificationScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> todayActivities = [];
  late String currentDateKey;
  late String currentDateDisplay = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentDateKey = DateFormat('yyyy-MM-dd').format(now);
    currentDateDisplay = DateFormat('dd/MM/yyyy').format(now);
    _loadTodayActivities();
  }

  Future<void> _loadTodayActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(currentDateKey);

    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        todayActivities = decoded.map<Map<String, dynamic>>((item) {
          return {
            "title": item["title"] ?? "Activity",
            "description": item["description"] ?? "",
            "time": item["time"],
            "tutorial": item["tutorial"] ?? "",
            "done": item["done"] ?? false,
          };
        }).toList();
      });
    }
  }

  Future<void> _saveTodayActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = todayActivities.map((item) {
      return {
        "title": item["title"],
        "description": item["description"],
        "time": item["time"],
        "tutorial": item["tutorial"],
        "done": item["done"] ?? false,
      };
    }).toList();
    await prefs.setString(currentDateKey, jsonEncode(encoded));
  }

  String _formatTime(Map<String, dynamic> activity) {
    if (activity["time"] is Map<String, dynamic>) {
      final t = activity["time"];
      final timeOfDay = TimeOfDay(hour: t["hour"], minute: t["minute"]);
      return timeOfDay.format(context);
    }
    return activity["time"]?.toString() ?? "";
  }

  void _openActivityCard(Map<String, dynamic> activity, int index) async {
    final timeMap = activity["time"];
    TimeOfDay timeOfDay;
    if (timeMap is Map<String, dynamic>) {
      timeOfDay = TimeOfDay(hour: timeMap["hour"], minute: timeMap["minute"]);
    } else if (activity["time"] is TimeOfDay) {
      timeOfDay = activity["time"];
    } else {
      timeOfDay = TimeOfDay.now();
    }

    final activityForCard = {
      "title": activity["title"],
      "description": activity["description"],
      "time": timeOfDay,
      "tutorial": activity["tutorial"],
      "done": activity["done"] ?? false,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityCardScreen(
          activity: activityForCard,
          index: index,
          isHomeScreen: true,
        ),
      ),
    );

    if (result != null && result['action'] == 'toggleDone') {
      setState(() {
        todayActivities[index]['done'] = result['isDone'];
      });
      _saveTodayActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Companion"),
        centerTitle: true,
        backgroundColor: const Color(0xFFDED3F2),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Updated: navigate to NotificationScreen
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFDED3F2)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Plan a Day'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlanADayScreen()),
                ).then((_) => _loadTodayActivities());
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Progress'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Here’s your plan for today!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currentDateDisplay,
              style: const TextStyle(fontSize: 16, color: Color(0xFF454343)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: todayActivities.isEmpty
                  ? Center(
                child: Text(
                  "No activities planned yet for today",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: todayActivities.length,
                itemBuilder: (context, index) {
                  final activity = todayActivities[index];
                  final time = _formatTime(activity);
                  final tutorialLink = activity["tutorial"] ?? "";
                  final isDone = activity["done"] ?? false;

                  return GestureDetector(
                    onTap: () => _openActivityCard(activity, index),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: isDone ? Colors.green[100] : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (tutorialLink.isNotEmpty)
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activity["description"] ?? "",
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
