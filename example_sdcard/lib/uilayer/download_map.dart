import 'package:example_sdcard/uilayer/themap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapsforge_flutter/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDownloadUrl =
    'http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/monaco.map';

/// Allows user to download a Map and store it on a sdcard.
///
/// Once a Map has been downloaded and saved, its permission and uri will be remembered for future use.
///
/// Before a map can be saved, the user is asked to grant permission to save the file.
class DownloadMap extends StatefulWidget {
  const DownloadMap({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadMapState();
}

class _DownloadMapState extends State<DownloadMap> {
  // The uri of the stored Map
  String? _mapUriString;
  bool _hasMap = false;
  String _errorMessage = '';

  late SharedPreferences _prefs;
  late MapsforgeStorage _storageHandler;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloaded Map')),
      body: FutureBuilder<void>(
        future: _init(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_hasMap) {
              return TheMap(uriString: _mapUriString!);
            } else {
              return Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      )));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        }),
      ),
    );
  }

  /// Initialize map when preference 'downloadedMapUriString' has been set, or download a Map.
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _mapUriString = _prefs.getString('downloadedMapUriString');

    _storageHandler = MapsforgeStorage(mapUriString: _mapUriString);

    if (_mapUriString != null) {
      // User may have revoked read/write permission for the file, or user may have deleted the Map
      if (await _storageHandler.hasPermission()) {
        if (await _storageHandler.existsMap()) {
          _hasMap = true;
        } else {
          _errorMessage = 'Map file does not exist.';
        }
      } else {
        _errorMessage = 'Permission has been revoked.';
      }
    } else {
      await _downloadMap();
    }
  }

  /// Download Map from internet
  Future<void> _downloadMap() async {
    final response = await http.get(Uri.parse(kDownloadUrl));

    if (response.statusCode == 200) {
      await _saveMapData(response.bodyBytes);
    } else {
      _errorMessage = 'Failed to download Map';
    }
  }

  /// Save data downloaded data to sdCard
  Future<void> _saveMapData(Uint8List bytes) async {
    final filename = kDownloadUrl.split('/').last;

    final uriString = await _storageHandler.askPermission(PermissionType.write,
        filename: filename);

    if (uriString == null) {
      _errorMessage = 'No file selected to store map';
      return;
    }

    await _storageHandler.writeMapFile(uriString, bytes);

    _mapUriString = uriString;
    await _prefs.setString('downloadedMapUriString', uriString);
    _hasMap = true;
  }
}
