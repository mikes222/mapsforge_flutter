import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

///
/// When using the downloading feature make sure WidgetsFlutterBinding.ensureInitialized(); is called somewhere around your main() function
class FileMgr {
  static final _log = new Logger('FileMgr');

  static FileMgr? _instance;

  Subject<FileDownloadEvent> _fileDownloadInject =
      PublishSubject<FileDownloadEvent>();

  Stream<FileDownloadEvent> get fileDownloadOberve =>
      _fileDownloadInject.stream;

  Subject<FileDeletedEvent> _fileDeletedInject =
      PublishSubject<FileDeletedEvent>();

  Stream<FileDeletedEvent> get fileDeletedOberve => _fileDeletedInject.stream;

  final Map<String, _DownloadInfo> tasks = Map();

  final int _maxConcurrentDownloads = 1;

  StreamSubscription? downloadSubscription;

  FileMgr._() {}

  factory FileMgr() {
    if (_instance != null) return _instance!;

    _instance = FileMgr._();
    return _instance!;
  }

  void dispose() {
    //super.dispose();
  }

  /// Returns a directory which is not visible to the user or other programs
  Future<String> findLocalPath() async {
    String result = (await getApplicationSupportDirectory()).path;

    var savedDir = Directory(result);
    bool exists = await savedDir.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await savedDir.create(recursive: true);
    }

    return result;
  }

  /// Returns a path which can be accessed also by users and external programs. Use this path for example to send mails
  Future<String> findExternalPath() async {
    // todo find another directory for ios
    String result = (await getExternalStorageDirectory())!.path;
    var savedDir = Directory(result);
    bool exists = await savedDir.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await savedDir.create(recursive: true);
    }

    return result;
  }

  /// Returns a path for temporary files
  Future<String> findTempPath(String subdir) async {
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

  /// returns a list of files in the give path. The full path is returned, eg. /data/user/0/com.mschwartz.dfb/db/query.db. The parameter [dirpath] is the absolute name of the path
  Future<List<String>> getFiles(String dirpath) async {
    Directory dir = Directory(dirpath);
    List<String> result = await dir
        .list()
        .map((fileSystemEntry) => fileSystemEntry.path)
        .toList();
    return result;
  }

  Future<bool> existsRelative(String filename) async {
    assert(!filename.startsWith("/"));
    String _localPath = await findLocalPath();

    File file = File("$_localPath/$filename");
    if (await file.exists()) {
      return true;
    }
    return false;
  }

  Future<bool> existsAbsolute(String filename) async {
    File file = File(filename);
    if (await file.exists()) {
      return true;
    }
    return false;
  }

  /// Un-g-zip a file and store the result at [filename]
  Future<void> ungzipAbsolute(String zippedFilename, String filename) async {
    _log.info("Unzipping $zippedFilename to $filename");
    File zippedfile = File("$zippedFilename");
    Uint8List content = await zippedfile.readAsBytes();
    Uint8List unzipped = gzip.decoder.convert(content) as Uint8List;
    File file = File("$filename");
    // wait until the file has been written
    await file.writeAsBytes(unzipped);
    //_log.info("Unzipping $_localPath/$filename finished");
  }

  Future<void> unzipAbsolute(
      String sourceFilename, String destinationDirectory) async {
    List<int> content = await File(sourceFilename).readAsBytes();
    Archive archive = ZipDecoder().decodeBytes(content);
    for (ArchiveFile file in archive) {
      if (file.isFile) {
        _log.info(
            "Unzipping ${file.name} to $destinationDirectory/${file.name}");
        List<int> unzipped = file.content;
        File destinationFile = File("$destinationDirectory/${file.name}");
        // wait until the file has been written
        await destinationFile.writeAsBytes(unzipped);
      } else {
        _log.info(
            "Unzipping directory ${file.name} to $destinationDirectory/${file.name}");
        Directory directory = Directory("$destinationDirectory/${file.name}");
        await directory.create(recursive: true);
      }
      //break;
    }
  }

  Future<void> deleteAbsolute(String filename) async {
    File file = File(filename);
    if (await file.exists()) {
      await file.delete();
      _fileDeletedInject.add(FileDeletedEvent(filename));
      return;
    }
  }

  Future<void> deleteRelative(String filename) async {
    String _localPath = await findLocalPath();
    File file = File("$_localPath/$filename");
    if (await file.exists()) {
      await file.delete();
      _fileDeletedInject.add(FileDeletedEvent("$_localPath/$filename"));
      return;
    }
  }

  Future<void> saveFileAbsolute(String filename, List<int> content) async {
    File file = File(filename);
    await file.writeAsBytes(content);
  }

  Future<void> saveFileRelative(String filename, List<int> content) async {
    String _localPath = await findLocalPath();
    File file = File("$_localPath/$filename");
    await file.writeAsBytes(content);
  }

  /// Downloads content from internet. This method is meant for smaller files since the
  /// download takes place in memory only. If [ignoreCertificate] is true an invalid certificate for an
  /// ssl connection is ignored and the file is downloaded anyway.
  Future<void> downloadContent(String source,
      [bool ignoreCertificate = false]) async {
    unawaited(_downloadNowToMemory(source, ignoreCertificate));
  }

  /// Downloads content from internet and caches it locally. If the content is already downloaded
  /// the file is provided from the cache. This method is meant for smaller files since the
  /// download takes place in memory only. If [ignoreCertificate] is true an invalid certificate for an
  /// ssl connection is ignored and the file is downloaded anyway.
  Future<List<int>> downloadAndCacheContent(String source,
      [bool ignoreCertificate = false]) async {
    String _localPath = await findLocalPath();
    String filename = source;
    int crc32 = getCrc32(filename.codeUnits);
    filename = "$_localPath/${crc32.toRadixString(16)}";
    //print("checking file $filename");
    File file = File(filename);
    if (await file.exists()) return file.readAsBytes();

    HttpClient _httpClient = HttpClient();
    _httpClient.connectionTimeout = const Duration(seconds: 20);
    _httpClient.idleTimeout = const Duration(minutes: 1);
    if (ignoreCertificate)
      _httpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

    HttpClientRequest request = await _httpClient.getUrl(Uri.parse(source));
    HttpClientResponse response = await request.close();
    final Uint8ListBuilder builder = await response.fold(
      new Uint8ListBuilder(),
      (Uint8ListBuilder buffer, List<int> bytes) => buffer..add(bytes),
    );
    final Uint8List content = builder.data;

    await saveFileAbsolute(filename, content);
    return content;
  }

  Future<void> _downloadNowToMemory(String source,
      [bool ignoreCertificate = false]) async {
    _log.info("file will be downloaded from ${source} into memory");

    http.Request req = http.Request('GET', Uri.parse(source));
    http.StreamedResponse response = await req.send();
    int total = response.contentLength ?? 0;
    int count = 0;
    List<int> content = [];
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    _fileDownloadInject.add(FileDownloadEvent.progress("memory", count, total));
    downloadSubscription = response.stream.listen((List<int> value) {
      int time = DateTime.now().millisecondsSinceEpoch;
      count += value.length;
      content.addAll(value);
      if (lastTime + 2000 < time) {
        _log.info(
            "Received $count of $total bytes (${(total == 0) ? "unknown" : (count / total * 100).round()} %) for memory");
        _fileDownloadInject
            .add(FileDownloadEvent.progress("memory", count, total));
        lastTime = time;
      }
    })
      ..onError((error, stacktrace) async {
        await downloadSubscription?.cancel();
        downloadSubscription = null;
        _fileDownloadInject.add(FileDownloadEvent.error("memory"));
      })
      ..onDone(() async {
        try {
          _fileDownloadInject.add(FileDownloadEvent.finish("memory", content));
        } catch (error) {
          _log.warning(error);
          _fileDownloadInject.add(FileDownloadEvent.error("memory"));
        }
        await downloadSubscription?.cancel();
        downloadSubscription = null;
      });
  }

  /// Downloads a file to the filesystem. If the source ends with .zip or .gz and the destination
  /// does not end with the same suffix the file will be unzipped. Adds the file to a queue if there
  /// are too many files currently downloading.
  Future<bool> downloadFileRelative(String source, String destination) async {
    assert(destination != "");
    assert(source != "");
    _DownloadInfo? info =
        tasks.values.firstWhereOrNull((element) => element.source == source);
    if (info != null) {
      _log.warning(
          "File $source already in downloadqueue, ignoring the downloadrequest");
      return false;
    }
    String _localPath = await findLocalPath();

    destination = "$_localPath/$destination";
    String tempDestination = destination;
    if (source.endsWith(".gz") && !tempDestination.endsWith(".gz")) {
      tempDestination += ".gz";
    } else if (source.endsWith(".zip") && !tempDestination.endsWith(".zip")) {
      tempDestination += ".zip";
    }

    int active = tasks.values
        .where((element) => element.status == STATUS.DOWNLOADING)
        .length;
    if (active >= _maxConcurrentDownloads) {
      info = _DownloadInfo(source, destination, tempDestination, STATUS.QUEUED);
      tasks[source] = info;
      _log.info(
          "file will be downloaded later from $source and stored at ${destination.startsWith("/") ? "" : "$_localPath/"}$destination");
      return true;
    }

    info =
        _DownloadInfo(source, destination, tempDestination, STATUS.DOWNLOADING);
    tasks[source] = info;

    await _downloadNowAbsolute(_localPath, info);
    return true;
  }

  Future<void> _downloadNowAbsolute(
      String _localPath, _DownloadInfo info) async {
    _log.info(
        "file will be downloaded from ${info.source} and stored at ${info.destination}");
    assert(downloadSubscription == null);
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    http.StreamedResponse response =
        await http.Client().send(http.Request('GET', Uri.parse(info.source)));
    int total = response.contentLength ?? 0;
    int count = 0;
    File tempFile = File("${info.tempDestination}");
    //print("tempfile $tempFile");
    IOSink sink;
    try {
      sink = tempFile.openWrite();
    } catch (error) {
      tasks.remove(info.source);
      _fileDownloadInject.add(FileDownloadEvent.error(info.destination));
      unawaited(_downloadNext(_localPath));
      return;
    }
    _fileDownloadInject
        .add(FileDownloadEvent.progress(info.destination, count, total));
    downloadSubscription = response.stream.listen((List<int> value) {
      int time = DateTime.now().millisecondsSinceEpoch;
      count += value.length;
      sink.add(value);
      if (lastTime + 2000 < time) {
        _log.info(
            "Received $count of $total bytes (${(total == 0) ? "unknown" : (count / total * 100).round()} %) for ${info.tempDestination}");
        _fileDownloadInject
            .add(FileDownloadEvent.progress(info.destination, count, total));
        lastTime = time;
      }
    })
      ..onError((error, stacktrace) async {
        tasks.remove(info.source);
        await downloadSubscription?.cancel();
        downloadSubscription = null;
        _fileDownloadInject.add(FileDownloadEvent.error(info.destination));

        await sink.close();
        await tempFile.delete();

        unawaited(_downloadNext(_localPath));
      })
      ..onDone(() async {
        await sink.flush();
        await sink.close();
        //await saveFile("$_localPath/${info.tempDestination}", content);
        try {
          if (info.source.endsWith(".gz") && !info.destination.endsWith(".gz"))
            await ungzipAbsolute(info.tempDestination, info.destination);
          else if (info.source.endsWith(".zip") &&
              !info.destination.endsWith(".zip")) {
            // destination must be a path
            String destination = info.destination;
            if (destination.lastIndexOf("/") > 0)
              destination =
                  destination.substring(0, destination.lastIndexOf("/"));
            await unzipAbsolute(info.tempDestination, destination);
          }
          _fileDownloadInject
              .add(FileDownloadEvent.finish(info.destination, null));
        } catch (error) {
          _log.warning(error);
          _fileDownloadInject.add(FileDownloadEvent.error(info.destination));
        }
        tasks.remove(info.source);
        await downloadSubscription?.cancel();
        downloadSubscription = null;

        unawaited(_downloadNext(_localPath));
      });
  }

  Future<void> _downloadNext(String _localPath) async {
    _DownloadInfo? info2 = tasks.values
        .firstWhereOrNull((element) => element.status == STATUS.QUEUED);
    if (info2 != null) {
      info2.status = STATUS.DOWNLOADING;
      await _downloadNowAbsolute(_localPath, info2);
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

enum DOWNLOADSTATUS {
  PROGRESS,
  FINISH,
  ERROR,
}

/////////////////////////////////////////////////////////////////////////////

class FileDownloadEvent {
  final DOWNLOADSTATUS status;

  final String filename;

  final int count;

  final int total;

  final List<int>? content;

  /// marks the current progress of the download. The file may NOT be available
  /// at the given filename-path yet. If the total bytes are unknown 0 is returned.
  FileDownloadEvent.progress(this.filename, this.count, this.total)
      : status = DOWNLOADSTATUS.PROGRESS,
        content = null,
        assert(count >= 0),
        assert(total >= 0),
        assert(total == 0 || count <= total);

  /// since we may unzip the file the count or total is not set at the finish-event
  FileDownloadEvent.finish(this.filename, this.content)
      : status = DOWNLOADSTATUS.FINISH,
        count = 0,
        total = 0;

  FileDownloadEvent.error(this.filename)
      : status = DOWNLOADSTATUS.ERROR,
        content = null,
        count = 0,
        total = 0;
}

/////////////////////////////////////////////////////////////////////////////

class FileDeletedEvent {
  final String filename;

  FileDeletedEvent(this.filename);
}

/////////////////////////////////////////////////////////////////////////////

enum STATUS {
  DOWNLOADING,
  QUEUED,
}

/////////////////////////////////////////////////////////////////////////////

class _DownloadInfo {
  /// The url to download from
  final String source;

  /// The path/filename where this file should be stored at in the filesystem
  final String destination;

  /// The path/filename where this file is downloaded. Same as $destination if there is no need to unzip the file
  final String tempDestination;

  STATUS status;

  _DownloadInfo(
      this.source, this.destination, this.tempDestination, this.status);

  @override
  String toString() {
    return 'FileHelperInfo{source: $source, destination: $destination, tempDestination: $tempDestination}';
  }
}

/////////////////////////////////////////////////////////////////////////////

/// An indefinitely growing builder of a [Uint8List].
class Uint8ListBuilder {
  static const int _kInitialSize = 100000; // 100KB-ish

  int _usedLength = 0;
  Uint8List _buffer = new Uint8List(_kInitialSize);

  Uint8List get data => new Uint8List.view(_buffer.buffer, 0, _usedLength);

  void add(List<int> bytes) {
    _ensureCanAdd(bytes.length);
    _buffer.setAll(_usedLength, bytes);
    _usedLength += bytes.length;
  }

  void _ensureCanAdd(int byteCount) {
    final int totalSpaceNeeded = _usedLength + byteCount;

    int newLength = _buffer.length;
    while (totalSpaceNeeded > newLength) {
      newLength *= 2;
    }

    if (newLength != _buffer.length) {
      final Uint8List newBuffer = new Uint8List(newLength);
      newBuffer.setAll(0, _buffer);
      newBuffer.setRange(0, _usedLength, _buffer);
      _buffer = newBuffer;
    }
  }
}
