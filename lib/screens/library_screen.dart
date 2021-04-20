import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/material.dart';
import 'package:bphc_digital_library/services/download_helper.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

List<FileSystemEntity> files = [];
List<Book> books = [];
// Directory? externalDir;
String? externalDir;

///To remove the inital path to the file/directory
RegExp initRegExp = new RegExp(
  r"(\/.+\/BPHC_Downloads\/)|(_\d+\-?.*)",
  caseSensitive: true,
  multiLine: false,
);

RegExp regexpForFolder = RegExp(
  r'\/.+\/BPHC_Downloads\/',
  caseSensitive: true,
);

class Book {
  const Book(
      {required this.title,
      required this.path,
      required this.issueDate,
      required this.items});
  final String title;
  final String path;
  final String? issueDate;
  final List<Item> items;
}

class Item {
  const Item({required this.title, required this.path, required this.size});
  final String title;
  final String path;
  final int size;
  // final int size;
}

Item toItem(FileSystemEntity e) {
  final name = e.path.replaceAll(RegExp(r'\/.+\/'), '');
  final size = e.statSync().size;
  return Item(title: name, path: e.path, size: size);
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key, required this.onEnter}) : super(key: key);
  final Function onEnter;
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    getFiles();
  }

  Widget toListTile(Item item) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      tileColor: Color(0x33000000),
      leading: Icon(Icons.insert_drive_file_rounded),
      title: Text(item.title),
      onTap: () async {
        final result = await OpenFile.open(item.path);
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
          Text("${(item.size / 1024).toStringAsFixed(2)}kb"),
          IconButton(
            onPressed: () async {
              try {
                final file = File(item.path);
                await confirmDialog(file, context, getFiles);
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
            },
            icon: Icon(Icons.delete),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  void createTree() {
    books = [];
    final List<String> bookTitles = [];
    for (var i = 0; i < files.length; i++) {
      if (FileSystemEntity.isDirectorySync(files[i].path)) {
        final title = files[i].path; //.replaceAll(initRegExp, '');
        bookTitles.add(title);
      }
    }
    for (var i = 0; i < bookTitles.length; i++) {
      print(bookTitles[i]);
      final bookT = bookTitles[i];
      final date = RegExp(r'_\d+\-?.*').firstMatch(bookT)?.group(0);
      final items = Directory(bookT).listSync().map((e) => toItem(e)).toList();
      print(items.toString());

      books.add(Book(
        title: bookTitles[i].replaceAll(
            initRegExp, ''), //.replaceAll(RegExp(r'_\d+\-?.*'), ''),
        issueDate: date,
        items: items,
        path: bookT,
      ));
    }
  }

  void getFiles() async {
    // externalDir = await getExternalStorageDirectory();
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // externalDir = await AndroidPathProvider.downloadsPath;
      if (externalDir != null) {
        await Directory('$externalDir/BPHC_Downloads').create();
        final filesHere = Directory('$externalDir/BPHC_Downloads').listSync();
        files = filesHere;

        createTree();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInLibrary = Provider.of<SearchInputs>(context).showInLibraryTitle;
    final dir = Provider.of<SearchInputs>(context).externalDir;
    if (dir != externalDir) {
      //this is so that this screen is rebuilt whe provider changes
      externalDir = dir;
      getFiles();
    }

    if (books.length > 0) {
      return Stack(alignment: Alignment.center, children: [
        ListView.builder(
          itemBuilder: (context, index) {
            final items = books[index].items.map((e) => toListTile(e)).toList();
            if (items.length == 0) {
              items.add(Text("No Items here."));
            }
            items.add(bookOptions(
                bookName: '${books[index].title}_${books[index].issueDate}',
                path: books[index].path,
                context: context,
                searchStr: provideSearchString(books[index])));
            return Container(
              padding: externalDir == 'downloads'
                  ? null
                  : EdgeInsets.only(bottom: 1),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Color(0x22FEFEFE),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ExpansionTile(
                // collapsedBackgroundColor: Colors.grey,
                // backgroundColor: kBackgroundColor,
                onExpansionChanged: (isExpanded) {
                  if (isExpanded) {
                    context.read<SearchInputs>().updateShowInLibrary(
                        '${books[index].title}${books[index].issueDate}');
                  } else {
                    context.read<SearchInputs>().updateShowInLibrary(null);
                  }
                },
                initiallyExpanded:
                    '${books[index].title}${books[index].issueDate}' ==
                        showInLibrary,
                leading: Icon(Icons.book_rounded),
                title: Text(books[index].title),
                subtitle: (books[index].issueDate != null)
                    ? Text(books[index].issueDate?.replaceAll("_", "") ??
                        'No date')
                    : null,
                children: items,
              ),
            );
          },
          itemCount: books.length,
        ),
        Positioned(
            bottom: 20.0,
            child: ElevatedButton(
              child: Text("Delete all books"),
              onPressed: () async {
                final bookFile = File('$externalDir/BPHC_Downloads');
                await confirmDialog(bookFile, context, () {
                  setState(() {
                    getFiles();
                  });
                }, isBook: true, isDeleteAll: true);

                await Directory('$externalDir/BPHC_Downloads').create();
                deleteAllHistory();
              },
            )),
      ]);
    } else
      return Center(child: Text("Downloaded items will show up here."));
  }

  String provideSearchString(Book book) {
    final title = book.title.replaceAll(" ", "+");
    return "$title&rpp=10&sort_by=score&order=desc&filter_field_1=title&filter_type_1=equals&filter_value_1=$title&filter_field_2=dateIssued&filter_type_2=contains&filter_value_2=${book.issueDate?.replaceAll('_', '')}";
  }

  Widget deleteBookButton(
      {required String bookName,
      required String path,
      required BuildContext context}) {
    final file = File(path);

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        primary: Color(0xDDff195b),
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(5.0),
          side: BorderSide(color: Color(0xFFff195b)),
        ),
      ),
      onPressed: () {
        confirmDialog(file, context, getFiles, isBook: true);
      },
      label: Text("Delete"),
      icon: Icon(Icons.delete),
    );
  }

  Widget bookOptions(
      {required String bookName,
      required String path,
      required BuildContext context,
      required String searchStr}) {
    final searchString =
        "general+chemistry&rpp=10&sort_by=score&order=desc&filter_field_1=title&filter_type_1=equals&filter_value_1=General+Chemistry&filter_field_2=dateIssued&filter_type_2=contains&filter_value_2=2015-05";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        alignment: WrapAlignment.spaceEvenly,

        children: [
          deleteBookButton(bookName: bookName, path: path, context: context),
          // ElevatedButton(
          //     onPressed: () async {
          //       widget.onEnter();
          //       await Provider.of<SearchInputs>(context, listen: false)
          //           .updateSubjectSearch(searchStr);
          //     },
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text("Browse"),
          //         Icon(Icons.open_in_new_sharp),
          //       ],
          //     ))
          OutlinedButton.icon(
            onPressed: () async {
              if (!(await checkInternet())) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text("Not connected to internet"),
                ));
                return;
              } else {
                widget.onEnter();
                print(searchStr);
                await Provider.of<SearchInputs>(context, listen: false)
                    .updateSubjectSearch(searchStr, fromLibraryBrowse: true);
              }
            },
            icon: Icon(Icons.open_in_new_outlined, color: Colors.teal),
            label: Text("Browse", style: TextStyle(color: Colors.teal)),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final shareUrl = await getBookLink(bookName);
              print(shareUrl);
              if (shareUrl != null)
                Share.share(
                    "From BPHC Library:\n${bookName.replaceFirst("_", '')}\n$shareUrl");
            },
            icon: Icon(Icons.share),
            label: Text("Share"),
          ),
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return ChangeNotifierProvider<FileList>(
  //     create: (context) => FileList(),
  //     builder: (context, _) => ListView.builder(
  //       itemBuilder: (context, index) {
  //         return ListTile(
  //           title: Text(files[index].path),
  //           onTap: () async {
  //             final result = await OpenFile.open(files[index].path);
  //           },
  //           trailing: IconButton(
  //             onPressed: () async {
  //               try {
  //                 final file = File(files[index].path);
  //                 await confirmDialog(file, context, () {
  //                   final filesHere =
  //                       Directory('${externalDir?.path}/BPHC_Downloads')
  //                           .listSync();
  //                   setState(() {
  //                     files = filesHere;
  //                   });
  //                 });
  //                 // setState(() {});
  //               } catch (e) {
  //                 print(e.toString());
  //               }
  //             },
  //             icon: Icon(Icons.delete),
  //             color: Colors.redAccent,
  //           ),
  //         );
  //       },
  //       itemCount: files.length,
  //     ),
  //   );
  // }
}

Future<void> confirmDialog(
    File file, BuildContext context, void Function() stateCallBack,
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

class FileList with ChangeNotifier {
  bool rebuild = false;
  void reBuild(bool val) {
    rebuild = !rebuild;
    notifyListeners();
  }
}
