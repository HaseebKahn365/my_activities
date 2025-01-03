//doneActivities = databaseActivitiesProvider.activities;

/*
now we need to create beautiful cards which will display the following information
it will first sort all the done activities by finish time
then it will group the activities by groupTitle
then we will display the groupTitle and the length of the activities in that group
we will also display the most recent 3 activities of this group

 */

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:my_activities/screens/add_activity.dart';
import 'package:provider/provider.dart';

class DoneActivityCard extends StatelessWidget {
  final String groupTitle;
  final int activityCount;
  final List<DoneActivity> recentActivities;

  const DoneActivityCard({
    super.key,
    required this.groupTitle,
    required this.activityCount,
    required this.recentActivities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '($activityCount ${activityCount == 1 ? 'activity' : 'activities'})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (recentActivities.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recentActivities.map((activity) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          activity.finishTime.toLocal().toString().split(' ')[0], // Display only the date
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class DoneActivitiesScreen extends StatelessWidget {
  const DoneActivitiesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort activities by finishTime

    return Scaffold(
      body: Consumer<DatabaseActivities>(
        builder: (context, databaseActivitiesProvider, child) {
          final sortedActivities = List<DoneActivity>.from(databaseActivitiesProvider.activities)..sort((a, b) => b.finishTime.compareTo(a.finishTime));

          // Step 2: Group activities by groupTitle
          final groupedActivities = <String, List<DoneActivity>>{};
          for (final activity in sortedActivities) {
            groupedActivities.putIfAbsent(activity.groupTitle, () => []).add(activity);
          }

          final groupCards = groupedActivities.entries.map((entry) {
            final groupTitle = entry.key.isEmpty ? 'Extra' : entry.key;
            final activities = entry.value;
            final recentActivities = activities.take(3).toList();
            return OpenContainer(
              clipBehavior: Clip.antiAlias,
              middleColor: Colors.transparent,
              openElevation: 0,
              closedElevation: 0,
              closedColor: Colors.transparent,
              openColor: Colors.transparent,
              closedBuilder: (context, openContainer) {
                return DoneActivityCard(
                  groupTitle: groupTitle,
                  activityCount: activities.length,
                  recentActivities: recentActivities,
                );
              },
              openBuilder: (context, closeContainer) {
                return GroupDetailsScreen(groupTitle: groupTitle, activities: activities);
              },
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(8),
            children: groupCards,
          );
        },
      ),
    );
  }
}

class GroupDetailsScreen extends StatefulWidget {
  final String groupTitle;
  final List<DoneActivity> activities;

  const GroupDetailsScreen({
    super.key,
    required this.groupTitle,
    required this.activities,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
//destroy the card of the activity that was deleted
  void destroyThisCard(DoneActivity activity) {
    setState(() {
      widget.activities.remove(activity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(groupTitle),
      //   elevation: 0,
      // ),
      body: Column(
        children: [
          const SizedBox(height: 48),
          GestureDetector(
            onLongPress: () {
              //show a dialog to delete all activities in this group
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete all activities?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          //delete all activities in this group
                          await databaseActivitiesProvider.deleteActivitiesByGroupTitle(widget.groupTitle);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Delete'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.themeData.colorScheme.onSurface.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Activities: ${widget.activities.length}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${Jiffy.parse(widget.activities.first.finishTime.toString()).fromNow()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.activities.length,
              itemBuilder: (context, index) {
                // Helper method for time information rows
                Widget buildTimeInfo(BuildContext context, IconData icon, String label, String time, Color iconColor) {
                  return Row(
                    children: [
                      Icon(icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                final activity = widget.activities[index];
                return GestureDetector(
                    //on long press, show a dialog to delete this activity
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete this activity?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  //delete this activity
                                  await databaseActivitiesProvider.deleteActivity(activity);
                                  Navigator.of(context).pop();
                                  destroyThisCard(activity);
                                },
                                child: const Text('Delete'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(
                          color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with title and duration
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                    softWrap: true,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${activity.finishTime.difference(activity.startTime).inMinutes} min',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Timestamps section
                            buildTimeInfo(
                              context,
                              Icons.play_circle_outlined,
                              'Started',
                              Jiffy.parse(activity.startTime.toString()).format(pattern: 'dd/MM/yyyy h:mm a'),
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),

                            buildTimeInfo(
                              context,
                              Icons.check_circle_outline,
                              'Finished',
                              Jiffy.parse(activity.finishTime.toString()).format(pattern: 'dd/MM/yyyy h:mm a'),
                              Colors.green,
                            ),
                            const SizedBox(height: 12),

                            buildTimeInfo(
                              context,
                              Icons.access_time,
                              'Expected',
                              '${Jiffy.parse(activity.estimatedEndTime.toString()).format(pattern: 'h:mm a')} (${Jiffy.parse(activity.estimatedEndTime.toString()).fromNow()})',
                              Theme.of(context).colorScheme.primary,
                            ),

                            if (activity.description?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              // Description section
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Description',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          activity.description!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Category section at bottom
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    activity.category.toString(),
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      //lets add a slight floating effect to the card using flutter_animate
                    ));
              },
            ),
          ),
        ],
      ),
      //add a floating action button to add a new activity but with the groupTitle already filled
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddActivityScreen(groupTitle: widget.groupTitle),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                var begin = const Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.linearToEaseOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
              reverseTransitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        label: const Text('Add Activity'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
