import 'package:bphc_digital_library/services/firebase_messaging_service.dart';
import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Store all notification id's in Firebase and in the respective notes
class NotificationHelper {
  static var androidDetails = AndroidNotificationDetails(
      "Reminders", "To Do reminders", "Your todo reminders",
      importance: Importance.high);

  static Future<dynamic>? handleReminderNotification(
      {required DateTime dateTime, required TodoItem item}) async {
    print("hash code is" + item.hashCode.toString());
    var difference =
        dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (difference > 100 &&
        (item.title != '' || item.content != '') &&
        (item.title != null || item.content != null)) {
      var differenceDuration = Duration(milliseconds: difference);
      await showReminderNotification(
        differenceDuration: differenceDuration,
        title: item.title,
        content: item.content,
        // payload: note?.key.toString(),
        id: item.key,
      );
      // note?.setReminder(dateTime).then((value) => null);
    } else {
      print(difference.toString());
    }
  }

  static Future<dynamic> cancelNotification(int id) async {
    return await flutterLocalNotificationsPlugin.cancel(id);
  }

  // static Future<dynamic> notificationSelected(String? payload) async {
  //   // showDialog(
  //   //   context: context
  //   // )
  //   print("Notif $payload");
  //   await Hive.openBox<Note>("notes");
  //   print(MyApp.navigatorKey?.currentContext != null);
  //   if (MyApp.navigatorKey?.currentContext != null && payload != null)
  //     Navigator.pushNamed(MyApp.navigatorKey!.currentState!.context, "/note", arguments: {
  //       'note': Hive.box<Note>("notes").get(int.parse(payload)),
  //     });
  //   return Future.value(3);
  // }

  static Future<dynamic>? showReminderNotification(
      {required Duration differenceDuration,
      String? title,
      String? content,
      String? payload,
      int id = 0}) async {
    if (title == null && content == null) title = "BPHC reminder";
    print(differenceDuration.toString());
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      content,
      tz.TZDateTime.now(tz.local).add(differenceDuration),
      // tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      generalNotificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: false,
      payload: payload,
    );
  }

  static Future<dynamic>? showNotification(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidDetails = AndroidNotificationDetails(
        "channelId", "To do reminders", "channelDescription",
        importance: Importance.high);
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails);
    // await flutterLocalNotificationsPlugin.show(0, "Task", "body", generalNotificationDetails);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        "scheduled title",
        "body",
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: false);
  }
// final BehaviorSubject<ReminderNotification> didReceiveLocalNotificationSubject =
//     BehaviorSubject<ReminderNotification>();
//
// final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();
}
