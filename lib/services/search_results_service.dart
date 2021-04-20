import 'package:flutter/material.dart';

class BookData {
  const BookData(
      {required this.title,
      required this.issueData,
      required this.url,
      required this.author});
  final String title;
  final String issueData;
  final String? url;
  final String author;
  Widget toWidget() {
    return ListTile(
      title: Text(this.title),
      trailing: Text(this.issueData),
    );
  }
}

class BookItemData {
  BookItemData({required this.fileName, required this.size, this.downloadURL});
  final String fileName;
  final String size;
  final String? downloadURL;
}
