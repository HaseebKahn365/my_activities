import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:my_activities/screens/active_activities.dart';
import 'package:my_activities/screens/homepage.dart';
import 'package:path/path.dart' as pathProvider;
import 'package:sqflite/sqflite.dart';

enum Category { w, s, m, l }

final themeProvider = ThemeProvider();
final sharedPrefActivitiesProvider = SharedPrefActivities();
final databaseActivitiesProvider = DatabaseActivities();

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

class DatabaseActivities extends ChangeNotifier {
  static Database? _database;
  List<DoneActivity> activities = [];

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = pathProvider.join(await getDatabasesPath(), 'activities.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            groupTitle TEXT NOT NULL,
            startTime TEXT NOT NULL,
            estimatedEndTime TEXT NOT NULL,
            finishTime TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Add a new activity to the database
  Future<void> doneActivity(DoneActivity activity) async {
    final db = await database;
    await db.insert(
      'activities',
      {
        'title': activity.title,
        'groupTitle': activity.groupTitle,
        'startTime': activity.startTime.toIso8601String(),
        'estimatedEndTime': activity.estimatedEndTime.toIso8601String(),
        'finishTime': activity.finishTime.toIso8601String(),
        'category': activity.category.toString(), // Using .name to get the enum value as string
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('Activity added to database');
    printActivities();

    activities.add(activity);
    notifyListeners();
  }

  // Load all activities from the database
  Future<void> loadFromDb() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('activities');

    activities = maps
        .map((map) => DoneActivity(
              title: map['title'],
              groupTitle: map['groupTitle'],
              startTime: DateTime.parse(map['startTime']),
              estimatedEndTime: DateTime.parse(map['estimatedEndTime']),
              finishTime: DateTime.parse(map['finishTime']),
              category: Category.values.firstWhere(
                (e) => e.name == map['category'],
                orElse: () => Category.w, // Default to 'w' if not found
              ),
            ))
        .toList();
    printActivities();

    notifyListeners();
  }

  Category getCategory(String category) {
    switch (category) {
      case 'w':
        return Category.w;

      case 's':
        return Category.s;
      case 'm':
        return Category.m;

      default:
        return Category.w;
    }
  }

  // Save current activities to database (useful for bulk updates)
  Future<void> saveToDb() async {
    final db = await database;
    await db.delete('activities'); // Clear existing data

    for (var activity in activities) {
      await db.insert(
        'activities',
        {
          'title': activity.title,
          'groupTitle': activity.groupTitle,
          'startTime': activity.startTime.toIso8601String(),
          'estimatedEndTime': activity.estimatedEndTime.toIso8601String(),
          'finishTime': activity.finishTime.toIso8601String(),
          'category': activity.category.name, // Using .name to get the enum value as string
        },
      );
    }
  }

  // Delete an activity
  Future<void> deleteActivity(DoneActivity activity) async {
    final db = await database;
    await db.delete(
      'activities',
      where: 'title = ? AND startTime = ?',
      whereArgs: [activity.title, activity.startTime.toIso8601String()],
    );

    activities.removeWhere((a) => a.title == activity.title && a.startTime == activity.startTime);
    notifyListeners();
  }

  // Get activity count
  int get count => activities.length;

  // Query activities by category
  Future<List<DoneActivity>> getActivitiesByCategory(Category category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'category = ?',
      whereArgs: [category.name],
    );

    return maps
        .map((map) => DoneActivity(
              title: map['title'],
              groupTitle: map['groupTitle'],
              startTime: DateTime.parse(map['startTime']),
              estimatedEndTime: DateTime.parse(map['estimatedEndTime']),
              finishTime: DateTime.parse(map['finishTime']),
              category: getCategory(map['category']),
            ))
        .toList();
  }

  //method to print the activities in the database
  void printActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    log(maps.toString());
  }

  //delete all activities by group title
  Future<void> deleteActivitiesByGroupTitle(String groupTitle) async {
    log('Deleting activities with group title: $groupTitle');
    final db = await database;
    await db.delete(
      'activities',
      where: 'groupTitle = ?',
      whereArgs: [groupTitle],
    );

    activities.removeWhere((a) => a.groupTitle == groupTitle);
    notifyListeners();
  }
}
