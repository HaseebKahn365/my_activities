//doneActivities = databaseActivitiesProvider.activities;

/*
now we need to create beautiful cards which will display the following information
it will first sort all the done activities by finish time
then it will group the activities by groupTitle
then we will display the groupTitle and the length of the activities in that group
we will also display the most recent 3 activities of this group

 */

import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:my_activities/providers/providers.dart';
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

          // Step 3: Build cards for each group
          final groupCards = groupedActivities.entries.map((entry) {
            final groupTitle = entry.key.isEmpty ? 'Extra' : entry.key;
            final activities = entry.value;
            final recentActivities = activities.take(3).toList(); // Most recent 3 activities
            return GestureDetector(
              child: DoneActivityCard(
                groupTitle: groupTitle,
                activityCount: activities.length,
                recentActivities: recentActivities,
              ),
              onTap: () {
                // Navigate to the group details screen using material routing
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => GroupDetailsScreen(groupTitle: groupTitle, activities: activities),
                ));
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

class GroupDetailsScreen extends StatelessWidget {
  final String groupTitle;
  final List<DoneActivity> activities;

  const GroupDetailsScreen({
    super.key,
    required this.groupTitle,
    required this.activities,
  });

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
                          await databaseActivitiesProvider.deleteActivitiesByGroupTitle(groupTitle);
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Activities: ${activities.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Last Updated: ${Jiffy.parse(activities.first.finishTime.toString()).fromNow()}',
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
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${activity.title} - ${Jiffy.parse(activity.finishTime.toString()).fromNow()}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            //time it took
                            Text(
                              '${activity.finishTime.difference(activity.startTime).inMinutes} min',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Started: ${Jiffy.parse(activity.startTime.toString()).format(pattern: 'dd/MM/yyyy               h:mm a')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              'Finished: ${Jiffy.parse(activity.finishTime.toString()).format(pattern: 'dd/MM/yyyy             h:mm a')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        //estimated end time
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Text(
                                  'expected: ${Jiffy.parse(activity.estimatedEndTime.toString()).fromNow()}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'at ${Jiffy.parse(activity.estimatedEndTime.toString()).format(pattern: 'h:mm a')}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
