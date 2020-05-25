import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

///
/// A quick and dirty helper class to download a mapfile
///
class FileHelper {
  static final Map<String, FileHelperInfo> tasks = Map();

  static bool _initialized = false;

  static ReceivePort _port = ReceivePort();

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

  static Future<String> getTempDirectory(String subdir) async {
    assert(!subdir.startsWith("/"));
    String result = (await getTemporaryDirectory()).path + "/" + subdir;
    var savedDir = Directory(result);
    bool exists = await savedDir.exists();
    if (!exists) {
      print("Creating directory $result");
      savedDir.create(recursive: true);
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

  static void downloadFile(String source, String destination) async {
    if (!_initialized) {
      //WidgetsFlutterBinding.ensureInitialized();
      await FlutterDownloader.initialize();
      initState();
      _initialized = true;
    }
    String _localPath = await findLocalPath();

    String tempDestination = destination;
    if (source.endsWith(".gz") && !tempDestination.endsWith(".gz")) {
      tempDestination += ".gz";
    }

    File file = File(_localPath + "/" + destination);

    print("file will be downloaded from $source and stored at $_localPath/$tempDestination");
    final String taskId = await FlutterDownloader.enqueue(
      url: source,
      savedDir: _localPath,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: false, // click on notification to open downloaded file (for Android)
    );
    FileHelperInfo info = FileHelperInfo(source, destination, tempDestination);
    tasks[taskId] = info;
    print("taskId $taskId stored as $info $tasks");

    FlutterDownloader.registerCallback(downloadCallback);
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  static void downloadCallback2(String id, DownloadTaskStatus status, int progress) {
    print('Download task ($id) is in status ($status) and progress ($progress)');
    FileHelperInfo info = tasks[id];
    //print('info is $info');
    if (info == null) return;
    if (status == DownloadTaskStatus.complete) {
      // finished
      //FlutterDownloader.registerCallback(null);
      if (info.source.endsWith(".gz") && !info.destination.endsWith(".gz")) unzip(info.tempDestination, info.destination);
      tasks.remove(id);
    }
  }

  static void unzip(String zippedFilename, String filename) async {
    String _localPath = await findLocalPath();
    File zipfile = File(_localPath + "/" + zippedFilename);
    Uint8List content = await zipfile.readAsBytes();
    Uint8List unzipped = gzip.decoder.convert(content);
    File file = File(_localPath + "/" + filename);
    file.writeAsBytes(unzipped);
    zipfile.delete();
    print("file unzipped");
  }

  static void delete(String filename) async {
    String _localPath = await findLocalPath();

    File file = File(_localPath + "/" + filename);
    if (await file.exists()) file.delete();
  }

  static void initState() {
    //super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      //setState((){ });
      downloadCallback2(id, status, progress);
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    //super.dispose();
  }
}

class FileHelperInfo {
  final String source;
  final String destination;
  final String tempDestination;

  FileHelperInfo(this.source, this.destination, this.tempDestination);

  @override
  String toString() {
    return 'FileHelperInfo{source: $source, destination: $destination, tempDestination: $tempDestination}';
  }
}
