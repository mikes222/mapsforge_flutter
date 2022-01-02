import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:mapsforge_example/pathhandler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

///
/// When using the downloading feature make sure WidgetsFlutterBinding.ensureInitialized();
/// is called somewhere around your main() function
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

  final Map<String, _DownloadInfo> _downloadTasks = Map();

  final int _maxConcurrentDownloads = 1;

  _DevHttpOverrides _httpOverrides = _DevHttpOverrides();

  FileMgr._() {
    HttpOverrides.global = _httpOverrides;
  }

  factory FileMgr() {
    if (_instance != null) return _instance!;

    _instance = FileMgr._();
    return _instance!;
  }

  void dispose() {
    //super.dispose();
  }

  Subject<FileDeletedEvent> get fileDeletedInject => _fileDeletedInject;

  /// Returns a directory which is not visible to the user or other programs. The subdirectory will be
  /// created if necessary.
  Future<PathHandler> getLocalPathHandler(String subdir) async {
    assert(!subdir.startsWith("/"));
    assert(!subdir.endsWith("/"));
    String result = (await getApplicationSupportDirectory()).path;
    if (subdir.isNotEmpty) result = "$result/$subdir";

    var directory = Directory(result);
    bool exists = await directory.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await directory.create(recursive: true);
    }
    return PathHandler(directory);
  }

  /// Returns a path which can be accessed also by users and external programs.
  /// Use this path for example to send mails.
  // todo find another directory for ios
  Future<PathHandler> getExternalPathHandler(String subdir) async {
    assert(!subdir.startsWith("/"));
    assert(!subdir.endsWith("/"));
    String result = (await getExternalStorageDirectory())!.path;
    if (subdir.isNotEmpty) result = "$result/$subdir";

    var directory = Directory(result);
    bool exists = await directory.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await directory.create(recursive: true);
    }
    return PathHandler(directory);
  }

  /// Returns a path for temporary files. The O/S can delete these file when needed.
  /// The directory will be created if necessary.
  Future<PathHandler> getTempPathHandler(String subdir) async {
    assert(!subdir.startsWith("/"));
    assert(!subdir.endsWith("/"));
    String result = (await getTemporaryDirectory()).path;
    if (subdir.isNotEmpty) result = "$result/$subdir";

    var directory = Directory(result);
    bool exists = await directory.exists();
    if (!exists) {
      _log.info("Creating directory $result");
      await directory.create(recursive: true);
    }
    return PathHandler(directory);
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
    _log.info("Un-G-zipping $zippedFilename to $filename");
    File zippedfile = File("$zippedFilename");
    Uint8List content = await zippedfile.readAsBytes();
    Uint8List unzipped = gzip.decoder.convert(content) as Uint8List;
    File file = File("$filename");
    // wait until the file has been written
    await file.writeAsBytes(unzipped);
    //_log.info("Unzipping $_localPath/$filename finished");
  }

  /// unzipping a file into the specified [destinationDirectory]
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

  Future<void> saveFileAbsolute(String filename, List<int> content) async {
    File file = File(filename);
    await file.writeAsBytes(content);
  }

  Future<List<int>> downloadNow2(String source,
      [bool ignoreCertificate = false]) {
    String scheme = "https";
    String host = "";
    int port = 443;
    String path = "";
    Uri uri = Uri.parse(source);
    if (uri.scheme.isNotEmpty) scheme = uri.scheme;
    if (uri.host.isNotEmpty) host = uri.host;
    port = uri.port;
    path = uri.path;
    return downloadNow(scheme, host, port, path, ignoreCertificate);
  }

  /// Downloads content from internet. This method is meant for smaller files since the
  /// download takes place in memory only. If [ignoreCertificate] is true an invalid certificate for an
  /// ssl connection is ignored and the file is downloaded anyway.
  Future<List<int>> downloadNow(
      String scheme, String host, int port, String path,
      [bool ignoreCertificate = false]) async {
    try {
      List<int> content = await _downloadNowToMemory(
          scheme, host, port, path, ignoreCertificate);
      return content;
    } catch (error, stacktrace) {
      _log.warning(
          "Error while downloading file from $scheme://$host:$port/$path: $error");
      _fileDownloadInject.add(
          FileDownloadEvent.error("$scheme://$host:$port/$path", "memory"));
      throw error;
    }
  }

  /// Downloads content from internet and caches it locally. If the content is already downloaded
  /// the file is provided from the cache. This method is meant for smaller files since the
  /// download takes place in memory only. If [ignoreCertificate] is true an invalid certificate for an
  /// ssl connection is ignored and the file is downloaded anyway.
  Future<List<int>> downloadAndCacheNow(
      String scheme, String host, int port, String path,
      [bool ignoreCertificate = false]) async {
    PathHandler pathHandler = await getTempPathHandler("");
    String filename = "$scheme://$host:$port/$path";
    filename = pathHandler
        .getPath("${getCrc32(filename.codeUnits).toRadixString(16)}");
    File file = File(filename);
    if (await file.exists()) return file.readAsBytes();
    try {
      List<int> content = await _downloadNowToMemory(
          scheme, host, port, path, ignoreCertificate);
      await saveFileAbsolute(filename, content);
      return content;
    } catch (error, stacktrace) {
      _log.warning(
          "Error while downloading file from $scheme://$host:$port/$path: $error");
      _fileDownloadInject.add(
          FileDownloadEvent.error("$scheme://$host:$port/$path", "memory"));
      throw error;
    }
  }

  /// In case of error the calling method must send a _fileDownloadInject error
  Future<List<int>> _downloadNowToMemory(
      String scheme, String host, int port, String path,
      [bool ignoreCertificate = false]) async {
    if (path.startsWith("/")) path = path.substring(1);
    _log.info(
        "file will be downloaded from $scheme://$host:$port/$path into memory");

    if (ignoreCertificate) {
      _httpOverrides.addException(host, port);
    }
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    http.Request req =
        http.Request('GET', Uri.parse("$scheme://$host:$port/$path"));
    http.StreamedResponse response = await req.send();
    int total = response.contentLength ?? 0;
    int count = 0;
    List<int> content = [];
    _fileDownloadInject.add(FileDownloadEvent.progress(
        "$scheme://$host:$port/$path", "memory", count, total));
    await response.stream.forEach((List<int> value) {
      int time = DateTime.now().millisecondsSinceEpoch;
      count += value.length;
      content.addAll(value);
      if (lastTime + 2000 < time) {
        _log.info(
            "Received $count of $total bytes (${(total == 0) ? "unknown" : (count / total * 100).round()} %) for memory");
        _fileDownloadInject.add(FileDownloadEvent.progress(
            "$scheme://$host:$port/$path", "memory", count, total));
        lastTime = time;
      }
    });
    _fileDownloadInject.add(FileDownloadEvent.finish(
        "$scheme://$host:$port/$path", "memory", content));
    return content;
  }

  Future<void> downloadNowToFile(
      String scheme, String host, int port, String path, String destination,
      [bool ignoreCertificate = false]) async {
    try {
      await _downloadNowToFile(
          scheme, host, port, path, destination, ignoreCertificate);
    } catch (error, stacktrace) {
      _fileDownloadInject.add(
          FileDownloadEvent.error("$scheme://$host:$port/$path", destination));
      throw error;
    }
  }

  Future<void> downloadNowToFile2(String source, String destination,
      [bool ignoreCertificate = false]) {
    String scheme = "https";
    String host = "";
    int port = 443;
    String path = "";
    Uri uri = Uri.parse(source);
    if (uri.scheme.isNotEmpty) scheme = uri.scheme;
    if (uri.host.isNotEmpty) host = uri.host;
    port = uri.port;
    path = uri.path;
    return downloadNowToFile(
        scheme, host, port, path, destination, ignoreCertificate);
  }

  /// In case of error the calling method must
  //       _fileDownloadInject.add(FileDownloadEvent.error(destination));
  ///       _downloadTasks.remove(info.source);
  //       unawaited(_downloadNext());
  Future<void> _downloadNowToFile(
      String scheme, String host, int port, String path, String destination,
      [bool ignoreCertificate = false]) async {
    if (path.startsWith("/")) path = path.substring(1);
    String source = "$scheme://$host:$port/$path";
    _log.info(
        "file will be downloaded from $scheme://$host:$port/$path to $destination");

    if (ignoreCertificate) {
      _httpOverrides.addException(host, port);
    }
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    http.Request req =
        http.Request('GET', Uri.parse("$scheme://$host:$port/$path"));
    http.StreamedResponse response = await req.send();

    int total = response.contentLength ?? 0;
    int count = 0;
    String tempDestination = destination;
    if (source.endsWith(".gz") && !destination.endsWith(".gz")) {
      PathHandler pathHandler = await FileMgr().getTempPathHandler("");
      tempDestination = pathHandler
          .getPath("${getCrc32(source.codeUnits).toRadixString(16)}.gz");
    } else if (source.endsWith(".zip") && !destination.endsWith(".zip")) {
      PathHandler pathHandler = await FileMgr().getTempPathHandler("");
      tempDestination = pathHandler
          .getPath("${getCrc32(source.codeUnits).toRadixString(16)}.zip");
    }

    File tempFile = File(tempDestination);
    //print("tempfile $tempFile");
    IOSink sink = tempFile.openWrite();
    _fileDownloadInject
        .add(FileDownloadEvent.progress(source, destination, count, total));
    try {
      await response.stream.forEach((List<int> value) {
        int time = DateTime.now().millisecondsSinceEpoch;
        count += value.length;
        sink.add(value);
        if (lastTime + 2000 < time) {
          _log.info(
              "Received $count of $total bytes (${(total == 0) ? "unknown" : (count / total * 100).round()} %) for $destination");
          _fileDownloadInject.add(
              FileDownloadEvent.progress(source, destination, count, total));
          lastTime = time;
        }
      });
      await sink.flush();
      await sink.close();
    } catch (error, stacktrace) {
      await sink.close();
      await tempFile.delete();
      throw error;
    }
    if (source.endsWith(".gz") && !destination.endsWith(".gz")) {
      await ungzipAbsolute(tempDestination, destination);
      await tempFile.delete();
    } else if (source.endsWith(".zip") && !destination.endsWith(".zip")) {
      // destination must be a path
      if (destination.lastIndexOf("/") > 0)
        destination = destination.substring(0, destination.lastIndexOf("/"));
      await unzipAbsolute(tempDestination, destination);
      await tempFile.delete();
    }
    _fileDownloadInject.add(FileDownloadEvent.finish(source, destination));
  }

  Future<bool> downloadToFile2(String source, String destination) {
    String scheme = "https";
    String host = "";
    int port = 443;
    String path = "";
    Uri uri = Uri.parse(source);
    if (uri.scheme.isNotEmpty) scheme = uri.scheme;
    if (uri.host.isNotEmpty) host = uri.host;
    port = uri.port;
    path = uri.path;
    return downloadToFile(scheme, host, port, path, destination);
  }

  /// Downloads a file to the filesystem. If the source ends with .zip or .gz and the destination
  /// does not end with the same suffix the file will be unzipped. Adds the file to a queue if there
  /// are too many files currently downloading.
  Future<bool> downloadToFile(String scheme, String host, int port, String path,
      String destination) async {
    assert(destination != "");
    if (path.startsWith("/")) path = path.substring(1);
    String source = "$scheme://$host:$port/$path";
    _DownloadInfo? info = _downloadTasks.values
        .firstWhereOrNull((element) => element.source == source);
    if (info != null) {
      _log.warning(
          "File $source already in downloadqueue, ignoring the downloadrequest");
      return false;
    }

    int active = _downloadTasks.values
        .where((element) => element.status == _DOWNLOADINFOSTATUS.DOWNLOADING)
        .length;
    if (active >= _maxConcurrentDownloads) {
      info = _DownloadInfo(
          scheme: scheme,
          host: host,
          port: port,
          path: path,
          destination: destination,
          status: _DOWNLOADINFOSTATUS.QUEUED);
      _downloadTasks[source] = info;
      _log.info(
          "file will be downloaded later from $source and stored at $destination");
      return true;
    }

    try {
      info = _DownloadInfo(
          scheme: scheme,
          host: host,
          port: port,
          path: path,
          destination: destination,
          status: _DOWNLOADINFOSTATUS.DOWNLOADING);
      _downloadTasks[source] = info;

      await _downloadNowToFile(scheme, host, port, path, destination);
      _downloadTasks.remove(info.source);
      unawaited(_downloadNext());
    } catch (error, stacktrace) {
      _fileDownloadInject.add(FileDownloadEvent.error(source, destination));
      _downloadTasks.remove(source);
      unawaited(_downloadNext());
    }
    return true;
  }

  Future<void> _downloadNext() async {
    _DownloadInfo? info = _downloadTasks.values.firstWhereOrNull(
        (element) => element.status == _DOWNLOADINFOSTATUS.QUEUED);
    if (info != null) {
      info.status = _DOWNLOADINFOSTATUS.DOWNLOADING;
      try {
        await _downloadNowToFile(
            info.scheme, info.host, info.port, info.path, info.destination);
      } catch (error, stacktrace) {
        _fileDownloadInject
            .add(FileDownloadEvent.error(info.source, info.destination));
      }
      _downloadTasks.remove(info.source);
      unawaited(_downloadNext());
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

  final String source;

  final String filename;

  final int count;

  final int total;

  final List<int>? content;

  /// marks the current progress of the download. The file may NOT be available
  /// at the given filename-path yet. If the total bytes are unknown 0 is returned.
  FileDownloadEvent.progress(this.source, this.filename, this.count, this.total)
      : status = DOWNLOADSTATUS.PROGRESS,
        content = null,
        assert(count >= 0),
        assert(total >= 0),
        assert(total == 0 || count <= total);

  /// since we may unzip the file the count or total is not set at the finish-event
  FileDownloadEvent.finish(this.source, this.filename, [this.content = null])
      : status = DOWNLOADSTATUS.FINISH,
        count = 0,
        total = 0;

  FileDownloadEvent.error(this.source, this.filename)
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

enum _DOWNLOADINFOSTATUS {
  DOWNLOADING,
  QUEUED,
}

/////////////////////////////////////////////////////////////////////////////

class _DownloadInfo {
  final String scheme;
  final String host;
  final int port;
  final String path;

  /// The url to download from
  late final String source;

  /// The path/filename where this file should be stored at in the filesystem
  final String destination;

  _DOWNLOADINFOSTATUS status;

  _DownloadInfo(
      {required this.scheme,
      required this.host,
      required this.port,
      required this.path,
      required this.destination,
      required this.status}) {
    source = "$scheme://$host:$port/$path";
  }

  @override
  String toString() {
    return 'FileHelperInfo{source: $source, destination: $destination}';
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

/////////////////////////////////////////////////////////////////////////////

class _DevHttpOverrides extends HttpOverrides {
  final Set<_HostPort> _exceptions = {};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = _certCallback
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(minutes: 1);
  }

  bool _certCallback(X509Certificate cert, String host, int port) {
    if (_exceptions.contains(_HostPort(host, port))) return true;
    return false;
  }

  void addException(String host, int port) {
    _exceptions.add(_HostPort(host, port));
  }

  void removeException(String host, int port) {
    _exceptions
        .removeWhere((element) => element.host == host && element.port == port);
  }
}

/////////////////////////////////////////////////////////////////////////////

class _HostPort {
  final String host;

  final int port;

  const _HostPort(this.host, this.port);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HostPort &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => host.hashCode ^ port.hashCode;
}
