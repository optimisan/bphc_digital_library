import 'dart:async';
import 'dart:io';

import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:watcher/watcher.dart';
import 'book_models.dart';

///To remove the initial path to the file/directory
///
// Although the FileSystem class has a built in method for this...
final RegExp initRegExp = new RegExp(
  r"(\/.+\/BPHC_Downloads\/)|(_\d+\-?.*)",
  caseSensitive: true,
  multiLine: false,
);

final RegExp regexpForFolder = RegExp(
  r'\/.+\/BPHC_Downloads\/',
  caseSensitive: true,
);

class FileListing with ChangeNotifier {
  FileListing(BuildContext context) {
    this.getFileStream(context);
  }

  /// All files in  'BPHC_Downloads' directory
  List<FileSystemEntity> files = [];
  List<Book> books = [];
  String? externalDir;
  StreamSubscription? fileStream;

  /// Get file list from 'BPHC_Downloads' directory and assign it to [files]
  void getFiles({bool fromBuild = false}) async {
    // externalDir = await getExternalStorageDirectory();

    final status = await Permission.storage.request();
    if (status.isGranted) {
      // externalDir = await AndroidPathProvider.downloadsPath;
      if (externalDir != null) {
        await Directory('$externalDir/BPHC_Downloads').create();
        final filesHere = Directory('$externalDir/BPHC_Downloads').listSync();
        files = filesHere;
        createTree(fromBuild: fromBuild);
        // setState(() {});
      }
    }
  }

  /// C
  void createTree({bool fromBuild = false}) {
    books = []; //reset books
    final List<String> bookTitles = [];
    for (var i = 0; i < files.length; i++) {
      if (FileSystemEntity.isDirectorySync(files[i].path)) {
        final title = files[i].path; //.replaceAll(initRegExp, '');
        bookTitles.add(title);
      }
    }
    for (var i = 0; i < bookTitles.length; i++) {
      // print(bookTitles[i]);
      final bookT = bookTitles[i];
      // Get date from Directory name
      final date = RegExp(r'_\d+\-?.*').firstMatch(bookT)?.group(0);
      // Get items in the directory as [Item]
      final items = Directory(bookT).listSync().map((e) => e.toItem).toList();
      // print(items.toString());

      books.add(Book(
        title: bookTitles[i].replaceAll(initRegExp, ''), //.replaceAll(RegExp(r'_\d+\-?.*'), ''),
        issueDate: date,
        items: items,
        path: bookT,
      ));
    }
    if (!fromBuild) notifyListeners();
  }

  Future<void> confirmDialog(File file, BuildContext context, void Function() stateCallBack,
      {bool? isBook, bool? isDeleteAll}) async {
    final displayName = file.path.replaceAll(initRegExp, '');
    final fileData = file.path.replaceAll(regexpForFolder, '').split('/');
    return await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // title: Text(file.path),
        title: isBook == true
            ? isDeleteAll == null
                ? Text("Delete all items in $displayName?")
                : Text("Delete all books?")
            : Text(
                "Delete item ${file.path.replaceAll(RegExp(r'\/.+\/'), '')} in  ${displayName.replaceAll(RegExp(r'\/.+\/'), '')}?"),
        actions: [
          TextButton(
            child: Text("No, cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              primary: Colors.redAccent,
            ),
            child: Text("Delete"),
            onPressed: () async {
              try {
                if (isBook == null)
                  await file.delete();
                else
                  await file.delete(recursive: true);
                Navigator.of(context).pop();
                await Directory('$externalDir/BPHC_Downloads').create();
                stateCallBack();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isBook == true
                      ? isDeleteAll == null
                          ? "Deleted book $displayName"
                          : "Deleted all books"
                      : "Deleted item ${file.path.replaceAll(RegExp(r'\/.+\/'), '')}"),
                ));
                if (isBook == true) {
                  deleteFromHistory(bookName: fileData[0], isABook: true);
                } else {
                  deleteFromHistory(bookName: fileData[0], fileName: fileData[1]);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Could not delete: $e"),
                ));
              }
            },
          )
        ],
      ),
    );
  }

  void getFileStream(BuildContext context) {
    this.externalDir = context.read<SearchInputs>().externalDir;
    if (fileStream == null)
      fileStream = DirectoryWatcher('$externalDir/BPHC_Downloads').events.listen((event) {
        this.getFiles();
      });
  }

  void endStream() {
    fileStream?.cancel();
  }
}
