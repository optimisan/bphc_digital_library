import 'dart:io';

/// Data about the book. This is displayed in the library screen as an expansion tile.
///
/// Contains a list of [Item]s which are the shown in the expanded tile.
class Book {
  const Book(
      {required this.title, required this.path, required this.issueDate, required this.items});
  final String title;
  final String path;
  final String? issueDate;
  final List<Item> items;
}

/// Holds data about an item in a [Book]
///
/// Use getter [fileSize] for the file size
class Item {
  const Item({required this.title, required this.path, required this.size});
  final String title;
  final String path;
  final int size;
  String get fileSize {
    final sized = size / 1024;
    if (sized > 1024)
      return '${(sized / 1024).toStringAsFixed(2)} MB';
    else
      return '${sized.toStringAsFixed(2)} kB';
  }
}

extension BuildingItems on FileSystemEntity {
  /// Returns an [Item] from this [FileSystemEntity]
  Item get toItem {
    final name = this.path.replaceAll(RegExp(r'\/.+\/'), '');
    final size = this.statSync().size;
    return Item(title: name, path: this.path, size: size);
  }
}

// Item toItem(FileSystemEntity e) {
//   final name = e.path.replaceAll(RegExp(r'\/.+\/'), '');
//   final size = e.statSync().size;
//   return Item(title: name, path: e.path, size: size);
// }
