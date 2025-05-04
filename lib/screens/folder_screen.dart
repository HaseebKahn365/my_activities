
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
import 'package:flutter/material.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
      ),
      body: const Center(
        child: Text('This is the Folders screen'),
      ),
    );
  }
}
