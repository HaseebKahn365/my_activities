import 'package:flutter_test/flutter_test.dart';

/*
This entire application is a custom activity tracker that is mainly intended for tracking simple workouts and other activities in a simple way.
Here is what the activity should look like

// Let's implement these classes but instead of using local storage we immediately affect the lists to make the testing easier
*/

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

class SharedPrefActivities {
  List<ActiveActivity> activities = [];

  void addActivity(ActiveActivity activity) {
    activities.add(activity);
  }

  void removeActivity(ActiveActivity activity) {
    activities.remove(activity);
  }

  int get count => activities.length;

  // Optional: Method to simulate saving to shared preferences by converting to strings
  List<String> saveActivities() {
    return activities.map((activity) => activity.toStr()).toList();
  }

  // Optional: Method to simulate loading from shared preferences by parsing strings
  void loadActivities(List<String> savedActivities) {
    activities = savedActivities.map((str) => ActiveActivity.fromStr(str)).toList();
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

class DatabaseActivities {
  List<DoneActivity> activities = [];

  void doneActivity(DoneActivity activity) {
    activities.add(activity);
  }

  void removeActivity(DoneActivity activity) {
    activities.remove(activity);
  }

  int get count => activities.length;
}

void main() {
  group('ActiveActivity String Conversion', () {
    late ActiveActivity activity1;
    late ActiveActivity activity2;

    setUp(() {
      activity1 = ActiveActivity(
        title: 'Test@Activity',
        groupTitle: 'Group@1',
        startTime: DateTime(2024, 1, 1, 9, 0),
        estimatedEndTime: DateTime(2024, 1, 1, 10, 0),
        category: Category.w,
      );

      activity2 = ActiveActivity(
        title: 'Another@Test',
        groupTitle: 'Group@2',
        startTime: DateTime(2024, 1, 2, 14, 30),
        estimatedEndTime: DateTime(2024, 1, 2, 15, 30),
        category: Category.m,
      );
    });

    test('Convert activities to strings and back', () {
      final str1 = activity1.toStr();
      print('${str1}is a string for activity1 which is active');
      final str2 = activity2.toStr();
      print('${str2}is a string for activity2 which is active');

      final decoded1 = ActiveActivity.fromStr(str1);
      final decoded2 = ActiveActivity.fromStr(str2);

      expect(decoded1.title, equals(activity1.title));
      expect(decoded1.groupTitle, equals(activity1.groupTitle));
      expect(decoded1.startTime, equals(activity1.startTime));
      expect(decoded1.estimatedEndTime, equals(activity1.estimatedEndTime));
      expect(decoded1.category, equals(activity1.category));

      expect(decoded2.title, equals(activity2.title));
      expect(decoded2.groupTitle, equals(activity2.groupTitle));
      expect(decoded2.startTime, equals(activity2.startTime));
      expect(decoded2.estimatedEndTime, equals(activity2.estimatedEndTime));
      expect(decoded2.category, equals(activity2.category));
    });

    test('Handle special characters in string conversion', () {
      final activity = ActiveActivity(
        title: 'Test@With@Multiple@Symbols',
        groupTitle: 'Group@With@Symbols',
        startTime: DateTime(2024, 1, 1),
        estimatedEndTime: DateTime(2024, 1, 2),
        category: Category.s,
      );

      final decoded = ActiveActivity.fromStr(activity.toStr());
      expect(decoded.title, equals(activity.title));
      expect(decoded.groupTitle, equals(activity.groupTitle));
    });
  });

  group('SharedPrefActivities List Operations', () {
    late SharedPrefActivities sharedPref;
    late ActiveActivity activity1;
    late ActiveActivity activity2;

    setUp(() {
      sharedPref = SharedPrefActivities();
      activity1 = ActiveActivity(
        title: 'Activity 1',
        groupTitle: 'Group 1',
        startTime: DateTime(2024, 1, 1),
        estimatedEndTime: DateTime(2024, 1, 2),
        category: Category.s,
      );
      activity2 = ActiveActivity(
        title: 'Activity 2',
        groupTitle: 'Group 2',
        startTime: DateTime(2024, 1, 1),
        estimatedEndTime: DateTime(2024, 1, 2),
        category: Category.l,
      );
    });

    test('Add activities to list', () {
      expect(sharedPref.count, equals(0));

      sharedPref.addActivity(activity1);
      expect(sharedPref.count, equals(1));

      sharedPref.addActivity(activity2);
      expect(sharedPref.count, equals(2));
    });

    test('Remove activities from list', () {
      sharedPref.addActivity(activity1);
      sharedPref.addActivity(activity2);

      sharedPref.removeActivity(activity1);
      expect(sharedPref.count, equals(1));
      expect(sharedPref.activities.contains(activity2), isTrue);
    });
  });

  group('DatabaseActivities List Operations', () {
    late DatabaseActivities database;
    late DoneActivity activity1;
    late DoneActivity activity2;

    setUp(() {
      database = DatabaseActivities();
      activity1 = DoneActivity(
        title: 'Done 1',
        groupTitle: 'Group 1',
        startTime: DateTime(2024, 1, 1),
        estimatedEndTime: DateTime(2024, 1, 2),
        finishTime: DateTime(2024, 1, 2),
        category: Category.m,
      );
      activity2 = DoneActivity(
        title: 'Done 2',
        groupTitle: 'Group 2',
        startTime: DateTime(2024, 1, 1),
        estimatedEndTime: DateTime(2024, 1, 2),
        finishTime: DateTime(2024, 1, 2),
        category: Category.l,
      );
    });

    test('Add activities to database', () {
      expect(database.count, equals(0));

      database.doneActivity(activity1);
      expect(database.count, equals(1));

      database.doneActivity(activity2);
      expect(database.count, equals(2));
    });

    test('Remove activities from database', () {
      database.doneActivity(activity1);
      database.doneActivity(activity2);

      database.removeActivity(activity1);
      expect(database.count, equals(1));
      expect(database.activities.contains(activity2), isTrue);
    });
  });

  group('Saving Multiple Activities', () {
    late SharedPrefActivities sharedPref;
    late ActiveActivity sharedActivity1;
    late ActiveActivity sharedActivity2;

    late DatabaseActivities database;
    late DoneActivity dbActivity1;
    late DoneActivity dbActivity2;

    setUp(() {
      // Initialize SharedPrefActivities and Activities
      sharedPref = SharedPrefActivities();
      sharedActivity1 = ActiveActivity(
        title: 'Shared Activity 1',
        groupTitle: 'Shared Group 1',
        startTime: DateTime(2024, 2, 1, 8, 0),
        estimatedEndTime: DateTime(2024, 2, 1, 9, 0),
        category: Category.w,
      );
      sharedActivity2 = ActiveActivity(
        title: 'Shared Activity 2',
        groupTitle: 'Shared Group 2',
        startTime: DateTime(2024, 2, 2, 10, 0),
        estimatedEndTime: DateTime(2024, 2, 2, 11, 0),
        category: Category.m,
      );

      // Initialize DatabaseActivities and Activities
      database = DatabaseActivities();
      dbActivity1 = DoneActivity(
        title: 'DB Activity 1',
        groupTitle: 'DB Group 1',
        startTime: DateTime(2024, 3, 1, 7, 0),
        estimatedEndTime: DateTime(2024, 3, 1, 8, 0),
        finishTime: DateTime(2024, 3, 1, 8, 30),
        category: Category.l,
      );
      dbActivity2 = DoneActivity(
        title: 'DB Activity 2',
        groupTitle: 'DB Group 2',
        startTime: DateTime(2024, 3, 2, 12, 0),
        estimatedEndTime: DateTime(2024, 3, 2, 13, 0),
        finishTime: DateTime(2024, 3, 2, 13, 30),
        category: Category.s,
      );
    });

    test('Save and parse SharedPrefActivities correctly', () {
      // Add activities to SharedPrefActivities
      sharedPref.addActivity(sharedActivity1);
      sharedPref.addActivity(sharedActivity2);
      expect(sharedPref.count, equals(2));

      // Simulate saving to shared preferences
      List<String> savedData = sharedPref.saveActivities();
      expect(savedData.length, equals(2));

      // Clear current activities
      sharedPref.activities.clear();
      expect(sharedPref.count, equals(0));

      // Simulate loading from shared preferences
      sharedPref.loadActivities(savedData);
      expect(sharedPref.count, equals(2));

      // Verify that the loaded activities match the original ones
      final loadedActivity1 = sharedPref.activities[0];
      final loadedActivity2 = sharedPref.activities[1];

      expect(loadedActivity1.title, equals(sharedActivity1.title));
      expect(loadedActivity1.groupTitle, equals(sharedActivity1.groupTitle));
      expect(loadedActivity1.startTime, equals(sharedActivity1.startTime));
      expect(loadedActivity1.estimatedEndTime, equals(sharedActivity1.estimatedEndTime));
      expect(loadedActivity1.category, equals(sharedActivity1.category));

      expect(loadedActivity2.title, equals(sharedActivity2.title));
      expect(loadedActivity2.groupTitle, equals(sharedActivity2.groupTitle));
      expect(loadedActivity2.startTime, equals(sharedActivity2.startTime));
      expect(loadedActivity2.estimatedEndTime, equals(sharedActivity2.estimatedEndTime));
      expect(loadedActivity2.category, equals(sharedActivity2.category));
    });

    test('Add multiple activities to DatabaseActivities', () {
      // Add activities to DatabaseActivities
      database.doneActivity(dbActivity1);
      database.doneActivity(dbActivity2);
      expect(database.count, equals(2));

      // Verify that the activities are correctly added
      expect(database.activities[0].title, equals(dbActivity1.title));
      expect(database.activities[1].title, equals(dbActivity2.title));
    });
  });
}
