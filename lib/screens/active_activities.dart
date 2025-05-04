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

  ActiveActivity({
    required this.prodSecs,
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.category,
    this.description,
  });

  String toStr() {
    // If title or groupTitle contains the @ delimiter, replace it with a - symbol
    final title = this.title.replaceAll('@', '-');
    final groupTitle = this.groupTitle.replaceAll('@', '-'); // for safety
    // Convert all the datetimes to milliseconds since epoch
    final startTime = this.startTime.millisecondsSinceEpoch;
    final estimatedEndTime = this.estimatedEndTime.millisecondsSinceEpoch;
    final description = this.description ?? '';
    return '$title,$groupTitle,$startTime,$estimatedEndTime,${category.index},$description,$prodSecs@';
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
    return ActiveActivity(
      title: title,
      groupTitle: groupTitle,
      startTime: startTime,
      estimatedEndTime: estimatedEndTime,
      category: category,
      description: description,
      prodSecs: prodSecs,
    );
  }
}

//now lets convert the two main classes to providers for better state management
class SharedPrefActivities extends ChangeNotifier {
  List<ActiveActivity> activities = [];
  SharedPreferences? _prefs;

  void addActivity(ActiveActivity activity) {
    // activities.add(activity);insert the activity to the front
    //remove the spacing on the right and left of the group title to avoid creation of new groups if the titles are the same
    log('title length of group before trim: ${activity.title.length}');
    log('title: ${activity.title}');
    activity.groupTitle = activity.groupTitle.trim();
    log('title length of group after trim: ${activity.title.length}');
    log('title: ${activity.title}');

    activities.insert(0, activity);
    saveActivities();
    notifyListeners();
  }

  void removeActivity(ActiveActivity activity) {
    activities.remove(activity);
    saveActivities();
    notifyListeners();
  }

  //update activity method after every 3 seconds and save to shared preferences

  void updateActivity(ActiveActivity activity) {
    //match based on the title and group title
    final index = activities.indexWhere(
      (a) => a.title == activity.title && a.groupTitle == activity.groupTitle,
    );
    if (index != -1) {
      activities[index] = activity;
      saveActivities();
      log('Activity updated: ${activity.title}');
      notifyListeners();
    } else {
      log('Activity not found for update: ${activity.title}');
    }
  }

  int get count => activities.length;

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
    log('Timer started for activity: ${widget.activity.title}');
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateProgress();
      // Update the productive seconds by incrementing by 3 seconds
      int newProdSecs = widget.activity.prodSecs + 3;

      log('New productive seconds: $newProdSecs');
      // Update the activity in the provider
      final updatedActivity = ActiveActivity(
        title: widget.activity.title,
        groupTitle: widget.activity.groupTitle,
        startTime: widget.activity.startTime,
        estimatedEndTime: widget.activity.estimatedEndTime,
        category: widget.activity.category,
        description: widget.activity.description,
        prodSecs: newProdSecs,
      );
      Provider.of<SharedPrefActivities>(context, listen: false)
          .updateActivity(updatedActivity);
    });
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
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    } else {
      _startTimer();
    }
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

class PausePlayButton extends StatefulWidget {
  final VoidCallback onPressed;
  const PausePlayButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<PausePlayButton> createState() => _PausePlayButtonState();
}

class _PausePlayButtonState extends State<PausePlayButton> {
  bool isPaused = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      //a stylish pause.play button
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            isPaused = !isPaused;
            log('isPaused: $isPaused');
          });
          widget.onPressed();
        },
        child: Container(
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
                        // Theme.of(context).colorScheme.primaryContainer
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 32,
          ),
        ),
      ),
    );
  }
}
