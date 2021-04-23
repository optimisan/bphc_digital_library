import 'package:bphc_digital_library/screens/book_list_screen.dart';
import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void Function(bool)? _showLoading;
Function? _getUniLinks;

class CustomPopUpMenu extends StatelessWidget {
  const CustomPopUpMenu(this.showLoading, this.getUniLinks);
  final void Function(bool) showLoading;
  final Function getUniLinks;
  @override
  Widget build(BuildContext context) {
    _showLoading = this.showLoading;
    _getUniLinks = this.getUniLinks;
    return PopupMenuButton<String>(
      onSelected: (value) {
        _onMenuSelect(value, context);
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: "About",
          child: ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Colors.teal.shade200,
            ),
            title: const Text(
              "About",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ),
        const PopupMenuItem(
          value: "Share",
          child: ListTile(
            leading: Icon(
              Icons.share_rounded,
              color: Colors.tealAccent,
            ),
            title: const Text(
              "Share all items",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ),
        const PopupMenuItem(
          value: "Save online",
          child: ListTile(
            leading: Icon(
              Icons.cloud_upload_rounded,
              color: Colors.tealAccent,
            ),
            title: const Text(
              "Save online",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ),
        const PopupMenuItem(
          value: "Open from link",
          child: ListTile(
            leading: Icon(
              Icons.link,
              color: Colors.tealAccent,
            ),
            title: const Text(
              "Open from link",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ),
        const PopupMenuItem(
          value: "Settings",
          child: ListTile(
            leading: Icon(
              Icons.settings,
              color: Colors.orangeAccent,
            ),
            title: const Text(
              "Settings",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ),
      ],
    );
  }
}

void _onMenuSelect(String value, BuildContext context) {
  switch (value) {
    case 'About':
      infoDialog(context);
      break;
    case "Share":
      showShareDialog(context);
      break;
    case "Settings":
      showSettingsDialog(context);
      break;
    case "Save online":
      _showLoading!(true);
      sendToWeb(context, _showLoading);
      break;
    case "Open from link":
      showLinkDialog(context);
  }
}

void showLinkDialog(BuildContext context) async {
  ClipboardData? data = await Clipboard.getData('text/plain');
  TextEditingController controller = TextEditingController(text: data?.text);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Open from link"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(fontSize: 18.0),
              maxLines: null,
              decoration: InputDecoration(
                fillColor: Color(0x557A7A7A),
                filled: true,
                focusColor: Colors.blueGrey,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                    const Radius.circular(25.0),
                  ),
                ),
                hintText: "http://125.22.54.221:8080...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          TextButton(
            child: Text("Open"),
            onPressed: () {
              Navigator.of(context).pop();
              _getUniLinks!(urlFromMenu: controller.text);
            },
          ),
        ],
      );
    },
  );
}

void showSettingsDialog(BuildContext context) async {
  // final dir = context.watch<SearchInputs>().externalDir;
  final box = await Hive.openBox<String>("recents");
  bool recentsExist = box.length > 0;
  final prefs = await SharedPreferences.getInstance();
  bool isDownloads = prefs.getString("storageDirectory") == 'downloads';
  bool saveRecents = prefs.getBool("saveRecents") ?? true;
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Settings"),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    activeColor: Colors.teal,
                    value: isDownloads,
                    onChanged: (value) {
                      if (value == true) {
                        context
                            .read<SearchInputs>()
                            .updateExternalDir('downloads');
                        prefs.setString("storageDirectory", 'downloads');
                      } else {
                        context
                            .read<SearchInputs>()
                            .updateExternalDir('not downloads');
                        prefs.setString("storageDirectory", 'not downloads');
                      }
                      setState(() {
                        isDownloads = value == true;
                      });
                    },
                    title: Text("Use the Downloads directory to save items"),
                    subtitle: Text('Uncheck if downloading fails.'),
                  ),
                  CheckboxListTile(
                      title: Text("Save recent searches"),
                      activeColor: Colors.teal,
                      value: saveRecents,
                      onChanged: (value) {
                        prefs.setBool("saveRecents", value ?? true);
                        setState(() {
                          saveRecents = value ?? true;
                        });
                      }),
                  if (recentsExist)
                    ListTile(
                      trailing: Icon(Icons.delete, color: Colors.redAccent),
                      title: Text("Delete all recent searches"),
                      onTap: () {
                        SearchInputs.deleteAllRecents();
                        setState(() {
                          recentsExist = false;
                        });
                      },
                    ),
                ],
              );
            },
          ),
        );
      });
}

void infoDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: "BPHC Digital Library Mobile Client",
    applicationVersion: "By Akshat",
    // applicationIcon: Image.asset('icon/icon'),
    children: [
      RichText(
        textScaleFactor: 1.2,
        text: TextSpan(
          text: "All Items are saved in the ",
          children: [
            TextSpan(
              text: "Downloads",
              style: TextStyle(color: Colors.blueAccent),
            ),
            TextSpan(text: " folder in the format "),
            TextSpan(
                text: "BookName_issue-date",
                style: TextStyle(
                    color: Colors.tealAccent, fontStyle: FontStyle.italic)),
            TextSpan(
                text:
                    ". The library page lists those files.\n\nShare your items by clicking on the share option in the previous menu.\n")
          ],
        ),
      ),
      RichText(
        textScaleFactor: 1.2,
        text: TextSpan(
            text:
                "This app gets all data from the BPHC Digital Library website (http://125.22.54.221:8080/jspui)"),
      ),
      RichText(
        textScaleFactor: 1.2,
        text: TextSpan(
          text: "Click here if you find errors.",
          style: TextStyle(color: Colors.redAccent),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final logs = await getErrors();
              final Uri _emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'f20200284@hyderabad.bits-pilani.ac.in',
                  queryParameters: {
                    'subject': 'BPHC Digital Library app',
                    'body': logs,
                  });
              try {
                launch(_emailLaunchUri.toString().replaceAll("+", " "));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Could not open"),
                ));
              }
            },
        ),
      ),
    ],
  );
}

void showShareDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Share items as URLs"),
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Share as: "),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: Colors.tealAccent,
                ),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    "App links (recommended)",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                isThreeLine: true,
                subtitle: Text(
                    "Links of the form http://bphc.to?http://125... which will be opened by this app. These URLs do not represent a real website and cannot be opened with a browser directly."),
                onTap: () {
                  _shareAll(context, true);
                },
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  Icons.language_sharp,
                  color: Colors.orangeAccent,
                ),
                title: Text("Direct links"),
                subtitle: Text(
                    "Links as they appear on the website which can be opened by a browser. Communication apps might not detect and make these URLs clickable from their apps."),
                onTap: () {
                  _shareAll(context, false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        );
      });
}

void _shareAll(BuildContext context, bool asAppLinks) async {
  final share = await getHistory(asAppLinks);
  Navigator.of(context).pop();
  if (share == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("No items to share. Download something first! :)"),
    ));
  } else {
    Share.share(share);
  }
}
