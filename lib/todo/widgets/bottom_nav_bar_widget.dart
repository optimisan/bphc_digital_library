import 'package:bphc_digital_library/constants.dart';
import 'package:bphc_digital_library/screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class TasksBottomNavBar extends StatefulWidget {
  @override
  _TasksBottomNavBarState createState() => _TasksBottomNavBarState();
}

class _TasksBottomNavBarState extends State<TasksBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
        child: GNav(
          // mainAxisAlignment: MainAxisAlignment.start,
          rippleColor: Colors.grey[300]!,
          hoverColor: Colors.grey[100]!,
          gap: 8,
          activeColor: Colors.black,
          iconSize: 24,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          duration: Duration(milliseconds: 400),
          tabBackgroundColor: Colors.grey[100]!,
          color: kTealAccent,
          tabs: [
            GButton(icon: Icons.today, text: "Upcoming"),
            GButton(
              icon: Icons.check,
              text: 'All',
            ),
            GButton(
              icon: Icons.flight_takeoff_rounded,
              text: 'Missed',
            ),
            GButton(
              icon: Icons.flag_rounded,
              text: 'Completed',
            ),
          ],
          selectedIndex: context.watch<ScreenManager>().tasksScreenIndex,
          onTabChange: (index) {
            setState(() {
              context.read<ScreenManager>().setTasksScreen(index);
            });
          },
        ),
      ),
    );
  }
}
