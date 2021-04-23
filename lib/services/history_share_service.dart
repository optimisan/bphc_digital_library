import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Box<Map<dynamic, dynamic>>? historyBox;
List<String> recentBookNames = [];

///Adds the url and related file info to the history box.
///File name is grabbed from the url, so it is url encoded
void addToHistory({required String title, required String url}) async {
  _webUpdated(false);
  print(url);
  final uri = Uri.parse(url);
  final paths = uri.pathSegments;
  final fileName = Uri.decodeComponent(paths[paths.length - 1]);
  historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  // if (historyBox != null) {
  //   historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  // }
  if (!recentBookNames.contains(title)) {
    recentBookNames.add(title);
  }
  title = Uri.encodeComponent(title);
  var shareUrl = 'http://bphc.to?$url?folder=$title';
  var encoded = shareUrl;
  historyBox?.add({
    'isABook': false,
    'bookName': title,
    'fileName': fileName,
    'url': encoded
  });
}

/// Adds book to history, setting `isABook` to true.
void addBookToHistory(String? url, String? bookName) async {
  if (url != null && bookName != null) {
    _webUpdated(false);
    if (!recentBookNames.contains(bookName)) {
      historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
      var addThis = {
        'isABook': true.toString(),
        'bookName': bookName,
        'url': "http://bphc.to?http://125.22.54.221:8080$url",
      };
      if (historyBox?.values.contains(addThis) != true)
        historyBox?.add(addThis);
    }
  }
}

Future<String?> getBookLink(String bookName) async {
  historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  bookName = bookName.replaceFirst("__", '_');
  print("Book name = $bookName");
  if (historyBox != null) {
    if (historyBox!.length == 0)
      return null;
    else {
      for (var i = 0; i < historyBox!.length; i++) {
        final historyMap = historyBox?.getAt(i);
        print(historyMap);

        if (historyMap?['bookName'] == bookName &&
            historyMap?['isABook'] == true.toString()) {
          return historyMap?['url'];
        }
      }
    }
  }
}

Future<String?> getHistory(bool asAppLinks, {bool forWeb = false}) async {
  Map<String, List<String>> urlMap = {};
  historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  if (historyBox != null) {
    if (historyBox!.length == 0) {
      return null;
    }
    StringBuffer sb = new StringBuffer();
    if (!forWeb) {
      sb.write("My files from BPHC Library:");
    }
    for (var i = 0; i < historyBox!.length; i++) {
      if (historyBox?.getAt(i)?['isABook'] == true.toString()) continue;
      final book = historyBox?.getAt(i)?['bookName'];
      final name = historyBox?.getAt(i)?['fileName'];
      final fileUrl = (asAppLinks == true)
          ? (historyBox?.getAt(i)?['url'])
          : historyBox
              ?.getAt(i)?['url']
              .toString()
              .replaceAll("http://bphc.to?", '');

      // String str = "$book\n$name: $fileUrl\n\n";
      if (urlMap[book] != null) {
        if (forWeb)
          urlMap[book]?.add('<a href="$fileUrl" target="_blank">$name</a>');
        else
          urlMap[book]?.add('$name: $fileUrl');
      } else {
        urlMap[book] = [];
        if (forWeb)
          urlMap[book]?.add('<a href="$fileUrl" target="_blank">$name</a>');
        else
          urlMap[book]?.add('$name: $fileUrl');
      }
    }
    if (forWeb) {
      // sb.write("Last updated: ${DateTime.now()}");
      print(urlMap);
      return shareForWeb(urlMap);
    } else
      return shareFormatted(urlMap, sb);
  }
}

String? shareFormatted(Map<String, List<String>> urlMap, StringBuffer sb) {
  if (urlMap.length == 0) return null;
  urlMap.forEach((bookName, fileList) {
    sb.write('\n*$bookName\n');
    for (String file in fileList) {
      sb.write('$file\n');
    }
  });
  return sb.toString();
}

///Delete the file from history.
///Set `isABook` to true if deleting the whole book
void deleteFromHistory(
    {required String bookName, String? fileName, bool isABook = false}) async {
  _webUpdated(false);
  bookName = Uri.encodeComponent(bookName);
  // fileName = fileName?.replaceAll("%20", ' ');
  // fileName = Uri.decodeComponent(fileName ?? 'error');
  if (historyBox == null) {
    historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  }
  if (historyBox != null) {
    print(
        "Book name is $bookName and file is $fileName and length = ${historyBox?.length}");
    //Looping for everything
    var index;
    final int length = historyBox?.length ?? 0;
    for (index = 0; index < length; index++) {
      final Map<dynamic, dynamic> file =
          historyBox!.getAt(index) ?? {'fileName': '___'};
      print("loop $index");
      //Delete the file if the bookName and fileName matches,
      //or delete it without looking at fileName if it is a book
      //that we are deleting

      print(bookName + "is orig bookname and ${file['bookName']} is saved");
      print(historyBox?.getAt(index));
      if (file['bookName'] == bookName &&
          (isABook || file['fileName'] == fileName)) {
        historyBox?.deleteAt(index);
        if (!isABook) break;
      }
    }
  }
}

///Use for the `delete all` button.
void deleteAllHistory() async {
  _webUpdated(false);
  if (historyBox == null) {
    historyBox = await Hive.openBox<Map<dynamic, dynamic>>("history");
  }
  historyBox?.deleteFromDisk();
}

class ShareBookData {
  const ShareBookData(
      {required this.bookUrl, required this.items, required this.bookName});
  final String bookName;
  final String bookUrl;
  final List<Map<String, String>> items;
}

var response;

/// Upload contents to the web.
Future<void> sendToWeb(BuildContext context, Function? loadingOver) async {
  String? urlReceived;
  final history = await getHistory(false, forWeb: true);
  if (history == null) {
  } else {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('uid') == null) {
      Random random = new Random();
      int randomNumber = random.nextInt(9999999) + 100000;
      prefs.setInt('uid', randomNumber);
    }
    var url = Uri.parse('http://mirasma.ga/share-text.php');
    if (prefs.getBool('allowed to send to web') == true) {
      _webUpdated(true);
      response = await post(url, body: {
        'data': history,
        'uid': prefs.getInt('uid').toString(),
        'time': DateTime.now().toString(),
      });
      if (response.statusCode == 200) {
        loadingOver!(false);
        showWebDialog(context, urlReceived: response.body);
        // return response.body;
      }
    } else {
      loadingOver!(false);
      showWebDialog(context, uid: prefs.getInt('uid').toString());
    }

    print("done post");
  }
}

///Returns the history as HTML to post to website
String shareForWeb(Map<String, List<String>> m) {
  StringBuffer sb = new StringBuffer();
  final regex = RegExp(r'_\d+\-?.*');
  m.forEach((bookName, fileList) {
    final decoded = Uri.decodeComponent(bookName).replaceAll(regex, '');
    final issueDate =
        regex.firstMatch(bookName)?.group(0)?.replaceAll("_", '') ?? '';
    sb.write('''<div><div class="uk-card uk-card-default uk-card-body">
              <h3 class="uk-card-title">$decoded</h3>
              <span class="uk-label">$issueDate</span>
                 <ul class="uk-list uk-list-striped">''');
    for (String file in fileList) {
      sb.write('<li>$file</li>');
    }
    sb.writeln("</ul></div></div>");
  });
  sb.writeln('<p>Last updated: ${DateTime.now()}</p>');
  return sb.toString();
}

void showWebDialog(BuildContext context, {String? urlReceived, String? uid}) {
  showBottomSheet(
      context: context,
      builder: (context) {
        return Container(
            color: Colors.grey[900],
            height: 300,
            child: ChangeNotifierProvider<WebSave>(
              create: (BuildContext context) => WebSave(),
              builder: (context, webSave) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(height: 10),
                      Text("Items saved! Visit this url in your browser: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          )),
                      Text(urlReceived ?? 'http://mirasma.ga/bphc.php?uid=$uid',
                          style: TextStyle(fontWeight: FontWeight.w300)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Close"),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: urlReceived));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Copied!"),
                              ));
                            },
                            child: Text("Copy link"),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(),
                            onPressed: () {
                              if (urlReceived != null) launch(urlReceived);
                            },
                            child: Text("Open link"),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ));
      });
}

class InsideWebSave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class WebSave with ChangeNotifier {
  bool loading = false;
  String url = '';
  void updateLoading(bool val) {
    loading = val;
    notifyListeners();
  }

  void updateUrl(String u) {
    url = u;
    notifyListeners();
  }
}

void _webUpdated(bool val) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('allowed to send to web', !val);
}
