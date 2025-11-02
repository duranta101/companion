import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class CreateActivityScreen extends StatefulWidget {
  final Map<String, dynamic>? activity; // Optional activity for editing

  const CreateActivityScreen({super.key, this.activity});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final TextEditingController _whatController = TextEditingController();
  final TextEditingController _tutorialLinkController = TextEditingController();
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill fields
    if (widget.activity != null) {
      _whatController.text = widget.activity!['description'] ?? '';
      _tutorialLinkController.text = widget.activity!['tutorial'] ?? '';
      _selectedTime = widget.activity!['time'] as TimeOfDay;
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  void _submitActivity() {
    if (_whatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the activity description')),
      );
      return;
    }

    // Prepare activity data
    final activity = {
      'description': _whatController.text,
      'time': _selectedTime,
      'tutorial': _tutorialLinkController.text,
    };

    // Return to previous screen (ActivityListScreen or ActivityCardScreen)
    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Activity" : "Create Activity"),
        backgroundColor: const Color(0xFFDED3F2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 1st layer: What to do
            const Text(
              "What to do?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _whatController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter activity description",
              ),
            ),
            const SizedBox(height: 16),

            // 2nd layer: When to do (persistent time spinner)
            const Text(
              "When to do?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: TimePickerSpinner(
                is24HourMode: false,
                normalTextStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                highlightedTextStyle: const TextStyle(fontSize: 24, color: Colors.black),
                spacing: 50,
                itemHeight: 50,
                isForce2Digits: true,
                time: DateTime(
                  0,
                  0,
                  0,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onTimeChange: (time) {
                  setState(() {
                    _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // 3rd layer: How to do it (tutorial link optional)
            const Text(
              "How to do it?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tutorialLinkController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Paste tutorial link (optional)",
              ),
            ),
            const SizedBox(height: 24),

            // 4th layer: Submit button
            Center(
              child: ElevatedButton(
                onPressed: _submitActivity,
                child: Text(isEditing ? "Update Activity" : "Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
