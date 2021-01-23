import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static final _log = new Logger('FileHelper');

  static Future<String> findLocalPath() async {
//    final directory = widget.platform == TargetPlatform.android
//        ? await getExternalStorageDirectory()
//        : await getApplicationDocumentsDirectory();
//    return directory.path;
    String result = (await getApplicationDocumentsDirectory()).path;
    //result += '/dailyflightbuddy/maps';

    var savedDir = Directory(result);
    bool exists = await savedDir.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      savedDir.create(recursive: true);
    }

    return result;
  }

  static Future<String> getTempDirectory(String subdir) async {
    assert(!subdir.startsWith("/"));
    String result = (await getTemporaryDirectory()).path + "/" + subdir;
    var savedDir = Directory(result);
    bool exists = await savedDir.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await savedDir.create(recursive: true);
    }
    return result;
  }

  static Future<List<String>> getFiles(String dirpath) async {
    assert(dirpath != null);
    Directory dir = Directory(dirpath);
    List<String> result = await dir.list().map((fileSystemEntry) => fileSystemEntry.path).toList();
    return result;
  }

  static Future<bool> exists(String filename) async {
    String _localPath = await findLocalPath();

    File file = File(_localPath + "/" + filename);
    if (await file.exists()) {
      return true;
    }
    return false;
  }

  static void unzip(String zippedFilename, String filename) async {
    String _localPath = await findLocalPath();
    File zipfile = File(_localPath + "/" + zippedFilename);
    Uint8List content = await zipfile.readAsBytes();
    Uint8List unzipped = gzip.decoder.convert(content);
    File file = File(_localPath + "/" + filename);
    file.writeAsBytes(unzipped);
    zipfile.delete();
  }

  static Future<bool> delete(String filename) async {
    File file;
    if (filename.startsWith("/"))
      file = File(filename);
    else {
      String _localPath = await findLocalPath();
      file = File(_localPath + "/" + filename);
    }
    if (await file.exists()) {
      file.delete();
      return true;
    }
    return false;
  }
}
