import 'package:hive/hive.dart';

Box<Map<dynamic, dynamic>>? historyBox;
List<String> recentBookNames = [];

///Adds the url and related file info to the history box.
///File name is grabbed from the url, so it is url encoded
void addToHistory({required String title, required String url}) async {
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
  var shareUrl = 'http://bphc.to?$url?folder=$title';
  var encoded = Uri.encodeFull(shareUrl);
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

Future<String?> getHistory(bool asAppLinks) async {
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
      final str = "$book\n$name: $fileUrl\n\n";
      sb.write(str);
    }
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
