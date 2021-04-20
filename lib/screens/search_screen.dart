import 'dart:io';

import 'package:bphc_digital_library/services/error_logs_service.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:flutter/material.dart';
import 'package:bphc_digital_library/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({required this.onEnter});
  final Function onEnter;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(right: 14.0, left: 14.0, top: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: TextField(
                style: TextStyle(fontSize: 19.0),
                maxLines: 1,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) async {
                  FocusScope.of(context).unfocus();
                  if (value.trim() != '') {
                    onEnter();
                    try {
                      final result = await InternetAddress.lookup('google.com');
                      if (result.isNotEmpty &&
                          result[0].rawAddress.isNotEmpty) {
                        print('connected');
                        print("$value");
                        await Provider.of<SearchInputs>(context, listen: false)
                            .updateSubjectSearch(value);
                      }
                    } on SocketException catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Not connected to internet"),
                      ));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Enter something to search"),
                    ));
                  }
                },
                decoration: InputDecoration(
                  fillColor: Color(0x557A7A7A),
                  filled: true,
                  focusColor: Colors.blueGrey,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 18.0),
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(25.0),
                    ),
                  ),
                  hintText: "Type to search...",
                ),
              ),
            ),
            SizedBox(height: 25.0),

            // Padding(
            //   padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            //   child: Text(
            //     "Year of study",
            //     style: TextStyle(
            //       fontWeight: FontWeight.w400,
            //       color: Color(0xFFADADAD),
            //       fontSize: 18.0,
            //     ),
            //   ),
            // ),
            // YearChips(),
            RecentChips(onEnter: onEnter),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 15.0),
              child: Text(
                "QUICK SEARCH",
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFdb5e04),
                  fontSize: 24.0,
                ),
              ),
            ),
            SubjectChips(onEnter: onEnter),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: RichText(
                  textScaleFactor: 1.2,
                  text: TextSpan(
                      text:
                          "Enter your search term and tap the search/go icon in your keyboard to search. Alternatively, click on the quick search buttons above.",
                      children: [
                        TextSpan(
                            text:
                                '\nUse the course code for accurate results: '),
                        TextSpan(
                            text: "CS F111, CHEM F111",
                            style: TextStyle(color: Colors.tealAccent)),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YearChips extends StatefulWidget {
  @override
  _YearChipsState createState() => _YearChipsState();
}

class _YearChipsState extends State<YearChips> {
  int? _value = 0;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List<Widget>.generate(
        4,
        (int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(kYears[index]),
              labelStyle: TextStyle(fontSize: 15.0),
              selected: _value == index,
              onSelected: (bool selected) {
                setState(() {
                  _value = selected ? index : null;
                });
              },
            ),
          );
        },
      ).toList(),
    );
  }
}

class SubjectChips extends StatefulWidget {
  const SubjectChips({required this.onEnter});
  final Function onEnter;
  @override
  _SubjectChipsState createState() => _SubjectChipsState();
}

class _SubjectChipsState extends State<SubjectChips> {
  int? _value;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List<Widget>.generate(
        kFirstYearSubjects.length,
        (int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(kFirstYearSubjects[index]['name'] ?? 'Error'),
              labelStyle: TextStyle(fontSize: 15.0),
              selected: _value == index,
              onSelected: (bool selected) async {
                setState(() {
                  _value = selected ? index : null;
                });
                widget.onEnter();
                try {
                  final result = await InternetAddress.lookup('google.com');
                  if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                    print('connected');

                    await Provider.of<SearchInputs>(context, listen: false)
                        .updateSubjectSearch(
                            kFirstYearSubjects[index]['url'] ?? 'Error');
                  }
                } on SocketException catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Not connected to internet"),
                  ));
                }
              },
            ),
          );
        },
      ).toList(),
    );
  }
}

class RecentChips extends StatefulWidget {
  const RecentChips({required this.onEnter});
  final Function onEnter;
  @override
  _RecentChipsState createState() => _RecentChipsState();
}

class _RecentChipsState extends State<RecentChips> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox<String>('recents'),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ValueListenableBuilder(
              valueListenable: Hive.box<String>('recents').listenable(),
              builder: (BuildContext context, Box<String> boxContents, _) {
                if (boxContents.isEmpty) return SizedBox();
                try {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "RECENTS",
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: Colors.purpleAccent,
                              fontSize: 24.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          children: List<Widget>.generate(
                            boxContents.values.length,
                            (int index) {
                              String searchStr = boxContents.getAt(index) ?? '';
                              return InkWell(
                                // padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  padding: EdgeInsets.only(
                                      left: 15, top: 2, bottom: 2, right: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0x77676767),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          constraints:
                                              BoxConstraints(minWidth: 14),
                                          child: Text(searchStr)),
                                      SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          child: Icon(Icons.close, size: 20),
                                          onTap: () {
                                            final box =
                                                Hive.box<String>('recents');
                                            box.deleteAt(index);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  // setState(() {
                                  //   _value = selected ? index : null;
                                  // });
                                  widget.onEnter();
                                  try {
                                    final result = await InternetAddress.lookup(
                                        'example.com');
                                    if (result.isNotEmpty &&
                                        result[0].rawAddress.isNotEmpty) {
                                      print('connected');

                                      await Provider.of<SearchInputs>(context,
                                              listen: false)
                                          .updateSubjectSearch(searchStr);
                                    }
                                  } on SocketException catch (_) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text("Not connected to internet"),
                                    ));
                                  }
                                },
                              );
                            },
                          ).toList(),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Failed to open recent searches: $e"),
                  ));
                  logError(e.toString());
                  return SizedBox();
                }
              });
        } else {
          return SizedBox(height: 0);
        }
      },
    );
  }
}
