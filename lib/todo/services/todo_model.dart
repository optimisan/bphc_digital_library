import 'package:bphc_digital_library/todo/services/notification_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 1)
class TodoItem extends HiveObject with ChangeNotifier {
  TodoItem(
      {this.books,
      this.title,
      this.content,
      required this.isCompleted,
      this.remindAt,
      required this.createdAt});
  @HiveField(0)
  List<String>? books;
  @HiveField(1)
  String? title;

  /// Details of the todo task.
  @HiveField(2)
  String? content;

  /// Must be assigned a value (`false`) while instantiating
  @HiveField(3)
  bool isCompleted;
  @HiveField(4)
  DateTime? remindAt;

  /// This is to show the tasks in order of creation
  @HiveField(5)
  DateTime createdAt;

  String? get strRemindDate =>
      this.isCompleted ? '' : _timeToDisplay(this.remindAt);

  bool get reminderExists {
    if (remindAt != null)
      return remindAt!.millisecondsSinceEpoch >
          DateTime.now().millisecondsSinceEpoch;
    else
      return false;
  }

  void addReminder(DateTime dateTime) async {
    print("Hash code is ${this.key}");
    this.remindAt = dateTime;
    NotificationHelper.handleReminderNotification(
        dateTime: dateTime, item: this);
    this.saveTodoItem();
  }

  void deleteReminder() {
    print("Hash code is ${this.key}");
    NotificationHelper.cancelNotification(this.key);
  }

  /// Update the `title` and `content`
  Future<void>? updateWith(
      {String? title, String? content, bool? isBeingCreated}) {
    if (title != '') this.title = title;
    if (content != '') this.content = content;
    if (isBeingCreated == true) this.createdAt = DateTime.now();
  }

  void addBook(String name) {
    if (this.books == null) {
      this.books = [name];
    } else if (this.books?.contains(name) == false) {
      this.books?.add(name);
    }
    this.saveTodoItem();
  }

  /// Save todo item to the Hive "todo" box. If it exists, it is updated otherwise a new item is added to the box
  Future<void>? saveTodoItem() async {
    if ((this.title == null && this.content == null) ||
        (this.content == null && this.title == null)) return;
    final box = await Hive.openBox<TodoItem>("todo");
    if (box.containsKey(this.key)) {
      return await box.put(this.key, this);
    } else {
      await box.add(this);
      return;
    }
  }

  /// To undo delete, return this item (`this`) to the navigator and show snackbar with action
  @Deprecated('Use delete() instead, which comes with Hive')
  Future<void>? deleteTodoItem() async {
    final box = await Hive.openBox<TodoItem>("todo");
    await box.delete(this.key);
  }

  Future<void> markCompletedAs(bool val) async {
    final box = await Hive.openBox<TodoItem>("todo");
    this.isCompleted = val;
    notifyListeners();
    return await box.put(this.key, this);
  }
}

String? _timeToDisplay(DateTime? dateTime) {
  if (dateTime == null) return 'No time';
  var orig = dateTime;
  print(dateTime);
  dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final days = _todayMidnight().difference(dateTime).inDays;

  if (days == 0) {
    if (orig.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch)
      return "Missed";
    return "Today";
  }
  if (days > 0) {
    return days == 1 ? "Yesterday" : "$days days ago";
  } else {
    if (days == -1) {
      return "Tomorrow";
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}

DateTime _todayMidnight() {
  final today = DateTime.now();

  return DateTime(today.year, today.month, today.day);
}
