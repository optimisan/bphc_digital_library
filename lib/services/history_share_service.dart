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
bool webSaved = false;

///Adds the url and related file info to the history box.
///File name is grabbed from the url, so it is url encoded
void addToHistory({required String title, required String url}) async {
  webSaved = false;
  print(url);
  final uri = Uri.parse(url);
  final paths = uri.pathSegments;
  final fileName = paths[paths.length - 1].replaceAll("%20", ' ');
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

void addBookToHistory(String? url, String? bookName) async {
  if (url != null && bookName != null) {
    print(bookName);
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
    StringBuffer sb = new StringBuffer('My files from BPHC Digital Library:\n');
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

      String str = "$book\n$name: $fileUrl\n\n";
      if (forWeb) {
        if (urlMap[book] != null) {
          urlMap[book]?.add('<a href="$fileUrl" target="_blank">$name</a>');
        } else {
          urlMap[book] = [];
          urlMap[book]?.add('<a href="$fileUrl" target="_blank">$name</a>');
        }
        str =
            "<br><b>$book</b><br><i>$name</i>: <a href = \"$fileUrl\" target=\"_blank\"> $fileUrl</a><br>";
      }
      sb.write(str);
    }
    if (forWeb) {
      sb.write("Last updated: ${DateTime.now()}");
    } else
      sb.write("\nShared using the BPHC Digital Library Mobile app");
    return sb.toString();
  }
}

///Delete the file from history.
///Set `isABook` to true if deleting the whole book
void deleteFromHistory(
    {required String bookName, String? fileName, bool isABook = false}) async {
  // fileName = fileName?.replaceAll("%20", ' ');
  fileName = Uri.decodeComponent(fileName ?? 'error');
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
      print(bookName + "is orig bookname");
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
Future<void> sendToWeb(BuildContext context) async {
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
    if (webSaved == false) {
      webSaved = true;
      response = await post(url, body: {
        'data': history,
        'uid': prefs.getInt('uid').toString(),
      });
      if (response.statusCode == 200) {
        print(response.body);
        showWebDialog(context, response.body);
        // return response.body;
      }
    } else {
      showWebDialog(context, response.body);
    }

    print("done post");
  }
}

void showWebDialog(BuildContext context, String? urlReceived) {
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
                      Text(urlReceived ?? 'Error',
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
