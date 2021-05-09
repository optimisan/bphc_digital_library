import 'package:bphc_digital_library/screens/book_list_screen.dart';
import 'package:bphc_digital_library/services/search_inputs.dart';
import 'package:bphc_digital_library/services/search_results_service.dart';
import 'package:bphc_digital_library/todo/screens/todo_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({
    Key? key,
    required this.returnToLibrary,
  }) : super(key: key);
  final Function returnToLibrary;
  @override
  Widget build(BuildContext context) {
    List<BookData> books = Provider.of<SearchInputs>(context).books;
    String? searchStatus = Provider.of<SearchInputs>(context).searchStatus;
    final searchInputs = Provider.of<SearchInputs>(context);
    final bool showMore =
        searchInputs.currentPage < searchInputs.totalPages - 1;
    print("Search $searchStatus");
    bool listenToPort = context.read<SearchInputs>().alreadyListeningToPort;
    if (searchStatus != null && searchStatus == "done") {
      return ListView.builder(
        itemBuilder: (context, index) {
          if (index == books.length + 1) return SearchInfo();
          if (index == books.length + 2) return ShowMoreButton();
          if (index == 0) {
            return Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  searchInputs.subjectToDisplay
                          ?.replaceAll('+', ' ')
                          .replaceAll('&', '') ??
                      '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ));
          }
          return BookTile(
              books: books[index - 1],
              listenToPort: listenToPort,
              returnToLibrary: returnToLibrary);
        },
        itemCount: showMore ? (books.length + 3) : books.length + 2,
      );
    } else if (searchStatus == "loading") {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (searchStatus == "Nothing found") {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("No matching documents found"),
          SizedBox(height: 10),
          OpenInBrowserButton(),
        ],
      ));
    } else {
      // return Center(child: Text("Search results will show up here"));
      return NothingToShow('search',
          displayStr: "Search results will show up here");
    }
  }
}

class OpenInBrowserButton extends StatelessWidget {
  const OpenInBrowserButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final url =
            'http://125.22.54.221:8080/jspui/simple-search?query=${context.read<SearchInputs>().subject?.replaceAll(" ", "+")}';
        try {
          await launch(url);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Could not open url: $e"),
          ));
        }
      },
      icon: Icon(Icons.open_in_new_rounded),
      label: Text("Open in browser"),
      style: ElevatedButton.styleFrom(
        elevation: 1.0,
        primary: Color(0xFF343434),
      ),
    );
  }
}

class BookTile extends StatefulWidget {
  const BookTile({
    Key? key,
    required this.books,
    required this.listenToPort,
    required this.returnToLibrary,
  }) : super(key: key);

  final BookData books;
  final bool listenToPort;
  final Function returnToLibrary;

  @override
  _BookTileState createState() => _BookTileState();
}

class _BookTileState extends State<BookTile> {
  bool thisWasVisited = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      child: InkWell(
        onTap: () async {
          final showLibrary =
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => BookListScreen(
                        listenToPort: widget.listenToPort,
                        updateListen: () {
                          Provider.of<SearchInputs>(context)
                              .alreadyListeningToPort = true;
                        },
                        bookURL: widget.books.url,
                        bookName: widget.books.title,
                        toLibrary: (String book) {
                          Provider.of<SearchInputs>(context, listen: false)
                              .showInLibraryTitle = book;
                          widget.returnToLibrary();
                        },
                        folderName:
                            '${widget.books.title}_${widget.books.issueData}',
                      )));
          setState(() {
            this.thisWasVisited = true;
          });
          if (showLibrary != null) {
            Provider.of<SearchInputs>(context, listen: false)
                .showInLibraryTitle = showLibrary;
            widget.returnToLibrary();
          }
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
                    Icon(Icons.book, size: 26, color: Colors.tealAccent),
                    SizedBox(width: 8),
                    Expanded(child: Text(widget.books.title)),
                    if (thisWasVisited)
                      Icon(
                        Icons.history_rounded,
                        color: Colors.lightBlueAccent,
                      ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconRow(
                      title: widget.books.issueData,
                      icon: Icons.date_range_rounded,
                    ),
                    IconRow(title: widget.books.author, icon: Icons.person),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return ListTile(
      leading: SizedBox(width: 60, child: Text(widget.books.issueData)),
      title: Text(widget.books.title),
      selectedTileColor: Colors.pink,
      onTap: () async {
        // print('sdsd ${books[index].url} ' ?? "url is null");
        final showLibrary = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BookListScreen(
                  listenToPort: widget.listenToPort,
                  updateListen: () {
                    Provider.of<SearchInputs>(context).alreadyListeningToPort =
                        true;
                  },
                  bookURL: widget.books.url,
                  bookName: widget.books.title,
                  toLibrary: (String book) {
                    Provider.of<SearchInputs>(context, listen: false)
                        .showInLibraryTitle = book;
                    widget.returnToLibrary();
                  },
                  folderName: '${widget.books.title}_${widget.books.issueData}',
                )));
        if (showLibrary != null) {
          Provider.of<SearchInputs>(context, listen: false).showInLibraryTitle =
              showLibrary;
          widget.returnToLibrary();
        }
      },
    );
  }
}

class IconRow extends StatelessWidget {
  const IconRow({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: icon == Icons.person
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Icon(icon, size: 22),
        SizedBox(width: 8),
        Container(
          constraints: BoxConstraints(minWidth: 100, maxWidth: 200),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
            ),
            overflow: TextOverflow.fade,
          ),
        ),
      ],
    );
  }
}

class SearchInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        // mainAxisAlignment: MainAxisAlignment.center,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (context.read<SearchInputs>().currentPage + 1 <
              context.read<SearchInputs>().totalPages)
            SizedBox(
              width: 130,
              child: Text(
                context.read<SearchInputs>().currentPage + 1 <
                        context.read<SearchInputs>().totalPages
                    ? "Showing ${context.read<SearchInputs>().currentPage * 10 + 10} of${context.read<SearchInputs>().searchInfo}books"
                    : "",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          SizedBox(width: 20),
          OpenInBrowserButton(),
        ],
      ),
    );
  }
}

class ShowMoreButton extends StatefulWidget {
  @override
  _ShowMoreButtonState createState() => _ShowMoreButtonState();
}

class _ShowMoreButtonState extends State<ShowMoreButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, top: 10),
      child: isLoading
          ? Container(
              child: Align(
                child: SizedBox(
                    width: 40, height: 40, child: CircularProgressIndicator()),
              ),
            )
          : Container(
              child: Align(
                child: SizedBox(
                  width: 250,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.tealAccent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(25.0),
                        // side: BorderSide(color: Color(0xFFff195b)),
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        isLoading = !isLoading;
                      });
                      await Provider.of<SearchInputs>(context, listen: false)
                          .parseBody(nextPage: true);
                    },
                    label: Text("Load more books"),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
