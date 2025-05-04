import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:my_activities/screens/add_activity.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveActivity {
  //we need to add optional description to the activity
  final String title;
  String groupTitle;
  final DateTime startTime;
  final int prodSecs;
  final DateTime estimatedEndTime;
  final Category category;
  String? description;
  final int? folderId; // Add folderId to associate with a folder

  ActiveActivity({
    required this.prodSecs,
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.category,
    this.description,
    this.folderId,
  });

  String toStr() {
    // If title or groupTitle contains the @ delimiter, replace it with a - symbol
    final title = this.title.replaceAll('@', '-');
    final groupTitle = this.groupTitle.replaceAll('@', '-'); // for safety
    // Convert all the datetimes to milliseconds since epoch
    final startTime = this.startTime.millisecondsSinceEpoch;
    final estimatedEndTime = this.estimatedEndTime.millisecondsSinceEpoch;
    final description = this.description ?? '';
    final folderId = this.folderId?.toString() ?? 'null';
    return '$title,$groupTitle,$startTime,$estimatedEndTime,${category.index},$description,$prodSecs,$folderId@';
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
    final description =
        parts[5].isNotEmpty ? parts[5].substring(0, parts[5].length - 1) : '';
    final prodSecs = int.parse(parts[6].replaceAll('@', '').trim());
    final folderId =
        parts.length > 7 && parts[7] != 'null' ? int.parse(parts[7]) : null;
    return ActiveActivity(
      title: title,
      groupTitle: groupTitle,
      startTime: startTime,
      estimatedEndTime: estimatedEndTime,
      category: category,
      description: description,
      prodSecs: prodSecs,
      folderId: folderId,
    );
  }
}

//now lets convert the two main classes to providers for better state management
class SharedPrefActivities extends ChangeNotifier {
  List<ActiveActivity> activities = [];
  SharedPreferences? _prefs;
  // Add a map to store timers for each activity
  final Map<String, Timer> _timers = {};
  // Track paused status for each activity
  final Map<String, bool> _pausedStates = {};

  int get count => activities.length; // Add back the count getter

  // Helper method to get a unique key for each activity
  String _getActivityKey(ActiveActivity activity) {
    return '${activity.title}_${activity.groupTitle}';
  }

  void addActivity(ActiveActivity activity) {
    activity.groupTitle = activity.groupTitle.trim();
    activities.insert(0, activity);
    saveActivities();

    // Start timer for new activity
    _startActivityTimer(activity);

    notifyListeners();
  }

  void removeActivity(ActiveActivity activity) {
    final activityKey = _getActivityKey(activity);

    // Cancel timer if it exists
    if (_timers.containsKey(activityKey)) {
      _timers[activityKey]?.cancel();
      _timers.remove(activityKey);
      _pausedStates.remove(activityKey);
    }

    activities.remove(activity);
    saveActivities();
    notifyListeners();
  }

  void updateActivity(ActiveActivity activity) {
    final index = activities.indexWhere(
      (a) => a.title == activity.title && a.groupTitle == activity.groupTitle,
    );
    if (index != -1) {
      activities[index] = activity;
      saveActivities();
      notifyListeners();
    } else {
      log('Activity not found for update: ${activity.title}');
    }
  }

  // New methods to manage timers

  void _startActivityTimer(ActiveActivity activity) {
    final activityKey = _getActivityKey(activity);

    // Set as not paused by default
    _pausedStates[activityKey] = false;

    _timers[activityKey] = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Find activity in the list to get current state
      final index = activities.indexWhere(
        (a) => a.title == activity.title && a.groupTitle == activity.groupTitle,
      );

      if (index == -1) {
        // Activity not found, cancel timer
        timer.cancel();
        _timers.remove(activityKey);
        return;
      }

      // Check if activity is paused
      if (_pausedStates[activityKey] == true) {
        return; // Skip updating if paused
      }

      // Get current activity
      final currentActivity = activities[index];

      // Update productive seconds
      int newProdSecs = currentActivity.prodSecs + 3;

      // Create updated activity
      final updatedActivity = ActiveActivity(
        title: currentActivity.title,
        groupTitle: currentActivity.groupTitle,
        startTime: currentActivity.startTime,
        estimatedEndTime: currentActivity.estimatedEndTime,
        category: currentActivity.category,
        description: currentActivity.description,
        prodSecs: newProdSecs,
        folderId: currentActivity.folderId,
      );

      // Update in list
      activities[index] = updatedActivity;

      // Save and notify
      saveActivities();
      notifyListeners();
    });
  }

  void toggleActivityPauseState(ActiveActivity activity) {
    final activityKey = _getActivityKey(activity);

    // Toggle pause state
    bool isPaused = !(_pausedStates[activityKey] ?? true);
    _pausedStates[activityKey] = isPaused;

    // If timer doesn't exist and we're unpausing, start it
    if (!isPaused && !_timers.containsKey(activityKey)) {
      _startActivityTimer(activity);
    }

    notifyListeners();
  }

  bool isActivityPaused(ActiveActivity activity) {
    final activityKey = _getActivityKey(activity);
    return _pausedStates[activityKey] ?? true; // Default to paused
  }

  // Cleanup method
  void disposeAllTimers() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  // Optional: Method to simulate saving to shared preferences by converting to strings
  Future<void> saveActivities() async {
    //properly save the activities to shared preferences
    final List<String> savedActivities =
        activities.map((activity) => activity.toStr()).toList();
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
      activities =
          savedActivities.map((str) => ActiveActivity.fromStr(str)).toList();

      // Start timers for all activities
      for (var activity in activities) {
        _startActivityTimer(activity);
      }
    }

    notifyListeners();
  }
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
                      onDone: (doneActivity) async {
                        // Handle the done activity (e.g., save to a different provider)
                        DoneActivity doneActivity = DoneActivity(
                          title: activity.title,
                          groupTitle: activity.groupTitle,
                          startTime: activity.startTime,
                          estimatedEndTime: activity.estimatedEndTime,
                          finishTime: DateTime.now(),
                          category: activity.category,
                          description: activity.description,
                          prodSecs: activity.prodSecs,
                        );
                        await databaseActivitiesProvider.doneActivity(
                          doneActivity,
                        );
                        // You might want to add this to a DoneActivities provider
                        provider.removeActivity(activity);
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
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AddActivityScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        },
        label: const Text('Add Activity'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

//the code needs to be refactored in order to track the minutes that are spent on doing the productive work.
//lets introduce a pause/play button

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

class _ActivityCardState extends State<ActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _targetProgress = 0.0;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Only update the UI, not the actual timer logic
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateProgress();
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!mounted) return;

    final now = DateTime.now();
    final total = widget.activity.estimatedEndTime
        .difference(widget.activity.startTime)
        .inSeconds;
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
    setState(() {});

    _progressController.forward(from: 0);
  }

  void _handlePauseTimer() {
    // Use provider to toggle pause state
    final provider = Provider.of<SharedPrefActivities>(context, listen: false);
    provider.toggleActivityPauseState(widget.activity);
  }

  void _handleDone() {
    final doneActivity = DoneActivity(
      title: widget.activity.title,
      groupTitle: widget.activity.groupTitle,
      startTime: widget.activity.startTime,
      estimatedEndTime: widget.activity.estimatedEndTime,
      finishTime: DateTime.now(),
      category: widget.activity.category,
      description: widget.activity.description,
      prodSecs: widget.activity.prodSecs,
    );
    widget.onDone(doneActivity);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeLeft =
        widget.activity.estimatedEndTime.difference(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      //add a thin border to the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                    _targetProgress >= 1
                        ? themeProvider.themeData.colorScheme.error
                        : colorScheme.primary,
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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

                PausePlayButton(
                  onPressed: _handlePauseTimer,
                  activity: widget.activity,
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
                //add description if it exists
                if (widget.activity.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.activity.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PausePlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final ActiveActivity activity; // Add parameter for activity

  const PausePlayButton({
    super.key,
    required this.onPressed,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    // Get pause state from provider
    final provider = Provider.of<SharedPrefActivities>(context);
    final isPaused = provider.isActivityPaused(activity);

    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: AnimatedContainer(
          width: isPaused ? 134 : 66,
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border.all(
                color: isPaused
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 0.5,
              ),
              gradient: LinearGradient(
                colors: isPaused
                    ? [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primary
                      ]
                    : [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.surfaceContainerLowest,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 32,
              ),
              isPaused ? const SizedBox(width: 8) : const SizedBox(width: 0),
              Text(
                isPaused ? 'Resume' : '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
