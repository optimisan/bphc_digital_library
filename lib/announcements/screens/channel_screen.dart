import 'package:bphc_digital_library/announcements/screens/display_message_screen.dart';
import 'package:bphc_digital_library/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChannelScreen extends StatelessWidget {
  const ChannelScreen(this.channelName);
  final String channelName;
  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection(channelName);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(channelName),
        backgroundColor: Color(0x335555),
        elevation: 0.2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: users.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data?.docs.length == 0) {
            return Center(child: const Text("No messages in this channel."));
          }
          final List<Widget>? list = snapshot.data?.docs.map((DocumentSnapshot document) {
            return MessageTile(
              title: document.data()?['title'] ?? 'Message',
              content: document.data()?['content']?.replaceAll("\\n", "\n") ?? '',
              time: document.data()?['time'],
              imageURL: document.data()?['imageURL'],
              author: document.data()?['author'],
            );
            return ListTile(
              title: Text(document.data()?['title'] ?? ''),
              subtitle: Text(document.data()?['content']?.replaceAll("#", "\n") ?? ''),
            );
          }).toList();
          list?.insert(
            0,
            Container(
              height: 10,
            ),
          );

          return ListView(
            children: list ?? [],
          );
        },
      ),
    );
  }
}

class MessageTile extends StatefulWidget {
  const MessageTile(
      {required this.title, required this.content, this.imageURL, this.time, this.author});
  final String title;
  final String content;
  final String? time;
  final String? imageURL;
  final String? author;

  @override
  _MessageTileState createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  bool expand = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DisplayMessageScreen(
                title: widget.title,
                content: widget.content,
                time: widget.time,
                imageUrl: widget.imageURL,
                author: widget.author,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Color(0x33ABABAB),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20)),
              if (widget.time != null)
                Text(
                  widget.time ?? 'No Date',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0x88DEDEDE),
                    // fontWeight: FontWeight.w300,
                  ),
                ),
            ],
          ),
          // child: ExpansionTile(
          //   leading: widget.imageURL != null ? Icon(Icons.attach_file) : null,
          //   title: Text(
          //     widget.title,
          //     style: const TextStyle(fontSize: 19),
          //   ),
          //   subtitle: Padding(
          //     padding: const EdgeInsets.only(top: 5.0),
          //     child: Text(widget.time ?? '',
          //         style: const TextStyle(color: Color(0xDDFEFEFE))),
          //   ),
          //   children: [
          //     if (widget.imageURL != null)
          //       Container(
          //         constraints: BoxConstraints(maxHeight: 200),
          //         child: Image.network(widget.imageURL!),
          //       ),
          //     Align(
          //       alignment: Alignment.topLeft,
          //       child: Padding(
          //         padding: const EdgeInsets.only(bottom: 10.0),
          //         child: AnimatedContainer(
          //           duration: Duration(milliseconds: 240),
          //           constraints: BoxConstraints(maxHeight: expand ? 200 : 70),
          //           // child: Text(content),
          //           child: Markdown(
          //             data: widget.content,
          //             selectable: true,
          //           ),
          //         ),
          //       ),
          //     ),
          //     Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       children: [
          //         Text(
          //           "Content is scrollable",
          //           style:
          //               const TextStyle(fontWeight: FontWeight.w300, fontSize: 12),
          //         ),
          //         OutlinedButton(
          //             onPressed: () {
          //               setState(() {
          //                 expand = !expand;
          //               });
          //             },
          //             child: Text(expand ? "Collapse" : "Expand")),
          //       ],
          //     )
          //   ],
          // ),
        ),
      ),
    );
  }
}
