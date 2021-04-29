import 'package:bphc_digital_library/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class DisplayMessageScreen extends StatelessWidget {
  final String title;
  final String content;
  final String? time;
  final String? author;
  final String? imageUrl;

  const DisplayMessageScreen({
    Key? key,
    required this.title,
    required this.content,
    this.author,
    this.time,
    this.imageUrl,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0x44232323),
        elevation: 0.3,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            if (imageUrl != null)
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                margin: EdgeInsets.only(bottom: 15),
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    imageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 17,
                color: Color(0x88DEDEDE),
                // fontWeight: FontWeight.w300,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(author ?? "By unknown"),
                    Text(time ?? 'No date')
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 7),
              child: Text(
                title,
                style: TextStyle(fontSize: 21),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MarkdownBody(
                onTapLink: (text, href, title) {
                  try {
                    if (href != null) launch(href);
                  } catch (e) {}
                },
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                        textScaleFactor: 1.2,
                        p: TextStyle(color: Color(0xBCEDEDED))),
                data: content,
                selectable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
