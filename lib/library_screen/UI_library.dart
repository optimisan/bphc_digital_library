import 'dart:io';

import 'package:bphc_digital_library/screens/library_screen.dart';
import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../screen_provider.dart';
import 'book_models.dart';

extension ItemUI on Item {
  Widget toListTile(BuildContext context, void Function() deleteCallBack) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      tileColor: Color(0x33000000),
      leading: Icon(Icons.insert_drive_file_rounded),
      title: Text(Uri.decodeComponent(this.title)),
      onTap: () async {
        final result = await OpenFile.open(this.path);
        print(result.message);
        if (result.message != "done") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Could not open file."),
          ));
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(this.fileSize),
          ItemPopupMenuButton(
              fileItem: File(this.path),
              title: this.title,
              onDelete: () async {
                try {
                  final file = File(this.path);
                  // TODO: change confirmDialog to update UI with getFiles()
                  await confirmDialog(file, context, () {
                    deleteCallBack();
                  });
                  // await confirmDialog(file, context, () async{
                  //   getFiles();
                  //   setState(() {
                  //     files = filesHere;
                  //   });
                  // });
                  // setState(() {});
                } catch (e) {
                  print(e.toString());
                }
              }),
          // IconButton(
          //   onPressed: () async {
          //     try {
          //       final file = File(this.path);
          //       // TODO: change confirmDialog to update UI with getFiles()
          //       await confirmDialog(file, context, () {
          //         deleteCallBack();
          //       });
          //       // await confirmDialog(file, context, () async{
          //       //   getFiles();
          //       //   setState(() {
          //       //     files = filesHere;
          //       //   });
          //       // });
          //       // setState(() {});
          //     } catch (e) {
          //       print(e.toString());
          //     }
          //   },
          //   icon: Icon(Icons.delete),
          //   color: Colors.redAccent,
          // ),
        ],
      ),
    );
  }
}

class ItemPopupMenuButton extends StatelessWidget {
  const ItemPopupMenuButton({required this.fileItem, required this.onDelete, required this.title});
  final File fileItem;
  final void Function() onDelete;
  final String title;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
        onSelected: (value) {
          _onMenuSelect(value, onDelete, context,
              bookName: fileItem.path.replaceAll(
                  RegExp(
                    '(\/.+\/BPHC_Downloads\/)|\/$title',
                    caseSensitive: true,
                  ),
                  ''),
              itemName: title);
        },
        itemBuilder: (builder) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: "Add task",
                child: ListTile(
                  title: const Text(
                    "Add as a task",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
              ),
              PopupMenuItem(
                  value: 'Delete',
                  child: ListTile(
                    title: const Text(
                      "Delete item",
                      style: const TextStyle(color: const Color(0xFFFEFEFE)),
                    ),
                  ))
            ]);
  }

  void _onMenuSelect(String value, void Function() onDelete, BuildContext context,
      {required String bookName, required String itemName}) {
    switch (value) {
      case 'Add task':
        final task = TodoItem(
            createdAt: DateTime.now(),
            isCompleted: false,
            title: Uri.decodeComponent(bookName),
            content: "Solve ${Uri.decodeComponent(itemName)}")
          ..saveTodoItem();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Task created"),
          action: SnackBarAction(
            label: 'Show',
            onPressed: () async {
              context.read<ScreenManager>().updateScreen('todo');
              final deletedItem =
                  await Navigator.of(context).pushNamed('/todo_editor', arguments: {'todo': task});
              if (deletedItem != null) {
                ScaffoldMessenger.of(mainScaffoldKey.currentContext!).showSnackBar(SnackBar(
                  content: Text("Task deleted"),
                  action: SnackBarAction(
                      label: "Undo",
                      onPressed: () {
                        if (deletedItem is TodoItem) {
                          deletedItem.saveTodoItem();
                        }
                      }),
                ));
              }
            },
          ),
        ));
        break;
      case 'Delete':
        onDelete();
        break;
    }
  }
}
