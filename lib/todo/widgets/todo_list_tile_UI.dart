import 'package:bphc_digital_library/screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:bphc_digital_library/main.dart';
import 'package:bphc_digital_library/todo/screens/todo_screen.dart';
import 'package:provider/provider.dart';

extension TodoTileUI on TodoItem {
  Widget toTile(int index) {
    return TodoWidget(todoItem: this, index: index);
  }
}

class TodoWidget extends StatelessWidget {
  const TodoWidget({
    Key? key,
    required this.todoItem,
    required this.index,
  }) : super(key: key);
  final TodoItem todoItem;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            fillColor: MaterialStateProperty.all(Color(0xad1ddee5)),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            value: todoItem.isCompleted,
            onChanged: (value) {
              if (context.read<ScreenManager>().tasksScreenIndex != 1)
                Provider.of<ScreenManager>(context, listen: false).notifyRebuild();
              todoItem.markCompletedAs(value ?? false);
            },
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final deletedItem = await Navigator.of(context)
                    .pushNamed('/todo_editor', arguments: {'todo': todoItem});

                if (deletedItem != null) {
                  ScaffoldMessenger.of(mainScaffoldKey.currentContext!).showSnackBar(SnackBar(
                    content: Text("Task deleted"),
                    action: SnackBarAction(
                        label: "Undo",
                        onPressed: () {
                          if (deletedItem is TodoItem) {
                            listKey.currentState
                                ?.insertItem(index, duration: Duration(milliseconds: 300));
                            deletedItem.saveTodoItem();
                          }
                        }),
                  ));
                }
              },
              child: Container(
                constraints: BoxConstraints(minHeight: 50),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xBD292E3C),
                ),
                padding: EdgeInsets.only(top: 10, bottom: 10, left: 9, right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(todoItem.title ?? 'No Title',
                              style: TextStyle(
                                decoration:
                                    this.todoItem.isCompleted ? TextDecoration.lineThrough : null,
                                color: this.todoItem.isCompleted ? Color(0xdd666666) : null,
                              )),
                        ),
                        if (todoItem.remindAt != null)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              todoItem.strRemindDate!,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 5),
                    if (todoItem.content != null && todoItem.content != '')
                      Text(
                        todoItem.content!,
                        style: TextStyle(
                          fontSize: 15,
                          color: this.todoItem.isCompleted ? Color(0xdd666666) : null,
                        ),
                      ),
                    // SizedBox(height: todoItem.content != null ? 5 : 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    // return ListTile(
    //   onTap: () async {
    //     final deletedItem = await Navigator.of(context)
    //         .pushNamed('/todo_editor', arguments: {'todo': todoItem});
    //     if (deletedItem != null) {
    //       print("Undo delete");
    //       ScaffoldMessenger.of(mainScaffoldKey.currentContext!)
    //           .showSnackBar(SnackBar(
    //         content: Text("Task deleted"),
    //         action: SnackBarAction(
    //             label: "Undo",
    //             onPressed: () {
    //               if (deletedItem is TodoItem) {
    //                 listKey.currentState?.insertItem(index,
    //                     duration: Duration(milliseconds: 300));
    //                 deletedItem.saveTodoItem();
    //               }
    //             }),
    //       ));
    //     }
    //   },
    //   title: Text(
    //     todoItem.title ?? '(No title)',
    //     style: TextStyle(
    //         decoration:
    //             todoItem.isCompleted ? TextDecoration.lineThrough : null),
    //   ),
    //   subtitle: todoItem.content == null ? null : Text(todoItem.content ?? ''),
    //   trailing: Checkbox(
    //     value: todoItem.isCompleted,
    //     onChanged: (value) {
    //       todoItem.markCompletedAs(value ?? false);
    //     },
    //   ),
    // );
  }
}

const kStyle = TextStyle(fontSize: 15, color: Color(0xDDADADAD));
