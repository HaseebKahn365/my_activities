import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:my_activities/screens/active_activities.dart';
import 'package:my_activities/screens/folder_screen.dart';
import 'package:my_activities/screens/homepage.dart';
import 'package:path/path.dart' as pathProvider;
import 'package:sqflite/sqflite.dart';

enum Category { w, s, m, l }

final themeProvider = ThemeProvider();
final sharedPrefActivitiesProvider = SharedPrefActivities();
final databaseActivitiesProvider = DatabaseActivities();
final folderProvider = FolderProvider();

//now we need to also take and optional parameter of description for done activity into account

class DoneActivity {
  final String title;
  final String groupTitle;
  final DateTime startTime;
  final DateTime estimatedEndTime;
  final DateTime finishTime;
  final Category category;
  final String? description;
  final int prodSecs;
  int? folderId; // Add folderId to associate with a folder

  DoneActivity({
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.finishTime,
    required this.category,
    this.description,
    required this.prodSecs,
    this.folderId,
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
      version: 2, // Increment version number
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            groupTitle TEXT NOT NULL,
            startTime TEXT NOT NULL,
            estimatedEndTime TEXT NOT NULL,
            finishTime TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            prodSecs INTEGER NOT NULL,
            folderId INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parentFolderId INTEGER,
            isPinned INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db
              .execute('ALTER TABLE activities ADD COLUMN folderId INTEGER');
          await db.execute('''
            CREATE TABLE folders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              parentFolderId INTEGER,
              isPinned INTEGER NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  //method to find a folder path by its id
  Future<List<Map<String, dynamic>>> getFolderPathById(int folderId) async {
    final db = await database;
    List<Map<String, dynamic>> folderPath = [];

    // ignore: unnecessary_null_comparison
    while (folderId != null) {
      final List<Map<String, dynamic>> result = await db.query(
        'folders',
        where: 'id = ?',
        whereArgs: [folderId],
      );
      if (result.isNotEmpty) {
        folderPath.add(result.first);
        folderId = result.first['parentFolderId'] ?? 'Root';
      } else {
        break;
      }
    }

    return folderPath.reversed.toList(); // Reverse to get the correct order
  }

  // Add a new activity to the database
  Future<void> doneActivity(DoneActivity activity) async {
    log('Description: ${activity.description}');
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
        'description': activity.description,
        'prodSecs': activity.prodSecs,
        'folderId': activity.folderId,
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
                orElse: () => Category.w,
              ),
              description: map['description'],
              prodSecs: map['prodSecs'] ?? 0,
              folderId: map['folderId'],
            ))
        .toList();
    printActivities();

    notifyListeners();
  }

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
              description: map['description'],
              prodSecs: map['prodSecs'],
              folderId: map['folderId'],
            ))
        .toList();
  }

  //get category from string
  Category getCategory(String category) {
    switch (category) {
      case 'w':
        return Category.w;
      case 's':
        return Category.s;
      case 'm':
        return Category.m;
      case 'l':
        return Category.l;
      default:
        return Category.w;
    }
  }

  //drop x activity into y folder
  Future<void> moveActivityToFolder(DoneActivity activity, int folderId) async {
    log('Moving activity: ${activity.title} to folderId: $folderId');
    final db = await database;
    await db.update(
      'activities',
      {'folderId': folderId},
      where: 'title = ? AND groupTitle = ?',
      whereArgs: [activity.title, activity.groupTitle],
    );
    activity.folderId = folderId; // Update the activity's folderId
    notifyListeners();
  }

  // Print all activities

  void printActivities() {
    for (var activity in activities) {
      log('Activity: ${activity.title}');
    }
  }

  //delete activities by group title
  Future<void> deleteActivitiesByGroupTitle(String groupTitle) async {
    log('Deleting activities with group title: $groupTitle');
    final db = await database;
    await db
        .delete('activities', where: 'groupTitle = ?', whereArgs: [groupTitle]);
    activities.removeWhere((activity) => activity.groupTitle == groupTitle);
    notifyListeners();
  }

  Future<void> deleteActivity(DoneActivity activity) async {
    log('Deleting activity: ${activity.title}');
    final db = await database;
    await db.delete('activities',
        where: 'groupTitle = ? AND title = ? AND estimatedEndTime = ?',
        whereArgs: [
          activity.groupTitle,
          activity.title,
          activity.estimatedEndTime.toIso8601String()
        ]);
    activities.removeWhere((act) =>
        act.title == activity.title &&
        act.groupTitle == activity.groupTitle &&
        act.estimatedEndTime.isAtSameMomentAs(activity.estimatedEndTime));
    notifyListeners();
  }

  //! methods for folders

  //dellete all folders
  Future<void> deleteAllFolders() async {
    final db = await database;
    await db.delete('folders');
    notifyListeners();
  }

  Future<void> createFolder(String name, {int? parentFolderId}) async {
    final db = await database;
    await db.insert('folders', {
      'name': name,
      'parentFolderId': parentFolderId,
      'isPinned': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    await db.delete('activities', where: 'folderId = ?', whereArgs: [folderId]);
    notifyListeners();
  }

  Future<void> renameFolder(int folderId, String newName) async {
    final db = await database;
    await db.update('folders',
        {'name': newName, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [folderId]);
    notifyListeners();
  }

  Future<void> pinFolder(int folderId, bool isPinned) async {
    final db = await database;
    await db.update(
        'folders',
        {
          'isPinned': isPinned ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [folderId]);
    notifyListeners();
  }
}
