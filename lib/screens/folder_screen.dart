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

class FolderProvider extends ChangeNotifier {
  Folder currentFolder = Folder(
    id: 0,
    name: 'Root',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  List<Map<String, dynamic>> folders = [];

  // filder folders for the current folder
  List<Map<String, dynamic>> currentFolderFolders = [];

  //init for root:
  Future<void> init() async {
    log('init called...');
    await loadFolders();

    await loadCurrentFolderActivities(currentFolder.id);
    currentFolderFolders =
        folders.where((folder) => folder['parentFolderId'] == null).toList();
    notifyListeners();

    //activities:
    await loadAllActivities();

    currentFolderActivities = currentFolderActivities
        .where((activity) =>
            activity['folderId'] == currentFolder.id ||
            activity['folderId'] == null)
        .toList();
  }

  Future<void> loadFolders() async {
    log('loadFolders called...');
    final db = await databaseActivitiesProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    folders = maps;
    log('Folders loaded: $folders');
    notifyListeners();
  }

  Future<void> addFolder(String name, {int? parentFolderId}) async {
    log('addFolder called with name: $name, parentFolderId: $parentFolderId');
    await databaseActivitiesProvider.createFolder(name,
        parentFolderId: parentFolderId);
    log('Folder added successfully');
    await loadFolders();
  }

  Future<void> deleteFolder(int folderId) async {
    log('deleteFolder called with folderId: $folderId');
    await databaseActivitiesProvider.deleteFolder(folderId);
    log('Folder deleted successfully');
    await loadFolders();
  }

  Future<void> renameFolder(int folderId, String newName) async {
    log('renameFolder called with folderId: $folderId, newName: $newName');
    await databaseActivitiesProvider.renameFolder(folderId, newName);
    log('Folder renamed successfully');
    await loadFolders();
  }

  Future<void> pinFolder(int folderId, bool isPinned) async {
    log('pinFolder called with folderId: $folderId, isPinned: $isPinned');
    await databaseActivitiesProvider.pinFolder(folderId, isPinned);
    log('Folder pin status updated successfully');
    await loadFolders();
  }

  Future<void> unpinFolder(int folderId) async {
    log('unpinFolder called with folderId: $folderId');
    await databaseActivitiesProvider.pinFolder(folderId, false);
    log('Folder unpinned successfully');
    await loadFolders();
  }

  List<Map<String, dynamic>> currentFolderActivities = [];
  Future<void> getActivitiesByFolderId(int folderId) async {
    log('getActivitiesByFolderId called with folderId: $folderId');
    final db = await databaseActivitiesProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    currentFolderActivities = maps;
    log('Activities loaded for folderId $folderId: $currentFolderActivities');
    notifyListeners();
  }

  //load all activities
  Future<void> loadAllActivities() async {
    log('loadAllActivities called...');
    final db = await databaseActivitiesProvider.database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    currentFolderActivities = maps;
    log('All activities loaded: $currentFolderActivities');
    notifyListeners();
  }

  //load current folder activities
  Future<void> loadCurrentFolderActivities(int folderId) async {
    log('loadCurrentFolderActivities called with folderId: $folderId');
    await getActivitiesByFolderId(folderId);
    log('Current folder activities loaded successfully');
  }

  //load folders of current
  Future<void> loadCurrentFolderFolders(int folderId) async {
    log('loadCurrentFolder called with folderId: $folderId');
    await getFoldersOfFolder(folderId);
    log('Current folder loaded successfully');
  }

  Future<void> moveActivityToFolder(DoneActivity activity, int folderId) async {
    log('moveActivityToFolder called with activity: $activity, folderId: $folderId');
    await databaseActivitiesProvider.moveActivityToFolder(activity, folderId);
    log('Activity moved to folderId $folderId successfully');
    await getActivitiesByFolderId(folderId);
  }

  Future<void> getFoldersOfFolder(int folderId) async {
    log('getFoldersOfFolder called with folderId: $folderId');
    final db = await databaseActivitiesProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'parentFolderId = ?',
      whereArgs: [folderId],
    );
    folders = maps;
    log('Folders loaded for folderId $folderId: $folders');
    notifyListeners();
  }

  //current folder :
}

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FolderProvider>(
          builder: (context, folderProvider, child) {
            return Text('Folder: ${folderProvider.currentFolder.name}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add folder logic
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController folderNameController =
                      TextEditingController();
                  return AlertDialog(
                    title: const Text('Create Folder'),
                    content: TextField(
                      controller: folderNameController,
                      decoration:
                          const InputDecoration(hintText: 'Folder Name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final folderName = folderNameController.text.trim();
                          if (folderName.isNotEmpty) {
                            Provider.of<FolderProvider>(context, listen: false)
                                .addFolder(folderName,
                                    parentFolderId: Provider.of<FolderProvider>(
                                            context,
                                            listen: false)
                                        .currentFolder
                                        .id);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<FolderProvider>(
        builder: (context, folderProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Current Folder: ${folderProvider.currentFolder.name}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Folders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: folderProvider.currentFolderFolders.length,
                  itemBuilder: (context, index) {
                    final folder = folderProvider.currentFolderFolders[index];
                    return ListTile(
                      title: Text(folder['name']),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          switch (value) {
                            case 'rename':
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final TextEditingController renameController =
                                      TextEditingController(
                                          text: folder['name']);
                                  return AlertDialog(
                                    title: const Text('Rename Folder'),
                                    content: TextField(
                                      controller: renameController,
                                      decoration: const InputDecoration(
                                          hintText: 'New Folder Name'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final newName =
                                              renameController.text.trim();
                                          if (newName.isNotEmpty) {
                                            folderProvider.renameFolder(
                                                folder['id'], newName);
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Text('Rename'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              break;
                            case 'delete':
                              folderProvider.deleteFolder(folder['id']);
                              break;
                            case 'pin':
                              folderProvider.pinFolder(folder['id'], true);
                              break;
                            case 'unpin':
                              folderProvider.unpinFolder(folder['id']);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename Folder'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Folder'),
                          ),
                          const PopupMenuItem(
                            value: 'pin',
                            child: Text('Pin Folder'),
                          ),
                          const PopupMenuItem(
                            value: 'unpin',
                            child: Text('Unpin Folder'),
                          ),
                        ],
                      ),
                      onTap: () {
                        folderProvider.loadCurrentFolderFolders(folder['id']);
                        folderProvider
                            .loadCurrentFolderActivities(folder['id']);
                      },
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Activities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: folderProvider.currentFolderActivities.length,
                  itemBuilder: (context, index) {
                    final activity =
                        folderProvider.currentFolderActivities[index];
                    return ListTile(
                      title: Text(activity['name'] ?? ''),
                      trailing: PopupMenuButton(
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              // View details logic
                              break;
                            case 'edit':
                              // Edit activity logic
                              break;
                            case 'delete':
                              folderProvider.deleteFolder(activity['id']);
                              break;
                            case 'move':
                              // Move activity logic
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View Details'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Activity'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Activity'),
                          ),
                          const PopupMenuItem(
                            value: 'move',
                            child: Text('Move Activity'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add activity logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
