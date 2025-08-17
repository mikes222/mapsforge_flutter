import 'dart:io';

import 'package:mapsforge_example/filemgr.dart';

class PathHandler {
  late final Directory directory;

  /// The directory must exist
  PathHandler(this.directory) {}

  /// returns a list of files in the give path. The full path is returned, eg. /data/user/0/com.mschwartz.dfb/db/query.db.
  Future<List<String>> getFiles() async {
    List<String> result = await directory
        .list()
        .map((fileSystemEntry) => fileSystemEntry.path)
        .toList();
    return result;
  }

  String getPath([String? filename]) {
    if (filename == null) return directory.path;
    return "${directory.path}/$filename";
  }

  /// Returns true if the given filename exists in the current directory
  Future<bool> exists(String filename) async {
    assert(!filename.startsWith("/"));
    File file = File("${directory.path}/$filename");
    if (await file.exists()) {
      return true;
    }
    return false;
  }

  /// Removes the file with the given filename in the current directory
  Future<void> delete(String filename) async {
    assert(!filename.startsWith("/"));
    File file = File("${directory.path}/$filename");
    if (await file.exists()) {
      await file.delete();
      FileMgr()
          .fileDeletedInject
          .add(FileDeletedEvent("${directory.path}/$filename"));
      return;
    }
  }

  Future<void> saveFile(String filename, List<int> content) async {
    File file = File("${directory.path}/$filename");
    await file.writeAsBytes(content);
  }

  Future<void> saveFileAsString(String filename, String content) async {
    File file = File("${directory.path}/$filename");
    await file.writeAsString(content, flush: true);
  }

  Future<List<int>> readFile(String filename) async {
    File file = File("${directory.path}/$filename");
    return await file.readAsBytes();
  }
}
