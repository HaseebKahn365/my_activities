import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my_activities/providers/add_activity.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Category { w, s, m, l }

class ActiveActivity {
  final String title;
  final String groupTitle;
  final DateTime startTime;
  final DateTime estimatedEndTime;
  final Category category;

  ActiveActivity({
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.category,
  });

  String toStr() {
    // If title or groupTitle contains the @ delimiter, replace it with a - symbol
    final title = this.title.replaceAll('@', '-');
    final groupTitle = this.groupTitle.replaceAll('@', '-'); // for safety
    // Convert all the datetimes to milliseconds since epoch
    final startTime = this.startTime.millisecondsSinceEpoch;
    final estimatedEndTime = this.estimatedEndTime.millisecondsSinceEpoch;
    return '$title,$groupTitle,$startTime,$estimatedEndTime,${category.index}@';
  }

  // Factory constructor for creating ActiveActivity from string making sure to use @ as the delimiter
  factory ActiveActivity.fromStr(String str) {
    final parts = str.split(',');
    final title = parts[0].replaceAll('-', '@');
    final groupTitle = parts[1].replaceAll('-', '@');
    final startMSE = int.parse(parts[2]);
    final endMSE = int.parse(parts[3]);
    final startTime = DateTime.fromMillisecondsSinceEpoch(startMSE);
    final estimatedEndTime = DateTime.fromMillisecondsSinceEpoch(endMSE);
    final category = Category.values[int.parse(parts[4].substring(0, 1))];
    return ActiveActivity(
      title: title,
      groupTitle: groupTitle,
      startTime: startTime,
      estimatedEndTime: estimatedEndTime,
      category: category,
    );
  }
}

//now lets convert the two main classes to providers for better state management
class SharedPrefActivities extends ChangeNotifier {
  List<ActiveActivity> activities = [];
  SharedPreferences? _prefs;

  void addActivity(ActiveActivity activity) {
    // activities.add(activity);insert the activity to the front
    activities.insert(0, activity);
    saveActivities();
    notifyListeners();
  }

  void removeActivity(ActiveActivity activity) {
    activities.remove(activity);
    saveActivities();
    notifyListeners();
  }

  int get count => activities.length;

  // Optional: Method to simulate saving to shared preferences by converting to strings
  Future<void> saveActivities() async {
    //properly save the activities to shared preferences
    final List<String> savedActivities = activities.map((activity) => activity.toStr()).toList();
    log('Saved activities: $savedActivities');
    await _prefs!.setStringList('activities', savedActivities);
  }

  // Optional: Method to simulate loading from shared preferences by parsing strings
  Future<void> loadActivities() async {
    //properly load the activities from shared preferences
    _prefs = await SharedPreferences.getInstance();
    final List<String>? savedActivities = _prefs!.getStringList('activities');
    log('Loaded activities: $savedActivities');
    if (savedActivities != null) {
      activities = savedActivities.map((str) => ActiveActivity.fromStr(str)).toList();
    }

    notifyListeners();
  }
}

class DoneActivity {
  final String title;
  final String groupTitle;
  final DateTime startTime;
  final DateTime estimatedEndTime;
  final DateTime finishTime;
  final Category category;

  DoneActivity({
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.finishTime,
    required this.category,
  });
}

class ActiveActivitiesScreen extends StatelessWidget {
  const ActiveActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Consumer<SharedPrefActivities>(
              builder: (context, provider, child) {
                if (provider.activities.isEmpty) {
                  return Center(
                    child: Text(
                      'No active activities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: provider.count,
                  itemBuilder: (context, index) {
                    final activity = provider.activities[index];
                    return ActivityCard(
                      activity: activity,
                      onRemove: () => provider.removeActivity(activity),
                      onDone: (doneActivity) {
                        // Handle the done activity (e.g., save to a different provider)
                        provider.removeActivity(activity);
                        // You might want to add this to a DoneActivities provider
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddActivityScreen()),
          );
        },
        label: const Text('Add Activity'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class ActivityCard extends StatefulWidget {
  final ActiveActivity activity;
  final VoidCallback onRemove;
  final Function(DoneActivity) onDone;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onRemove,
    required this.onDone,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _targetProgress = 0.0;
  final int neeww = 32;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // Smooth animation duration
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateProgress();
    });
  }

  void _updateProgress() {
    if (!mounted) return;

    final now = DateTime.now();
    final total = widget.activity.estimatedEndTime.difference(widget.activity.startTime).inSeconds;
    final elapsed = now.difference(widget.activity.startTime).inSeconds;

    _targetProgress = elapsed / total;
    if (_targetProgress > 1) _targetProgress = 1;

    // Update the animation
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: _targetProgress,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _progressController.forward(from: 0);
  }

  void _handleDone() {
    final doneActivity = DoneActivity(
      title: widget.activity.title,
      groupTitle: widget.activity.groupTitle,
      startTime: widget.activity.startTime,
      estimatedEndTime: widget.activity.estimatedEndTime,
      finishTime: DateTime.now(),
      category: widget.activity.category,
    );
    widget.onDone(doneActivity);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeLeft = widget.activity.estimatedEndTime.difference(DateTime.now());

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _targetProgress >= 1 ? themeProvider.themeData.colorScheme.error : colorScheme.primary,
                  ),
                  minHeight: 6,
                );
              },
            ),
          ),
          // Rest of the card content remains the same
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.activity.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.activity.groupTitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.activity.category.toString().split('.').last,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Time left: ${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m',
                  style: TextStyle(
                    color: _targetProgress >= 1 ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onRemove,
                      child: const Text('Remove'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _handleDone,
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
