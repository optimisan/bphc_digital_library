import 'package:bphc_digital_library/screen_provider.dart';
import 'package:bphc_digital_library/todo/services/get_tasks_items.dart';
import 'package:bphc_digital_library/todo/services/todo_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// To access the Animated list
final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

/// This holds the items
List<TodoItem> _items = [];

/// This holds the item count
int _counter = 0;

int _screenIndex = 0;

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  @override
  Widget build(BuildContext context) {
    final screen = Provider.of<ScreenManager>(context).tasksScreenIndex;
    switch (screen) {
      case 0:
        return UpcomingTasksScreen();
      case 1:
      // return Center(child: Text("efsdf"));
      default:
        return UpcomingTasksScreen();
    }
  }
}

class TodoItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class NothingToShow extends StatelessWidget {
  const NothingToShow(this.showStr, {this.displayStr = "Nothing here yet"});
  final String showStr;
  final displayStr;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 150;
    var path;
    switch (showStr) {
      case 'todo':
        path = 'assets/images/To_do_image.png';
        break;
      case 'search':
        path = 'assets/images/Screen_image.png';
        break;
      case 'library':
        path = 'assets/images/Books_image.png';
        break;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            child: Image.asset(path, width: width),
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1), BlendMode.srcOver),
          ),
          SizedBox(height: 25),
          Text(displayStr),
          SizedBox(height: 25),
        ],
      ),
    );
  }
}
