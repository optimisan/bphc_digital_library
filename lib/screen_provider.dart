import 'package:flutter/foundation.dart';

class ScreenManager with ChangeNotifier {
  String screenName = "home";
  int tasksScreenIndex = 0;

  /// Tasks are categorized as (_) if task
  /// `Upcoming` : Has no reminder, or reminder exists and is not completed.
  /// `Missed` : Reminder was in the past and is not completed
  /// `Completed` : Is completed.
  String tasksFilter = "upcoming";
  void updateScreen(String name) {
    screenName = name;
    notifyListeners();
  }

  void notifyRebuild() {
    notifyListeners();
  }

  void setTasksScreen(int index) {
    if (index != tasksScreenIndex) {
      tasksScreenIndex = index;
      switch (index) {
        case 1:
          tasksFilter = 'all';
          break;
        case 0:
          tasksFilter = 'upcoming';
          break;
        case 2:
          tasksFilter = 'missed';
          break;
        case 3:
          tasksFilter = 'completed';
          break;
        default:
      }
      notifyListeners();
    }
  }
}
