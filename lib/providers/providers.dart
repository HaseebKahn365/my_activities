import 'package:flutter/material.dart';
import 'package:my_activities/providers/active_activities.dart';
import 'package:my_activities/screens/homepage.dart';

final themeProvider = ThemeProvider();
final sharedPrefActivitiesProvider = SharedPrefActivities();
final databaseActivitiesProvider = DatabaseActivities();

class DatabaseActivities extends ChangeNotifier {
  List<DoneActivity> activities = [];

  void doneActivity(DoneActivity activity) {
    activities.add(activity);
    notifyListeners();
  }

  void removeActivity(DoneActivity activity) {
    activities.remove(activity);
    notifyListeners();
  }

  int get count => activities.length;
}
