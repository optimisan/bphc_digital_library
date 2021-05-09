import 'package:bphc_digital_library/screen_provider.dart';
import 'package:bphc_digital_library/todo/screens/todo_screen.dart';
import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:bphc_digital_library/todo/widgets/todo_list_tile_UI.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class UpcomingTasksScreen extends StatelessWidget {
  const UpcomingTasksScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<ScreenManager>().tasksFilter;
    return FutureBuilder(
      future: Hive.openBox<TodoItem>("todo"),
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<TodoItem>("todo").listenable(),
            builder: (context, Box<TodoItem> boxContents, _) {
              if (boxContents.isEmpty) {
                return NothingToShow('todo', displayStr: 'No tasks to do');
              }

              // final l = getTasksList(boxContents.values.toList());
              final todoList = getTasksList(
                  boxContents: boxContents.values.toList(),
                  filter: filter); //boxContents.values.toList();
              // todoList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              if (todoList.isEmpty) {
                return NothingToShow(
                  'todo',
                  displayStr: 'No $filter tasks',
                );
              }
              return DefaultTextStyle(
                style: const TextStyle(fontSize: 20),
                child: AnimatedList(
                  key: listKey,
                  initialItemCount: todoList.length,
                  itemBuilder: (context, index, animation) {
                    return _slideIt(context, index, animation, todoList[index]);
                  },
                ),
              );
              return ListView.builder(
                itemBuilder: (context, index) {
                  return boxContents.getAt(index)?.toTile(index) ?? SizedBox();
                },
                itemCount: boxContents.length,
              );
            },
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

List getTasksList({required List<TodoItem> boxContents, String? filter}) {
  if (filter == null || filter == 'all') {
    boxContents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return boxContents;
  } else {
    if (filter == 'upcoming') {
      boxContents = boxContents
          .where((element) =>
              (element.reminderExists || element.remindAt == null) && !element.isCompleted)
          .toList();
      boxContents.sort(_sortIt);
    }
    if (filter == 'missed') {
      boxContents = boxContents
          .where((element) =>
              element.remindAt != null && !element.reminderExists && !element.isCompleted)
          .toList();
      boxContents.sort((a, b) => b.remindAt!.compareTo(a.remindAt!));
    } else if (filter == 'completed') {
      boxContents = boxContents.where((element) => element.isCompleted).toList();
      boxContents.sort(_sortIt);
    }
  }
  return boxContents;
}

int _sortIt(TodoItem a, TodoItem b) {
  if (a.remindAt == null && b.remindAt == null) {
    return b.createdAt.compareTo(a.createdAt);
  } else {
    if (b.remindAt == null) return -1;
    if (a.remindAt == null)
      return 1;
    else {
      return b.remindAt!.compareTo(a.remindAt!);
    }
  }
}

Widget _slideIt(BuildContext context, int index, animation, TodoItem? todoItem) {
  if (todoItem == null)
    return SizedBox();
  else {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        ),
      ),
      child: todoItem.toTile(index),
    );
  }
}
