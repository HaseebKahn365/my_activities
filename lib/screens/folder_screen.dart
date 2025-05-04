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

import 'package:flutter/material.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('This is the Folders screen'),
      ),
    );
  }
}
