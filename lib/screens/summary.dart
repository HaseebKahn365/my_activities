/*

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


    on this screen we are going to use the fl ch
           



 */