import 'dart:math';

import 'package:bphc_digital_library/screen_provider.dart';
import 'package:bphc_digital_library/services/history_share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import '../main.dart';
import 'popup_menu_widget.dart';

void Function(bool)? _showLoading;
Function? _getUniLinks;

class CustomDrawer extends StatelessWidget {
  const CustomDrawer(this.showLoading, this.getUniLinks);
  final void Function(bool) showLoading;
  final Function getUniLinks;
  @override
  Widget build(BuildContext context) {
    _showLoading = this.showLoading;
    _getUniLinks = this.getUniLinks;
    try {
      if (prefs.getInt('uid') == null) {
        Random random = new Random();
        int randomNumber = random.nextInt(9999999) + 100000;
        prefs.setInt('uid', randomNumber);
      }
    } catch (e) {}
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 140,
                  child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/background.png"),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5), BlendMode.srcOver),
                      ),
                    ),
                    accountName: Text("BPHC Digital Library",
                        style: TextStyle(fontSize: 20)),
                    accountEmail: Text("For the students of BPHC"),
                    // accountEmail: Text(
                    //   'User: ${prefs.getInt('uid')}',
                    // ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.library_books_rounded,
                    color: Colors.tealAccent,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<ScreenManager>().updateScreen('home');
                  },
                  title: const Text("Library"),
                ),
                ListTile(
                  leading: Icon(
                    Icons.share_outlined,
                    color: Colors.tealAccent,
                  ),
                  onTap: () async {
                    await showShareDialog(context);
                  },
                  title: const Text(
                    "Share all items",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
                // ListTile(
                //   leading: Icon(
                //     Icons.cloud_upload_rounded,
                //     color: Colors.tealAccent,
                //   ),
                //   onTap: () {
                //     Navigator.of(context).pop();
                //     _showLoading!(true);
                //     sendToWeb(context, _showLoading);
                //   },
                //   title: const Text(
                //     "Save online",
                //     style: const TextStyle(color: const Color(0xFFFEFEFE)),
                //   ),
                // ),
                ListTile(
                  leading: Icon(
                    Icons.link,
                    color: Colors.tealAccent,
                  ),
                  onTap: () async {
                    await showLinkDialog(context);
                    Navigator.of(context).pop();
                    context.read<ScreenManager>().updateScreen("home");
                  },
                  title: const Text(
                    "Open from link",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.message, color: Colors.tealAccent),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<ScreenManager>().updateScreen('messages');
                  },
                  title: const Text(
                    "Announcements",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Colors.tealAccent,
                  ),
                  onTap: () {
                    showSettingsDialog(context);
                  },
                  title: const Text(
                    "Settings",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.share_rounded,
                    color: Colors.purpleAccent,
                  ),
                  onTap: () {
                    Share.share(
                        'Download the BPHC Digital Library from the Play Store now!\nhttps://play.google.com/store/apps/details?id=com.akshat.bphc_digital_library');
                  },
                  title: const Text(
                    "Share this app!",
                    style: const TextStyle(color: const Color(0xFFFEFEFE)),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Colors.tealAccent,
            ),
            onTap: () {
              infoDialog(context);
            },
            title: const Text(
              "About",
              style: const TextStyle(color: const Color(0xFFFEFEFE)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showLinkDialog(BuildContext context) async {
  ClipboardData? data = await Clipboard.getData('text/plain');
  TextEditingController controller = TextEditingController(text: data?.text);
  return await showDialog(
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
