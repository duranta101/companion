import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'create_activity_screen.dart';

class ActivityCardScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final int index;
  final bool isHomeScreen;

  const ActivityCardScreen({
    super.key,
    required this.activity,
    required this.index,
    this.isHomeScreen = false,
  });

  @override
  State<ActivityCardScreen> createState() => _ActivityCardScreenState();
}

class _ActivityCardScreenState extends State<ActivityCardScreen> {
  late YoutubePlayerController _youtubeController;
  late Map<String, dynamic> activity;
  late bool isDone;

  @override
  void initState() {
    super.initState();
    activity = widget.activity;

    // Correctly initialize from 'done' key
    isDone = activity['done'] ?? false;

    final tutorialLink = activity['tutorial'] as String?;
    final videoId = tutorialLink != null
        ? YoutubePlayerController.convertUrlToId(tutorialLink)
        : null;

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.close();
    super.dispose();
  }

  void _deleteActivity() {
    Navigator.pop(context, {'action': 'delete', 'index': widget.index});
  }

  void _editActivity() async {
    final updatedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateActivityScreen(
          activity: activity,
        ),
      ),
    );

    if (updatedActivity != null && mounted) {
      setState(() {
        activity['description'] = updatedActivity['description'];
        activity['time'] = updatedActivity['time'];
        activity['tutorial'] = updatedActivity['tutorial'];
      });

      Navigator.pop(context, {
        'action': 'edit',
        'index': widget.index,
        'activity': updatedActivity,
      });
    }
  }

  void _toggleDone() {
    setState(() {
      isDone = !isDone;
      activity['done'] = isDone; // Update correct key
    });

    Navigator.pop(context, {
      'action': 'toggleDone',
      'index': widget.index,
      'isDone': isDone,
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeData = activity['time'];
    late TimeOfDay timeOfDay;

    if (timeData is TimeOfDay) {
      timeOfDay = timeData;
    } else if (timeData is Map<String, dynamic>) {
      timeOfDay = TimeOfDay(hour: timeData['hour'], minute: timeData['minute']);
    } else {
      timeOfDay = TimeOfDay.now();
    }

    final description = activity['description'] as String;
    final tutorialLink = activity['tutorial'] as String?;

    final ButtonStyle unifiedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFDED3F2),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    final ButtonStyle deleteButtonStyle = unifiedButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(Colors.redAccent),
      foregroundColor: MaterialStateProperty.all(Colors.white),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity Details"),
        backgroundColor: const Color(0xFFDED3F2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Text(
                timeOfDay.format(context),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              description,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            if (tutorialLinkIsValid(tutorialLink))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayerControllerProvider(
                  controller: _youtubeController,
                  child: YoutubePlayer(
                    controller: _youtubeController,
                    aspectRatio: 16 / 9,
                  ),
                ),
              )
            else
              const Text(
                "No tutorial link provided",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 24),
            Center(
              child: widget.isHomeScreen
                  ? ElevatedButton(
                onPressed: _toggleDone,
                style: unifiedButtonStyle,
                child: Text(isDone ? "Unmark" : "Mark as Done"),
              )
                  : Column(
                children: [
                  ElevatedButton(
                    onPressed: _editActivity,
                    style: unifiedButtonStyle,
                    child: const Text("Edit Activity"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _deleteActivity,
                    style: deleteButtonStyle,
                    child: const Text("Delete Activity"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool tutorialLinkIsValid(String? link) {
    return link != null && link.isNotEmpty;
  }
}
