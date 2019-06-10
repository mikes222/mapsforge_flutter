import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
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
      print("Creating directory $result");
      savedDir.create(recursive: true);
    }

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

  static void downloadFile(String source, String destination) async {
    String _localPath = await findLocalPath();

    String tempDestination = destination;
    if (source.endsWith(".gz") && !tempDestination.endsWith(".gz")) {
      tempDestination += ".gz";
    }

    File file = File(_localPath + "/" + destination);

    print("file will be downloaded from $source and stored at $_localPath/$tempDestination");
    final taskId = await FlutterDownloader.enqueue(
      url: source,
      savedDir: _localPath,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: false, // click on notification to open downloaded file (for Android)
    );
    print("taskId $taskId");

    FlutterDownloader.registerCallback((id, status, progress) {
      // Download task (5bb2cc9b-986c-4feb-bd07-880d88269d68) is in status (DownloadTaskStatus(3)) and process (100)
      if (id != taskId) return;
      if (status == DownloadTaskStatus.complete) {
        // finished
        FlutterDownloader.registerCallback(null);
        if (source.endsWith(".gz") && !destination.endsWith(".gz")) unzip(tempDestination, destination);
      }
      print('Download task ($id) is in status ($status) and process ($progress)');
    });
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

  static void delete(String filename) async {
    String _localPath = await findLocalPath();

    File file = File(_localPath + "/" + filename);
    if (await file.exists()) file.delete();
  }
}
