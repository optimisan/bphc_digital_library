import 'package:flutter/foundation.dart';

class ScreenManager with ChangeNotifier {
  String screenName = "home";
  void updateScreen(String name) {
    screenName = name;
    notifyListeners();
  }
}
