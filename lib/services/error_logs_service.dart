import 'package:hive/hive.dart';

Box? errorBox;
String errorString = '';

void logError(String e) async {
  print("logging error");
  errorString += e;

  try {
    errorBox = await Hive.openBox<String>("errors");
    errorBox?.add(e);
  } catch (e) {}
}

void clearErrorLogs() async {
  errorBox = await Hive.openBox<String>("errors");
  errorBox?.deleteFromDisk();
}

Future<String?> getErrors() async {
  Box box;

  errorBox = await Hive.openBox<String>("errors");
  if (errorBox != null) {
    box = Hive.box<String>("errors");
  } else {
    errorBox = await Hive.openBox<String>("errors");
    box = Hive.box<String>("errors");
  }
  StringBuffer sb = new StringBuffer('Logs: ');
  for (var i = 0; i < box.length; i++) {
    sb.writeln(box.getAt(i));
  }
  if (box.length == 0) sb.write(errorString);
  return sb.toString();
}
