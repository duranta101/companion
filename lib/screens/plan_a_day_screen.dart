import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'activity_list_screen.dart'; // Import the ActivityListScreen

class PlanADayScreen extends StatefulWidget {
  const PlanADayScreen({super.key});

  @override
  State<PlanADayScreen> createState() => _PlanADayScreenState();
}

class _PlanADayScreenState extends State<PlanADayScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan a Day"),
        backgroundColor: const Color(0xFFDED3F2), // same appbar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Layer 1: Title
            const Text(
              "Choose a day to plan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Layer 2: Calendar
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now(), // cannot select past days
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  // Navigate to ActivityListScreen on day selection
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityListScreen(
                        selectedDate: selectedDay,
                      ),
                    ),
                  );
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepPurple.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
