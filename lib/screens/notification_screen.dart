import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> pendingActivities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    List<Map<String, dynamic>> tempPending = [];

    final now = DateTime.now();

    for (var key in keys) {
      final dataString = prefs.getString(key);
      if (dataString != null) {
        final List decoded = jsonDecode(dataString);
        for (var item in decoded) {
          if (item["done"] == false && item["time"] != null) {
            final t = item["time"];
            DateTime activityTime;

            if (t is Map<String, dynamic>) {
              // Combine today's date with activity hour/minute
              activityTime = DateTime(
                now.year,
                now.month,
                now.day,
                t["hour"],
                t["minute"],
              );
            } else {
              continue; // skip if time is invalid
            }

            // If more than 1 hour passed since activity time
            if (now.difference(activityTime).inMinutes >= 60) {
              tempPending.add({
                "title": item["description"] ?? "Activity", // <-- use description
                "time": activityTime,
              });
            }
          }
        }
      }
    }

    setState(() {
      pendingActivities = tempPending;
      isLoading = false;
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFFDED3F2),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingActivities.isEmpty
          ? const Center(
        child: Text(
          "No pending activities",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: pendingActivities.length,
        itemBuilder: (context, index) {
          final activity = pendingActivities[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(activity["title"]), // now shows description
              subtitle: Text(
                "Scheduled at: ${_formatTime(activity["time"])}",
              ),
              leading: const Icon(
                Icons.notification_important,
                color: Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
