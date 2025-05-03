import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:my_activities/screens/active_activities.dart';
import 'package:my_activities/screens/homepage.dart';
import 'package:path/path.dart' as pathProvider;
import 'package:sqflite/sqflite.dart';

/*
Here are the new features that I want to add:
instead of just tracking the end time. we need to track the minutes spent on doing productive work. 
we should be able to pause the activity mid-work so that we don't increment the minutes.

another feature that we want to add is being able to put groups into folders.
There should be a root folder containing subfolders or groups.

groups are not folders. groups represent a collection of activities in a project.

while folders allow for a more flexible organization, groups allow for a more structured approach.


refactor the databaseActivities helper class to consider the minutes.
this refactor should not cause errors in the exisiting structure

also create a new attribute called parent folder id which will allow us to put all the activities in a group. 

create a table in the database called folders which willl not only contain the folder name but also an attribute called parent folder id which will allow us to put folders into folders.

for now we should implement these methods and then later we will add methods to put groups into folders and folders into folders

 */

enum Category { w, s, m, l }

final themeProvider = ThemeProvider();
final sharedPrefActivitiesProvider = SharedPrefActivities();
final databaseActivitiesProvider = DatabaseActivities();

//now we need to also take and optional parameter of description for done activity into account

class DoneActivity {
  final String title;
  final String groupTitle;
  int minutesSpent;
  final DateTime startTime;
  final DateTime estimatedEndTime;
  final DateTime finishTime;
  final Category category;
  final String? description;
  final int? parentFolderId;

  DoneActivity({
    required this.title,
    required this.groupTitle,
    required this.startTime,
    required this.estimatedEndTime,
    required this.finishTime,
    required this.category,
    this.description,
    this.minutesSpent = 0,
    this.parentFolderId,
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
      version: 3, // Increment version number
      onCreate: (Database db, int version) async {
        // Create folders table
        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parentFolderId INTEGER,
            FOREIGN KEY (parentFolderId) REFERENCES folders(id)
          )
        ''');

        // Create activities table with new columns
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
            minutesSpent INTEGER NOT NULL DEFAULT 0,
            parentFolderId INTEGER,
            FOREIGN KEY (parentFolderId) REFERENCES folders(id)
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        log('Upgrading database from version $oldVersion to $newVersion');
        if (oldVersion < 2) {
          // Add description column to existing table
          await db
              .execute('ALTER TABLE activities ADD COLUMN description TEXT');
        }
        if (oldVersion < 3) {
          // Create folders table
          await db.execute('''
            CREATE TABLE folders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              parentFolderId INTEGER,
              FOREIGN KEY (parentFolderId) REFERENCES folders(id)
            )
          ''');

          // Create a temporary table with the new schema
          await db.execute('''
            CREATE TABLE activities_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              groupTitle TEXT NOT NULL,
              startTime TEXT NOT NULL,
              estimatedEndTime TEXT NOT NULL,
              finishTime TEXT NOT NULL,
              category TEXT NOT NULL,
              description TEXT,
              minutesSpent INTEGER NOT NULL DEFAULT 0,
              parentFolderId INTEGER,
              FOREIGN KEY (parentFolderId) REFERENCES folders(id)
            )
          ''');

          // Copy data from old table to new table
          await db.execute('''
            INSERT INTO activities_new 
            SELECT id, title, groupTitle, startTime, estimatedEndTime, finishTime, 
                   category, description, 0 as minutesSpent, 1 as parentFolderId
            FROM activities
          ''');

          // Drop the old table
          await db.execute('DROP TABLE activities');

          // Rename the new table to the original name
          await db.execute('ALTER TABLE activities_new RENAME TO activities');

          // Create a folder called root if it doesn't exist
          await db.execute(
            '''INSERT OR IGNORE INTO folders (id, name) VALUES (1, 'root')''',
          );
        }
      },
    );
  }

//! methods for debugging

//logging activities in db for cheching their parent folder:
  Future<void> logParents() async {
    log('Here are the activites and the names of the folder to which they belong');
    final db = await database;
    final List<Map<String, dynamic>> activitiesInDb =
        await db.query('activities');
    for (var activity in activitiesInDb) {
      final parentFolder = await db.query(
        'folders',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [activity['parentFolderId']],
      );
      final parentFolderName =
          parentFolder.isNotEmpty ? parentFolder.first['name'] : 'root';
      log('Activity: ${activity['title']}, Parent Folder ID: ${activity['parentFolderId']}, Parent Folder Name: $parentFolderName');
    }
  }

  //method to get all folders on the root level
  Future<List<Map<String, dynamic>>> getRootFolders() async {
    final db = await database;
    return await db.query('folders', where: 'parentFolderId IS NULL');
  }

  //method to get all folders in a folder
  Future<List<Map<String, dynamic>>> getFoldersInFolder(int folderId) async {
    final db = await database;
    return await db
        .query('folders', where: 'parentFolderId = ?', whereArgs: [folderId]);
  }

  //method to get all activities in a folder
  Future<List<Map<String, dynamic>>> getActivitiesInFolder(int folderId) async {
    final db = await database;
    return await db.query('activities',
        where: 'parentFolderId = ?', whereArgs: [folderId]);
  }

  //method to get all activities in the database
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    final db = await database;
    return await db.query('activities');
  }

  //method to get all folders in the database
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final db = await database;
    return await db.query('folders');
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
        'minutesSpent': activity.minutesSpent,
        'parentFolderId': activity.parentFolderId,
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
              minutesSpent: map['minutesSpent'] ?? 0,
              parentFolderId: map['parentFolderId'],
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
              minutesSpent: map['minutesSpent'] ?? 0,
              parentFolderId: map['parentFolderId'],
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

  // Folder operations
  Future<int> createFolder(String name, {int? parentFolderId}) async {
    final db = await database;
    final id = await db.insert(
      'folders',
      {
        'name': name,
        'parentFolderId': parentFolderId,
      },
    );
    notifyListeners();
    return id;
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    // First delete all activities in this folder
    await db.delete(
      'activities',
      where: 'parentFolderId = ?',
      whereArgs: [folderId],
    );
    // Then delete the folder itself
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getFolders({int? parentFolderId}) async {
    final db = await database;
    return await db.query(
      'folders',
      where: parentFolderId == null
          ? 'parentFolderId IS NULL'
          : 'parentFolderId = ?',
      whereArgs: parentFolderId == null ? [] : [parentFolderId],
    );
  }

  Future<void> updateActivityMinutes(
      DoneActivity activity, int minutesSpent) async {
    final db = await database;
    await db.update(
      'activities',
      {'minutesSpent': minutesSpent},
      where: 'title = ? AND groupTitle = ? AND estimatedEndTime = ?',
      whereArgs: [
        activity.title,
        activity.groupTitle,
        activity.estimatedEndTime.toIso8601String()
      ],
    );

    // Update the local activity
    final index = activities.indexWhere((act) =>
        act.title == activity.title &&
        act.groupTitle == activity.groupTitle &&
        act.estimatedEndTime.isAtSameMomentAs(activity.estimatedEndTime));
    if (index != -1) {
      activities[index] = DoneActivity(
        title: activity.title,
        groupTitle: activity.groupTitle,
        startTime: activity.startTime,
        estimatedEndTime: activity.estimatedEndTime,
        finishTime: activity.finishTime,
        category: activity.category,
        description: activity.description,
        minutesSpent: minutesSpent,
        parentFolderId: activity.parentFolderId,
      );
    }
    notifyListeners();
  }

  Future<void> moveActivityToFolder(
      DoneActivity activity, int? folderId) async {
    final db = await database;
    await db.update(
      'activities',
      {'parentFolderId': folderId},
      where: 'title = ? AND groupTitle = ? AND estimatedEndTime = ?',
      whereArgs: [
        activity.title,
        activity.groupTitle,
        activity.estimatedEndTime.toIso8601String()
      ],
    );

    // Update the local activity
    final index = activities.indexWhere((act) =>
        act.title == activity.title &&
        act.groupTitle == activity.groupTitle &&
        act.estimatedEndTime.isAtSameMomentAs(activity.estimatedEndTime));
    if (index != -1) {
      activities[index] = DoneActivity(
        title: activity.title,
        groupTitle: activity.groupTitle,
        startTime: activity.startTime,
        estimatedEndTime: activity.estimatedEndTime,
        finishTime: activity.finishTime,
        category: activity.category,
        description: activity.description,
        minutesSpent: activity.minutesSpent,
        parentFolderId: folderId,
      );
    }
    notifyListeners();
  }
}
