import 'package:flutter/material.dart';
import 'package:my_activities/providers/providers.dart';
// import 'package:provider/provider.dart';

class FolderScreen extends StatefulWidget {
  final int? parentFolderId;
  final String? currentFolderName;

  const FolderScreen({
    super.key,
    this.parentFolderId,
    this.currentFolderName = 'Root',
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late Future<List<Map<String, dynamic>>> _foldersFuture;
  late Future<List<Map<String, dynamic>>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _foldersFuture = databaseActivitiesProvider.getFolders(
      parentFolderId: widget.parentFolderId,
    );
    _activitiesFuture = databaseActivitiesProvider.getActivitiesInFolder(
      widget.parentFolderId ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentFolderName ?? 'Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateFolderDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _foldersFuture,
          builder: (context, foldersSnapshot) {
            if (foldersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (foldersSnapshot.hasError) {
              return Center(child: Text('Error: ${foldersSnapshot.error}'));
            }

            final folders = foldersSnapshot.data ?? [];

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _activitiesFuture,
              builder: (context, activitiesSnapshot) {
                if (activitiesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (activitiesSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${activitiesSnapshot.error}'));
                }

                final activities = activitiesSnapshot.data ?? [];

                return ReorderableListView.builder(
                  itemCount: folders.length + activities.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    // await databaseActivitiesProvider.reorderItems(
                    //   widget.parentFolderId,
                    //   oldIndex,
                    //   newIndex,
                    // );
                    setState(() {
                      _loadData();
                    });
                  },
                  itemBuilder: (context, index) {
                    if (index < folders.length) {
                      final folder = folders[index];
                      return ListTile(
                        key: Key('folder-${folder['id']}'),
                        leading: const Icon(Icons.folder),
                        title: Text(folder['name']),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteFolderDialog(context, folder['id']);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderScreen(
                                parentFolderId: folder['id'],
                                currentFolderName: folder['name'],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      final activityIndex = index - folders.length;
                      final activity = activities[activityIndex];
                      return ListTile(
                        key: Key('activity-${activity['id']}'),
                        leading: const Icon(Icons.task),
                        title: Text(activity['title']),
                        subtitle: Text(activity['groupTitle']),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await databaseActivitiesProvider.createFolder(
                  controller.text,
                  parentFolderId: widget.parentFolderId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _loadData();
                  });
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteFolderDialog(
      BuildContext context, int folderId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: const Text(
            'Are you sure you want to delete this folder? This will also delete all activities inside it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await databaseActivitiesProvider.deleteFolder(folderId);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _loadData();
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 

/*
Creating a folder provider that will simplify the process of creating, combining, deleting, renaming folders and creating subfolders.
along with these we should also be able to pin folders.
once we are inside a folder we should be able to create activity from inside the folder for convenience.
we should also refactor the add activity screen to be able to add activity to a folder.


 */