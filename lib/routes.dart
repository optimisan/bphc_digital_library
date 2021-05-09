import 'package:flutter/material.dart';
import 'todo/screens/todo_editor_screen.dart';

class GenerateRoute {
  static Route? generateRoute(RouteSettings settings) {
    print("route generate");
    try {
      return _doGenerateRoute(settings);
    } catch (e, s) {
      debugPrint("failed to generate route for $settings: $e $s");
      return null;
    }
  }

  static Route? _doGenerateRoute(RouteSettings settings) {
    if (settings.name?.isNotEmpty != true) return null;

    final uri = Uri.parse(settings.name!);
    final path = uri.path;
    // final q = uri.queryParameters ?? <String, String>{};
    switch (path) {
      case '/todo_editor':
        {
          try {
            final todo = (settings.arguments as Map)['todo'];
            return _buildRoute(
                settings,
                (_) => TodoEditorScreen(
                      todoItem: todo,
                    ));
          } catch (e) {
            return _buildRoute(settings, (_) => TodoEditorScreen());
          }
        }
      default:
        return null;
    }
  }

  static Route _buildRoute(RouteSettings settings, WidgetBuilder builder) =>
      MaterialPageRoute<void>(
        settings: settings,
        builder: builder,
      );
}
