import 'package:example_sdcard/uilayer/themap.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Allow user to pick a Map from sdcard.
///
/// Once a Map has been selected, its permission and uri will be remembered for future use.
///
/// The user wll be shown a FilePicker to select a Map and grant permission to the app.
class ExistingMap extends StatefulWidget {
  const ExistingMap({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExistingMapState();
}

class _ExistingMapState extends State<ExistingMap> {
  String? _mapUriString;
  String _errorMessage = '';
  MapsforgeStorage _storageHandler = MapsforgeStorage();
  bool _hasMap = false;

  late SharedPreferences _prefs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Existing Map')),
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

  /// Initialize map when preference 'uriString' has been set. 
  /// Else let the user pick a map using the FilePicker.
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _mapUriString = _prefs.getString('existingMapUriString');

    if (_mapUriString != null) {
      _storageHandler = MapsforgeStorage(mapUriString: _mapUriString);

      // User may have revoked permission, or user may have deleted the Map file
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
      await _pickExistingMap();
    }
  }

  /// Pick an existing Map from sdcard
  Future<void> _pickExistingMap() async {
    if (_hasMap) {
      return;
    }

    final uriString = await _storageHandler.askPermission(PermissionType.read);

    if (uriString != null) {
      _hasMap = true;
      _mapUriString = uriString;
      await _prefs.setString('existingMapUriString', uriString);
    } else {
      _errorMessage = 'No Map selected';
    }
  }
}
