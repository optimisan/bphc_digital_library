import 'package:bphc_digital_library/announcements/screens/channel_screen.dart';
import 'package:bphc_digital_library/todo/screens/todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('all-collections');

    return StreamBuilder<QuerySnapshot>(
      stream: users.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data?.docs.length == 0) {
          // return Center(child: const Text("No messages here."));
          return NothingToShow(
            'library',
            displayStr: 'No internet',
          );
        }

        return ListView(
          children: snapshot.data?.docs.map((DocumentSnapshot document) {
                return ChannelTile(
                    title: document.data()?['name'] ?? '', info: document.data()?['info']);
                return ListTile(
                  title: Text(document.data()?['name'] ?? ''),
                  subtitle: Text(document.data()?['info'] ?? ''),
                );
              }).toList() ??
              [],
        );
      },
    );
  }
}

class ChannelTile extends StatelessWidget {
  const ChannelTile({required this.title, required this.info});
  final String title;
  final String? info;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      child: InkWell(
        onTap: () async {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChannelScreen(title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0x22adadad),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 18, color: Color(0xFAEDEDED)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.article,
                      size: 28,
                      color: Colors.tealAccent,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      title,
                      style: const TextStyle(fontSize: 19),
                    )),
                  ],
                ),
                SizedBox(height: 12),
                if (info != null)
                  Row(
                    children: [
                      Text(
                        info ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
