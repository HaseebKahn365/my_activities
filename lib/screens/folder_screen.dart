/*
Creating a folder provider that will simplify the process of creating, combining, deleting, renaming folders and creating subfolders.
along with these we should also be able to pin folders.
once we are inside a folder we should be able to create activity from inside the folder for convenience.
we should also refactor the add activity screen to be able to add activity to a folder.
THERE SHOULD BE A FLOATING ACTION BUTTON TO CREATE ACTIVITY FROM INSIDE THE FOLDER.


Logical structure:
Folder
-name
-subfolders
-activities


Only folders can be pinned maintained in a simple list.


Refactors:
we need to modify the active activity provider to be able to store reference to the folder it belongs to.
after the activity is done we need to save the activity to the folder it belongs to.


new Activity class:
-folderId //null if it is not in any folder
..extra fields:



Database Refactor:
we need to create a new database table for folders.
containing the following fields:
-id
-name
-parentFolderId
-isPinned
-createdAt
-updatedAt

Logic for creating a folder:
-create a new folder in the database
- its parent folder id should be the id of the folder it is being created in unless it is a root folder where it should be null

Logic for creating a subfolder:
-create a new folder in the database
- its parent folder id should be the id of the folder it is being created in

Logic for deleting a folder:
-delete the folder from the database
-delete all the subfolders and activities inside it

Logic for renaming a folder:
-rename the folder in the database

Logic for pinning a folder:
-pin the folder in the database

Logic for unpinning a folder:
-unpin the folder in the database

Logic for adding an activity to a folder:
-take the activity id and folder id as parameters



*/

/*

we must create a folder provider to manage the folder screen state and the folder database.
Working on the ui of the folder screen.

lets create a folder screen to show the folders and their activities or subfolders.

the default view should display the root directory with the following appearance:

at the top should be the path of the current folder. and after it will be an icon button to add a new folder.

after it in the center will be the name of the current folder (if any) and the number of activities inside it.

then there will be two sections for the folders and the activities.

Folders section:
it will contain a list of folders inside the current folder.
a list view containing list tiles with names of the folder and 3 verrtical dots icon to show a popup menu with the following options:
- rename folder
- delete folder
- pin folder
- unpin folder

Activities section:
- it will contain a list of activities inside the current folder.
- a list view containing list tiles with names of the activities and an icon button to show details.
we can add a popup menu to show the following options:
- view details
- edit activity
- delete activity
- move activity to another folder



*/

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class Folder {
  int id;
  String name;
  int? parentFolderId;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;

  Folder({
    required this.id,
    required this.name,
    this.parentFolderId,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });
}

//creating a folder provider
class FolderProvider with ChangeNotifier {
  static Database? _db;

  //!vars for root folder and activities
  final List<Folder> rootFolders = [];
  final List<DoneActivity> rootActivities = [];

  Future<void> loadDatabase() async {
    databaseActivitiesProvider.database.then((db) {
      _db = db;
    });
    notifyListeners();
  }

  //creating a method to add folder to root directory
  Future<void> addFolderToRoot(String name) async {
    if (_db == null) {
      throw Exception('Database is not loaded');
    }
    final folder = Folder(
      id: rootFolders.length + 1,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db!.insert('folders', {
      'name': folder.name,
      'parentFolderId': folder.parentFolderId,
      'isPinned': folder.isPinned ? 1 : 0,
      'createdAt': folder.createdAt.toIso8601String(),
      'updatedAt': folder.updatedAt.toIso8601String(),
    });

    log('Folder added: ${folder.name}');

    rootFolders.add(folder);
    notifyListeners();
  }

  //method to add activity to root:
  Future<void> addActivityToRoot(int activityId) async {
    if (_db == null) {
      throw Exception('Database is not loaded');
    }
    await _db!.update(
      'activities',
      {'folderId': null},
      where: 'id = ?',
      whereArgs: [activityId],
    );
    notifyListeners();
  }

  //methods to load root datas
  Future<void> loadRootFolders() async {
    if (_db == null) {
      throw Exception('Database is not loaded');
    }
    final List<Map<String, dynamic>> maps = await _db!.query('folders');
    rootFolders.clear();
    for (var map in maps) {
      rootFolders.add(Folder(
        id: map['id'],
        name: map['name'],
        parentFolderId: map['parentFolderId'],
        isPinned: map['isPinned'] == 1,
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      ));
    }
    notifyListeners();
  }

  //method to load root activities:
  Future<void> loadRootActivities() async {
    if (_db == null) {
      throw Exception('Database is not loaded');
    }
    final List<Map<String, dynamic>> maps =
        await _db!.query('activities', where: 'folderId IS NULL');
    rootActivities.clear();
    for (var map in maps) {
      rootActivities.add(DoneActivity(
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
      ));
    }
    notifyListeners();
  }
}

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          // Adding folder button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show dialog to add folder
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Add Folder'),
                    content: TextField(
                      decoration:
                          const InputDecoration(hintText: 'Folder Name'),
                      onSubmitted: (value) {
                        final folderProvider =
                            Provider.of<FolderProvider>(context, listen: false);
                        folderProvider.addFolderToRoot(value);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<FolderProvider>(
        builder: (context, folderProvider, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: folderProvider.rootFolders.length,
                  itemBuilder: (context, index) {
                    final folder = folderProvider.rootFolders[index];
                    return ListTile(
                      title: Text(folder.name),
                      trailing: const Icon(Icons.folder),
                      onTap: () {
                        // Navigate to folder details
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: folderProvider.rootActivities.length,
                  itemBuilder: (context, index) {
                    final activity = folderProvider.rootActivities[index];
                    return ListTile(
                      title: Text(activity.title),
                      trailing: const Icon(Icons.check_circle),
                      onTap: () {
                        // Show activity details
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add folder or activity
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
