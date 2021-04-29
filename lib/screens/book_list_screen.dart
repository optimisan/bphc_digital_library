import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:bphc_digital_library/constants.dart';
import 'package:bphc_digital_library/services/download_helper.dart';
import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:bphc_digital_library/services/search_results_service.dart';
import 'package:bphc_digital_library/widgets/popup_menu_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

ReceivePort _receivePort = ReceivePort();
Stream<dynamic>? _asBroadcast;
String? folderNameTitle;
String? url;
String? externalDir;
Function? goToLibrary;

class BookListScreen extends StatefulWidget {
  const BookListScreen(
      {this.bookURL,
      required this.listenToPort,
      required this.updateListen,
      required this.bookName,
      required String? folderName,
      required this.toLibrary})
      : folderNameT = folderName;
  final String? bookURL;
  final String bookName;
  final bool listenToPort;
  final void Function() updateListen;
  final String? folderNameT;
  final Function toLibrary;

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  DownloadingTasks? downloadingTasks;
  static void downloadCallback0(String id, DownloadTaskStatus status, int progress) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName("downloader");
    if (sendPort != null) {
      print("Hello");
      sendPort.send([id, status, progress]);
    }
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    print("hi");
    send?.send([id, status, progress]);
  }

  StreamSubscription<dynamic>? subscription;
  void getExternalDir() async {
    externalDir = await AndroidPathProvider.downloadsPath;
  }

  @override
  void initState() {
    super.initState();
    getExternalDir();
    goToLibrary = widget.toLibrary;
    url = widget.bookURL;
    // IsolateNameServer.registerPortWithName(_receivePort.sendPort, "downloader");
    // _asBroadcast = _receivePort.asBroadcastStream();
    // var myStreamController = StreamController<dynamic>.broadcast();
    // myStreamController.stream.asBroadcastStream().listen((event) {})
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'downloader_send_port');
    if (widget.listenToPort)
      _receivePort.listen((dynamic data) {
        String id = data[0];
        DownloadTaskStatus status = data[1];
        int progress = data[2];
        print("In UI isolate");
        setState(() {
          // downloadingTasks.updateDownloadWithIndex(index, value)
        });
      });
    // if (widget.listenToPort)
    //   subscription = _receivePort.listen((message) {
    //     print(message[2].toString());
    //     print("fwfsf");
    //   });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    _receivePort.close();
    subscription?.cancel();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    folderNameTitle = widget.folderNameT;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0x88121212),
        elevation: 0.0,
        title: Text(widget.bookName),
      ),
      body: FutureBuilder<List<BookItemData>?>(
        future: parseBody(widget.bookURL),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.hasError != true) {
            if (snapshot.data != null && snapshot.data?.length != 0) {
              return ChangeNotifierProvider<DownloadingTasks>(
                create: (context) {
                  downloadingTasks = DownloadingTasks(snapshot.data?.length ?? 0);
                  return downloadingTasks ?? DownloadingTasks(snapshot.data?.length ?? 0);
                },
                builder: (context, _) => ListView.builder(
                  itemBuilder: (context, index) {
                    return BookListTile(bookItemData: snapshot.data?[index], index: index);
                  },
                  itemCount: snapshot.data!.length,
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class BookListTile extends StatefulWidget {
  BookListTile({
    Key? key,
    required this.bookItemData,
    required this.index,
  }) : super(key: key);
  final BookItemData? bookItemData;
  final int index;
  @override
  _BookListTileState createState() => _BookListTileState();
}

class _BookListTileState extends State<BookListTile> {
  DownloadTaskStatus? downloadStatus;
  int? downloadProgress;
  bool clicked = false;

  // static void downloadCallback(
  //     String id, DownloadTaskStatus status, int progress) {
  //   SendPort? sendPort = IsolateNameServer.lookupPortByName("downloader");
  //   if (sendPort != null) {
  //     sendPort.send([id, status, progress]);
  //   }
  // }
  void testing() async {
    final externalDir = await getExternalStorageDirectory();
    // Directory appDocDirectory = await getApplicationDocumentsDirectory();
    if (externalDir != null) {
      final files = Directory('${externalDir.path}/BPHC_Downloads').listSync();
      print(files[0].path);
    }
  }

  @override
  void initState() {
    super.initState();

    // IsolateNameServer.registerPortWithName(_receivePort.sendPort, "downloader");

    // FlutterDownloader.registerCallback(downloadCallback);

    // _asBroadcast?.listen((message) {
    //   print(message[1].toString());
    //   setState(() {
    //     downloadProgress = message[2].toInt();
    //   });
    // });
  }

  @override
  void dispose() {
    super.dispose();
    // _receivePort.close();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = Uri.encodeComponent(widget.bookItemData?.fileName ?? 'null');
    final file = File('$externalDir/BPHC_Downloads/$folderNameTitle/$fileName');
    print('$externalDir/BPHC_Downloads/$folderNameTitle/$fileName');
    final fileExists = file.existsSync();
    final bool isDownloading =
        context.watch<DownloadingTasks>().currentDownloading.getVal(widget.index) ?? false;
    return ListTile(
      title: Text(widget.bookItemData?.fileName ?? "Error"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.bookItemData?.size ?? "Error"),
          SizedBox(width: 7.0),
          fileExists || isDownloading ? Icon(Icons.check_sharp) : Icon(Icons.download_rounded),
        ],
      ),
      onTap: () async {
        final file = File('$externalDir/BPHC_Downloads/$folderNameTitle/$fileName');
        if (file.existsSync()) {
          OpenFile.open(file.path);
        } else {
          try {
            if (!(await checkInternet())) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text("Not connected to internet"),
              ));
              return;
            } else {
              await downloadFromURL(widget.bookItemData?.downloadURL, context,
                  folderName: folderNameTitle);
              addBookToHistory(url, folderNameTitle);
              setState(() {
                this.clicked = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text("Download started."),
                action: SnackBarAction(
                  label: "Show",
                  onPressed: () {
                    try {
                      if (mounted) {
                        try {
                          Navigator.pop(context, folderNameTitle);
                        } catch (e) {
                          goToLibrary!(folderNameTitle);
                        }
                      } else {
                        goToLibrary!(folderNameTitle);
                      }
                    } catch (e) {
                      goToLibrary!(folderNameTitle);
                    }
                  },
                ),
              ));
            }
          } catch (e) {
            logError(e.toString());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Download failed: $e"),
              duration: Duration(seconds: 8),
              action: SnackBarAction(
                  label: "Resolve",
                  onPressed: () {
                    showSettingsDialog(context);
                  }),
            ));
          }
        }
      },
      subtitle: (this.downloadProgress != null)
          ? SizedBox(
              width: 100.0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                minHeight: 5.0,
                value: this.downloadProgress?.toDouble(),
              ),
            )
          : null,
    );
  }
}

class DownloadingTasks with ChangeNotifier {
  DownloadingTasks(int length) : currentDownloading = List.filled(length, false);

  List<bool> currentDownloading;
  void updateDownloadWithIndex(int index, bool value) {
    currentDownloading[index] = value;
    notifyListeners();
  }
}

extension ListGetter<bool> on List<bool> {
  bool? getVal(int index) {
    try {
      return this[index];
    } catch (e) {
      return null;
    }
  }
}

Future<List<BookItemData>?> parseBody(String? url) async {
  List<BookItemData> bookItems = [];
  url = url?.replaceAll("http://125.22.54.221:8080", '');
  final response = await Client().get(Uri.parse('http://125.22.54.221:8080$url'));
  if (response.statusCode == 200) {
    var document = parse(response.body);
    if (document.getElementsByTagName("table").length == 0) {
      return Future.value(null);
    }
    var table = document
        .getElementsByClassName("panel-body")[0]
        .getElementsByTagName("tbody")[0]
        .getElementsByTagName("tr");
    for (var i = 1; i < table.length; i++) {
      var fileName = table[i].getElementsByTagName("td")[0].getElementsByTagName("a")[0].innerHtml;
      var size = table[i].getElementsByTagName("td")[2].innerHtml;
      var itemURL =
          table[i].getElementsByTagName("td")[0].getElementsByTagName("a")[0].attributes['href'];
      bookItems.add(BookItemData(fileName: fileName, size: size, downloadURL: itemURL));
    }
    return Future.value(bookItems);
  }
  return Future.value(null);
}
