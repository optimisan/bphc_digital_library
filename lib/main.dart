import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:bphc_digital_library/screens/book_list_screen.dart';
import 'package:bphc_digital_library/screens/search_screen.dart';
import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:bphc_digital_library/widgets/popup_menu_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:bphc_digital_library/services/url_opener_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/library_screen.dart';
import 'screens/items_screen.dart';
import 'package:flutter/material.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;

late final String externalDir;
late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FlutterDownloader.initialize(
        debug: true // optional: set false to disable printing logs to console
        );
    // Directory appDocDirectory = await getApplicationDocumentsDirectory();
    // final externalDir = await getExternalStorageDirectory();
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("saveRecents") == null) {
      prefs.setBool("saveRecents", true);
    }
    if (prefs.getString('storageDirectory') == null) {
      prefs.setString('storageDirectory', 'downloads');
    }
    if (prefs.getString('storageDirectory') == 'downloads') {
      externalDir = await AndroidPathProvider.downloadsPath;
    } else {
      Directory? dir = await getExternalStorageDirectory();
      if (dir == null) {
        dir = await getApplicationDocumentsDirectory();
      }
      externalDir = dir.path;
    }
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    // if (externalDir != null)
    // await Directory('$externalDir/BPHC_Downloads').create();
    runApp(MyApp());
  } catch (e) {
    runApp(FailScreen(e.toString()));
  }
}

Future<String?> initUniLinks() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    final initialLink = await getInitialLink();
    // Parse the link and warn the user, if it is not correct,
    // but keep in mind it could be `null`.
    return initialLink;
  } on PlatformException {
    // Handle exception by warning the user their action did not succeed
    // return?
  }
}

class FailScreen extends StatelessWidget {
  const FailScreen(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

void downloadCallback(id, status, progress) {}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEnter() {
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchInputs>(
      create: (BuildContext context) => SearchInputs(externalDir),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Digital Library',
          theme: ThemeData.dark(),
          home: HomePage(),
          // home: Scaffold(
          //   backgroundColor: Color(0xFF000216),
          //   appBar: AppBar(
          //     automaticallyImplyLeading: false,
          //     title: Text("  BPHC Digital Library"),
          //     backgroundColor: Colors.transparent,
          //     elevation: 0.0,
          //     actions: [
          //       Padding(
          //         padding: const EdgeInsets.only(right: 12.0),
          //         child: IconButton(
          //           icon: Icon(Icons.info_outline_rounded),
          //           onPressed: () {
          //             infoDialog(context);
          //           },
          //         ),
          //       )
          //     ],
          //     bottom: TabBar(controller: _tabController, tabs: [
          //       Tab(text: "Library"),
          //       Tab(text: "Search"),
          //       Tab(text: "Items"),
          //     ]),
          //   ),
          //   body: ChangeNotifierProvider<SearchInputs>(
          //     create: (BuildContext context) => SearchInputs(),
          //     builder: (context, _) {
          //       return TabBarView(
          //         controller: _tabController,
          //         children: [
          //           LibraryScreen(onEnter: _onEnter),
          //           SearchScreen(onEnter: _onEnter),
          //           ItemsScreen(),
          //         ],
          //       );
          //     },
          //   ),
          // ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool? linkOpened;
  String? querySubj;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    FlutterDownloader.registerCallback(downloadCallback);
    getUniLinks();
  }

  void showLoading() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        linkOpened = true;
      });
    });
  }

  void getUniLinks() async {
    String? link = await initUniLinks();
    if (link != null) {
      showLoading();
      link = link.replaceAll(RegExp(r"https?:\/\/bphc.to\/?\?"), '');
      var urlResult = await parseURL(link);
      // print(isFileList);
      if (urlResult == null || urlResult['status'] == 'invalid') {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            linkOpened = false;
          });
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Invalid URL'),
                  content: RichText(
                    textScaleFactor: 1.2,
                    text: TextSpan(text: "The URL ", children: [
                      TextSpan(
                          text: link,
                          style: TextStyle(color: Colors.lightBlueAccent)),
                      TextSpan(
                        text:
                            ' is not a valid BPHC DSpace link. You might want to check again.',
                      ),
                    ]),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        });
        return;
      } else if (urlResult['status'] == 'error') {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            linkOpened = false;
          });
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: RichText(
                    textScaleFactor: 1.2,
                    text: TextSpan(text: "The URL ", children: [
                      TextSpan(
                          text: link,
                          style: TextStyle(color: Colors.lightBlueAccent)),
                      TextSpan(
                        text:
                            ' could not be opened because ${urlResult["message"]}',
                      ),
                    ]),
                  ),
                  actions: [
                    TextButton(
                      child: Text("Try the browser"),
                      onPressed: () async {
                        try {
                          if (link != null) await launch(link);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Could not open url: $e"),
                          ));
                        }
                      },
                    ),
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        });
        return;
      } else if (urlResult['status'] == 'isDownloadLink') {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            linkOpened = false;
          });
          showDialog(
              context: context,
              builder: (context) {
                return getAlertDialog(
                  context,
                  title: urlResult['message'] ?? 'Error',
                  folderName: urlResult['folderName'],
                  actions: [],
                  isForDownload: true,
                  link: link ?? 'error url',
                  setState: () {
                    setState(() {});
                  },
                  searchFunction: () {
                    _onEnter(2);
                  },
                );
              });
        });
      } else if (urlResult['status'] == 'isASearch') {
        final uri = Uri.parse(link);
        final querySubject = uri.queryParameters['query'];
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            this.linkOpened = false;
          });
        });
        if (querySubject != null) {
          context.read<SearchInputs>().updateSubjectSearch(querySubject);
          _onEnter(2);
        }
      } else if (urlResult['status'] == 'isCollection') {
        //TODO: Implement collections
      } else {
        print("launching url");
        final bookName = await getBookName(link);
        if (bookName != null) {
          linkOpened = false;
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BookListScreen(
                    listenToPort: false,
                    updateListen: () {
                      Provider.of<SearchInputs>(context)
                          .alreadyListeningToPort = true;
                    },
                    bookURL: link,
                    bookName: bookName,
                    toLibrary: (String book) {
                      Provider.of<SearchInputs>(context, listen: false)
                          .showInLibraryTitle = book;
                      _onEnter(0);
                    },
                    folderName: bookName,
                  )));
          setState(() {
            this.linkOpened = false;
          });
        } else {
          WidgetsBinding.instance?.addPostFrameCallback((_) {
            setState(() {
              linkOpened = false;
            });
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Failed to load URL'),
                    content: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                          "The URL $link possibly leads to a non-existent page, or just could not be loaded"),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text("Open in browser"),
                        onPressed: () async {
                          try {
                            if (link != null) await launch(link);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Could not open url: $e"),
                            ));
                          }
                        },
                      ),
                    ],
                  );
                });
          });
        }
      }
    }
    print(link);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEnter(int screenNumber) {
    setState(() {
      linkOpened = false;
    });
    _tabController.animateTo(screenNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000216),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("  BPHC Digital Library"),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          // Padding(
          //   padding: const EdgeInsets.only(right: 5.0),
          //   child: IconButton(
          //     icon: Icon(Icons.info_outline_rounded),
          //     onPressed: () {
          //       infoDialog(context);
          //     },
          //   ),
          // ),
          //
          //
          // Padding(
          //   padding: const EdgeInsets.only(right: 8.0),
          //   child: IconButton(
          //     icon: Icon(Icons.share),
          //     tooltip: "Share all items",
          //     onPressed: () {
          //       showShareDialog(context);
          //     },
          //   ),
          // ),
          CustomPopUpMenu(),
        ],
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: "Library"),
          Tab(text: "Search"),
          Tab(text: "Items"),
        ]),
      ),
      body: ModalProgressHUD(
        inAsyncCall: this.linkOpened ?? false,
        child: TabBarView(
          controller: _tabController,
          children: [
            LibraryScreen(onEnter: () {
              _onEnter(2);
            }),
            SearchScreen(onEnter: () {
              _onEnter(2);
            }),
            ItemsScreen(
              returnToLibrary: () {
                _onEnter(0);
              },
            ),
          ],
        ),
      ),
    );
  }
}

//AlertDialog(
//   title: Text(urlResult['message'] ?? 'Error'),
//   actions: [
//     TextButton(
//       onPressed: () async {
//         await downloadFromURL(
//             link?.replaceAll("http://125.22.54.221:8080", ''),
//             context,
//             folderName: "Downloads");
//         Navigator.of(context).pop();
//         setState(() {});
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text("Download started."),
//         ));
//       },
//       child: Text("Download"),
//     ),
//     TextButton(
//       onPressed: () {
//         Navigator.of(context).pop();
//       },
//       child: Text("Cancel"),
//     ),
//   ],
// );
