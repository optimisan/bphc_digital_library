import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime _date = DateTime.now();
TimeOfDay _time = TimeOfDay.now();

class TimePickerWidget extends StatefulWidget {
  const TimePickerWidget({required this.todoItem});
  final TodoItem todoItem;

  @override
  _TimePickerWidgetState createState() =>
      _TimePickerWidgetState(todoItem.remindAt);
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  _TimePickerWidgetState(DateTime? d) {
    this.timeToDisplay = d;
  }
  DateTime? timeToDisplay;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      // style: OutlinedButton.styleFrom(
      //   primary: Color(0xAAEDEDED),
      // ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
            border: Border.all(color: Color(0x55EDEDED)),
            // border:,
            // color: Color(0xAB787878),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm, size: 18),
            SizedBox(width: 5),
            Text(
                this.timeToDisplay == null
                    ? "Select time"
                    : DateFormat.Hm().format(this.timeToDisplay!),
                style: const TextStyle(fontSize: 16, color: Color(0xFFADADAD))),
          ],
        ),
      ),
      onTap: () {
        _selectTime(context);
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final currentTime = widget.todoItem.remindAt != null
        ? TimeOfDay.fromDateTime(widget.todoItem.remindAt!)
        : TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      // builder: (BuildContext context, Widget child) {
      //   return MediaQuery(
      //     data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      //     child: child,
      //   );
      // },
    );
    if (pickedTime != null) {
      final DateTime todayDate = widget.todoItem.remindAt != null
          ? widget.todoItem.remindAt!
          : DateTime.now();
      setState(() {
        this.timeToDisplay = DateTime(
          todayDate.year,
          todayDate.month,
          todayDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
      this.widget.todoItem.addReminder(DateTime(
            todayDate.year,
            todayDate.month,
            todayDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
    }
  }
}

class DatePickerWidget extends StatefulWidget {
  DatePickerWidget({required this.todoItem});
  final TodoItem todoItem;

  @override
  _DatePickerWidgetState createState() =>
      _DatePickerWidgetState(this.todoItem.remindAt);
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  _DatePickerWidgetState(DateTime? d) {
    this.timeToDisplay = d;
  }
  DateTime? timeToDisplay;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0x55EDEDED)),
          // color: Color(0xAB787878),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 18),
            SizedBox(width: 5),
            Text(
                this.timeToDisplay == null
                    ? "Choose date"
                    : DateFormat.yMMMd().format(widget.todoItem.remindAt!),
                style: const TextStyle(fontSize: 16, color: Color(0xFFADADAD))),
          ],
        ),
      ),
      onTap: () {
        _selectDate(context);
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentTime = widget.todoItem.remindAt != null
        ? TimeOfDay.fromDateTime(widget.todoItem.remindAt!)
        : TimeOfDay.now();
    final DateTime? pickedTime = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // builder: (BuildContext context, Widget child) {
      //   return MediaQuery(
      //     data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      //     child: child,
      //   );
      // },
    );
    if (pickedTime != null) {
      final DateTime todayDate = widget.todoItem.remindAt != null
          ? widget.todoItem.remindAt!
          : DateTime.now();
      setState(() {
        this.timeToDisplay = DateTime(
          pickedTime.year,
          pickedTime.month,
          pickedTime.day,
          todayDate.hour,
          todayDate.minute,
        );
      });
      this.widget.todoItem.addReminder(DateTime(
            pickedTime.year,
            pickedTime.month,
            pickedTime.day,
            todayDate.hour,
            todayDate.minute,
          ));
    }
  }
}
