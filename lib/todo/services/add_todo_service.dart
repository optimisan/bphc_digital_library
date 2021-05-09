import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

import 'todo_model.dart';

class AddingTodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String text = '';
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        TextField(
          onChanged: (value) {
            text = value;
          },
        ),
        TextButton(
          child: Text("Save"),
          onPressed: () {
            _addItem(text);
          },
        ),
      ])),
    );
  }
}

void _addItem(String title) async {
  final box = await Hive.openBox<TodoItem>("todo");
  // box.add(TodoItem(isCompleted: false, title: title));
}
