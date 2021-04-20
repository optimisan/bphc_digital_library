import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_share_service.dart';

Future<void> downloadFromURL(String? url, BuildContext context,
    {required String? folderName}) async {
  final status = await Permission.storage.request();
  if (status.isGranted && url != null) {
    // final externalDir1 = await getExternalStorageDirectory();
    var externalDir;
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString("storageDirectory") == 'downloads')
      externalDir = await AndroidPathProvider.downloadsPath;
    else {
      Directory? appDocDirectory = await getExternalStorageDirectory();
      if (appDocDirectory == null) {
        appDocDirectory = await getApplicationDocumentsDirectory();
      }
      externalDir = appDocDirectory.path;
    }
    print(externalDir);
    // Directory appDocDirectory = await getApplicationDocumentsDirectory();
    late String path;
    if (folderName == null) {
      path = Directory('$externalDir/BPHC_Downloads').path;
    } else {
      // folderName = folderName.replaceAll(" ", "_");
      try {
        await Directory('$externalDir/BPHC_Downloads/$folderName').create();
      } catch (e) {
        logError(e.toString());
        await Directory('$externalDir/BPHC_Downloads').create();
        await Directory('$externalDir/BPHC_Downloads/$folderName').create();
      }
      path = Directory('$externalDir/BPHC_Downloads/$folderName').path;
    }
    try {
      final taskId = await FlutterDownloader.enqueue(
        url: 'http://125.22.54.221:8080$url',
        savedDir: path,
        showNotification: true,
        openFileFromNotification: true,
      );
      addToHistory(
          title: folderName ?? 'Files', url: 'http://125.22.54.221:8080$url');
    } catch (e) {
      logError(e.toString());
    }
  } else {
    print("Denied permission");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              "Could not download: permission denied. Allow storage access and try again.")),
    );
  }
}

Future<bool> checkInternet() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}
