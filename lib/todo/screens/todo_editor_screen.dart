import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:bphc_digital_library/todo/widgets/time_picker_widget.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

late TextEditingController _titleTextController;
late TextEditingController _contentTextController;

class TodoEditorScreen extends StatelessWidget {
  TodoEditorScreen({TodoItem? todoItem})
      : this.todoItem = todoItem ?? TodoItem(isCompleted: false, createdAt: DateTime.now()),
        this.isEditing = todoItem != null;
  final TodoItem todoItem;
  final bool isEditing;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          if (_titleTextController.text.trim() != '' || _contentTextController.text.trim() != '')
            this.todoItem.saveTodoItem();
        } catch (e) {}

        return Future.value(true);
      },
      child: ChangeNotifierProvider.value(
        value: todoItem,
        child: Consumer<TodoItem>(
          builder: (_, todoItem, __) => Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              leading: IconButton(
                // style: kButtonStyle,
                // child: Text("Save"),
                icon: Icon(Icons.arrow_back),
                tooltip: 'Save and Exit',
                onPressed: () {
                  try {
                    this.todoItem.updateWith(
                        title: _titleTextController.text.trim(),
                        content: _contentTextController.text.trim(),
                        isBeingCreated: !isEditing);
                    this.todoItem.saveTodoItem();
                    Navigator.of(context).pop();
                  } catch (e) {}
                },
              ),
              // leading: Checkbox(
              //   value: todoItem.isCompleted,
              //   onChanged: (value) {
              //     todoItem.markCompletedAs(value ?? false);
              //   },
              // ),
              actions: [
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                      onPressed: () {
                        try {
                          this.todoItem.updateWith(
                              title: _titleTextController.text.trim(),
                              content: _contentTextController.text.trim(),
                              isBeingCreated: !isEditing);
                          this.todoItem.saveTodoItem();
                          Navigator.of(context).pop();
                        } catch (e) {}
                      },
                      child: Text("Save"),
                      style: ElevatedButton.styleFrom(
                        elevation: 1.0,
                        primary: Color(0xFF222222),
                      )),
                ),
                if (isEditing)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      todoItem.deleteReminder();
                      todoItem.delete();
                      Navigator.pop<TodoItem>(context, this.todoItem);
                    },
                  ),
              ],
              backgroundColor: Color(0x88121212),
              elevation: 0.0,
              title: Text(this.isEditing ? "Edit Task" : "New Task"),
            ),
            body: TodoDetails(this.todoItem),
          ),
        ),
      ),
    );
  }
}

class TodoDetails extends StatefulWidget {
  const TodoDetails(this.todoItem);
  final TodoItem todoItem;
  @override
  _TodoDetailsState createState() => _TodoDetailsState(todoItem);
}

class _TodoDetailsState extends State<TodoDetails> {
  _TodoDetailsState(TodoItem todoItem) {
    _titleTextController = TextEditingController(text: todoItem.title);
    _contentTextController = TextEditingController(text: todoItem.content);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18),
      child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleTextController,
            style: TextStyle(color: Colors.white, fontSize: 22.0), //kNoteTitleLight,
            decoration: const InputDecoration(
              hintText: 'Title',
              fillColor: Color(0x507A7A7A),
              filled: true,
              focusColor: Colors.blueGrey,
              focusedBorder: const OutlineInputBorder(
                // borderSide:
                //     const BorderSide(color: Colors.transparent, width: 0.2),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                // borderSide:
                //     const BorderSide(color: Color(0x55700A7A), width: 0.2),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
              counter: const SizedBox(),
            ),
            maxLines: null,
            // maxLength: 1024,
            textCapitalization: TextCapitalization.sentences,
          ),
          SizedBox(height: 10),
          TextField(
            keyboardType: TextInputType.multiline,

            controller: _contentTextController,
            style: TextStyle(
              color: Colors.grey.shade300,
              height: 1.5,
              fontSize: 16,
            ), //kNoteTextLargeLight,
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
              hintText: 'Add details',
              filled: true,
              fillColor: Color(0x447A7A7A),
              focusedBorder: const OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                // borderSide:
                //     const BorderSide(color: Color(0x55700A7A), width: 0.2),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
            ),

            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
          SizedBox(height: 50),
          Text("Add A Reminder", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          SizedBox(height: 27),
          ReminderWidgets(widget.todoItem),
        ],
      )),
    );
  }
}

class ReminderWidgets extends StatelessWidget {
  const ReminderWidgets(this.todoItem);
  final TodoItem todoItem;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TimePickerWidget(todoItem: todoItem),
        SizedBox(width: 25),
        DatePickerWidget(todoItem: todoItem),
      ],
    );
  }
}
