import 'package:android_path_provider/android_path_provider.dart';
import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/search_results_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

final regexp = RegExp(r'.+?&');

class SearchInputs with ChangeNotifier {
  SearchInputs(this.externalDir, {this.subject});
  String externalDir;
  int year = 1;
  String? branch;
  String? searchStatus;
  String? subject;
  String? subjectToDisplay;
  List<BookData> books = [];
  String? showInLibraryTitle;
  String? searchInfo;
  bool alreadyListeningToPort = false;
  int currentPage = 0;
  int totalPages = 1;
  void updateExternalDir(String newDir) async {
    if (newDir == 'downloads') {
      externalDir = await AndroidPathProvider.downloadsPath;
    } else {
      final dir = await getExternalStorageDirectory();
      if (dir != null)
        externalDir = dir.path;
      else {
        logError("ExternalStorageDirectory is null");
      }
    }
    notifyListeners();
  }

  Future<void> updateSubjectSearch(String subjectString,
      {bool fromLibraryBrowse = false}) async {
    this.searchStatus = "loading";
    notifyListeners();

    this.subject = subjectString.replaceAll(" ", "+");
    this.subjectToDisplay =
        regexp.firstMatch(this.subject ?? '')?.group(0) ?? this.subject;
    await this.parseBody();
    if (this.searchStatus != "Nothing found") this.searchStatus = "done";
    if (fromLibraryBrowse != true && prefs.getBool("saveRecents") == true) {
      try {
        final box = await Hive.openBox<String>('recents');
        if (!box.values.contains(subjectToDisplay)) {
          box.add(subjectToDisplay ?? subjectString);
        }
      } catch (e) {}
    }
    return Future.value();
  }

  static void deleteAllRecents() async {
    try {
      final box = await Hive.openBox<String>('recents');
      box.deleteFromDisk();
      clearErrorLogs();
    } catch (e) {}
  }

  Future<void> updateSearchByBrowseBook(String searchQuery) async {
    this.searchStatus = "loading";
    notifyListeners();

    this.subjectToDisplay =
        regexp.firstMatch(searchQuery)?.group(0)?.replaceAll("&", '');
    this.subject = searchQuery.replaceAll(" ", "+");

    await this.parseBody();
    if (this.searchStatus != "Nothing found") this.searchStatus = "done";
    return Future.value();
  }

  Future<void>? search(BuildContext context) async {
    if (this.subject != null) {
      final url1 = Uri.parse(
          'http://125.22.54.221:8080/jspui/simple-search?query=${this.subject?.replaceAll(" ", "+")}');
      // make GET request
      // String url = 'https://jsonplaceholder.typicode.com/posts';
      // Response response = await get(url);
      // // sample info available in response
      // int statusCode = response.statusCode;
      // Map<String, String> headers = response.headers;
      // String? contentType = headers['content-type'];
      // String body = response.body;
      // return await parseBody(body);
    }
  }

  Future<void> parseBody({bool? nextPage}) async {
    late final Response response;
    print(this.currentPage);
    print(this.totalPages);

    if (nextPage != true) {
      this.books = [];
      this.currentPage = 0;
      response = await Client().get(Uri.parse(
          'http://125.22.54.221:8080/jspui/simple-search?query=${this.subject?.replaceAll(" ", "+")}'));
    } else if (this.currentPage < this.totalPages - 1) {
      response = await Client().get(Uri.parse(
          'http://125.22.54.221:8080/jspui/simple-search?query=${this.subject?.replaceAll(" ", "+")}&sort_by=score&order=desc&rpp=10&etal=0&start=${(++this.currentPage) * 10}'));
    } else {
      return Future.value();
    }
    if (response.statusCode == 200) {
      var document = parse(response.body);
      final len = document.getElementsByTagName("table").length;

      try {
        final regexp = RegExp(r' \d+ ');
        this.searchInfo = regexp
            .firstMatch(
                document.getElementsByClassName("alert-info")[0].innerHtml)
            ?.group(0);
      } catch (e) {
        this.searchInfo = '';
      }

      if (document.getElementsByTagName("table").length == 0) {
        this.searchStatus = "Nothing found";
        print("Nothing");
        notifyListeners();
        return Future.value();
      }
      try {
        var table = document
            .getElementsByTagName("table")[len - 1]
            .getElementsByTagName("tbody")[0]
            .getElementsByTagName("tr");

        var ul = document.getElementsByClassName("pagination")[0];
        this.totalPages = ul.getElementsByTagName("li").length - 2;

        for (var i = 1; i < table.length; i++) {
          var book = table[i];
          String issueDate = book
              .getElementsByTagName("td")[0]
              .getElementsByTagName("em")[0]
              .innerHtml;
          String title = book
              .getElementsByTagName("td")[1]
              .getElementsByTagName("a")[0]
              .innerHtml;
          String? bookURL = book
              .getElementsByTagName("td")[1]
              .getElementsByTagName("a")[0]
              .attributes['href'];
          String bookAuthor = book
              .getElementsByTagName("td")[2]
              .getElementsByTagName("em")[0]
              .getElementsByTagName("a")[0]
              .innerHtml;

          this.books.add(BookData(
              issueData: issueDate,
              title: title,
              url: bookURL,
              author: bookAuthor));
        }
        notifyListeners();
      } catch (e) {
        print("Oops $e");
        this.searchStatus = "Nothing found";
        notifyListeners();
      }
    }
  }

  void updateShowInLibrary(String? withThis) {
    this.showInLibraryTitle = withThis;
    notifyListeners();
  }
}
