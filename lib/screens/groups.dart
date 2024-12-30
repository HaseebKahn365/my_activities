//doneActivities = databaseActivitiesProvider.activities;

/*
now we need to create beautiful cards which will display the following information
it will first sort all the done activities by finish time
then it will group the activities by groupTitle
then we will display the groupTitle and the length of the activities in that group
we will also display the most recent 3 activities of this group

 */

import 'package:flutter/material.dart';
import 'package:my_activities/providers/providers.dart';

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
      return DoneActivityCard(
        groupTitle: groupTitle,
        activityCount: activities.length,
        recentActivities: recentActivities,
      );
    }).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: groupCards,
      ),
    );
  }
}
