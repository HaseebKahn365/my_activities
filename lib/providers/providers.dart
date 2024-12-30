import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    String path = join(await getDatabasesPath(), 'activities.db');
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
        'category': activity.category.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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
              category: _stringToCategory(map['category']),
            ))
        .toList();

    notifyListeners();
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
          'category': activity.category.toString(),
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

  // Helper method to convert string to Category enum
  Category _stringToCategory(String categoryString) {
    // You'll need to implement this based on your Category enum
    // Example implementation:
    return Category.values.firstWhere(
      (e) => e.toString() == categoryString,
      orElse: () => Category.values.first, // default value
    );
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
