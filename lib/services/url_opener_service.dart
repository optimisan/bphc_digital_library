import 'dart:io';

import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'download_helper.dart';

Future<Map<String, String?>?> parseURL(String? link) async {
  if (link != null) {
    final regexp =
        RegExp(r'http:\/\/125.22.54.221:8080\/jspui\/(handle|bitstream|simple-search|browse)\/?.+');
    final isValid = regexp.hasMatch(link);
    if (!isValid) {
      return {'status': 'invalid'};
    }
    var uri;
    try {
      uri = Uri.parse(link);
    } catch (e) {
      return {'status': 'error', 'message': 'it\'s not even a valid url what the heck'};
    }
    final folderName = uri.queryParameters['folder'];
    final paths = uri.pathSegments;
    try {
      if (paths[1] == 'handle') {
        return await checkIf404orNot(link);
      } else if (paths[1] == 'bitstream') {
        final is404 = await checkIf404orNot(link, isDownloadLink: true);
        if (is404['status'] == 'error') {
          return is404;
        }
        return {
          'status': 'isDownloadLink',
          'message': 'Download ${paths[paths.length - 1]}?',
          'folderName': folderName != null ? Uri.decodeComponent(folderName) : null,
        };
      } else if (paths[1] == 'simple-search') {
        return {'status': 'isASearch'};
      } else {
        return {
          'status': 'error',
          'message':
              '"browse" links are not yet supported. Only search queries, file lists and downloads are supported. View in the browser instead.'
        };
      }
    } catch (e) {
      return null;
    }
  }
}

Future<Map<String, String>> checkIf404orNot(String url, {bool isDownloadLink = false}) async {
  try {
    final result = await InternetAddress.lookup('example.com');

    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      final existRes = await head(Uri.parse(url));
      if (existRes.statusCode != 200) {
        return {'status': 'error', 'message': 'the resource does not exist on the server.'};
      }
      if (isDownloadLink) return {'status': 'success'};

      final response = await Client().get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        if (document.getElementsByTagName("table").length > 0) {
          final table = document.getElementsByClassName("table")[0];
          if (table.getElementsByTagName("colgroup").length > 0) {
            return {
              'status': 'error',
              'message':
                  '\'Collections\' are not supported at the moment. Only search queries, file lists and downloads are supported. View in the browser instead.'
            };
          }
          return {'status': 'isFileList'};
        } else
          return {
            'status': 'error',
            'message':
                'it does not contain any items. Only links which contain items (list of books or the files) are supported by this app.'
          };
      } else {
        return {'status': 'error', 'message': 'the resource does not exist on the server.'};
      }
    } else {
      return {'status': 'error', 'message': 'the resource does not exist on the server.'};
    }
  } on SocketException catch (_) {
    return {'status': 'error', 'message': 'your device is not connected to the internet.'};
  }
}

Future<String?> getBookName(String url) async {
  final response = await Client().get(Uri.parse(url));
  if (response.statusCode == 200) {
    final document = parse(response.body);
    final els = document.getElementsByClassName("dc_title");
    final element = els[els.length - 1];
    return element.innerHtml.replaceAll("&#x20;", " ");
  }
}

Widget getAlertDialog(BuildContext context,
    {required String title,
    Widget? content,
    required List<Widget> actions,
    bool isForDownload = false,
    String link = '',
    Function? setState,
    String? folderName,
    Function? searchFunction}) {
  if (isForDownload) {
    final controller = TextEditingController(text: folderName);
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          folderName == null
              ? Text(
                  "Enter the folder name in which you want to save this file (default is 'Downloads')\nEx. Computer Programming_2019-20")
              : Text("File will be saved to the folder $folderName. You can change it here."),
          SizedBox(height: 15),
          TextField(
            controller: controller,
            style: TextStyle(fontSize: 18.0),
            maxLines: null,
            decoration: InputDecoration(
              fillColor: Color(0x557A7A7A),
              filled: true,
              focusColor: Colors.blueGrey,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(25.0),
                ),
              ),
              hintText: "Folder_year",
            ),
          ),
          SizedBox(height: 15),
          (folderName == null)
              ? Text("Year is optional")
              : OpenInSearchButton(
                  folderName: folderName,
                  onClick: searchFunction,
                ),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text("Download"),
          onPressed: () async {
            try {
              link = link.replaceAll(RegExp(r'\?folder=.+$'), '');
              print("Url is $link");
              await downloadFromURL(link.replaceAll("http://125.22.54.221:8080", ''), context,
                  folderName: controller.text.trim() == ''
                      ? 'Downloads'
                      : controller.text.replaceAll('\n', ''));
              Navigator.of(context).pop();
              setState!();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Download started."),
              ));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Download failed: $e"),
              ));
            }
          },
        ),
      ],
    );
  }
  return AlertDialog(
    title: Text(title),
    content: content,
    actions: actions,
  );
}

class OpenInSearchButton extends StatelessWidget {
  const OpenInSearchButton({Key? key, required this.folderName, this.onClick}) : super(key: key);
  final String folderName;
  final Function? onClick;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final regex = RegExp(r'_\d+-?\d+');
        final date = regex.firstMatch(folderName)?.group(0)?.replaceAll("_", '');
        final name = folderName.replaceAll(RegExp(r'_\d+-?\d+'), '');
        String url = '';
        if (date != null)
          url =
              '$name&rpp=10&sort_by=score&order=desc&filter_field_1=title&filter_type_1=equals&filter_value_1=$name&filter_field_2=dateIssued&filter_type_2=contains&filter_value_2=$date';
        else {
          url = '$name';
        }
        Navigator.of(context).pop();
        await Provider.of<SearchInputs>(context, listen: false)
            .updateSubjectSearch(url, fromLibraryBrowse: true);

        try {
          onClick!();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Could not open url: $e"),
          ));
        }
      },
      icon: Icon(Icons.search),
      label: Container(
          constraints: BoxConstraints(maxWidth: 240), child: Text("Open in search instead")),
      style: ElevatedButton.styleFrom(
        elevation: 1.0,
        primary: Color(0xFF343434),
      ),
    );
  }
}
