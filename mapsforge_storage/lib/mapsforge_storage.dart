import 'package:flutter/foundation.dart';

import 'mapsforge_storage_platform_interface.dart';

/// The type of permission to ask.
enum PermissionType {
  read,
  write,
}

class MapsforgeStorage {
  /// Contains Uri of Map file
  String? _mapUriString;
  int _currentOffset = 0;

  /// Handles access to Storage Access Framework (SAF) of Andoid, providing
  /// user more options as to where to store a map.
  ///
  /// Parameter [mapUriString] can be empty when no map has been downloaded or no existing map
  /// has been picked yet.
  MapsforgeStorage({String? mapUriString}) : _mapUriString = mapUriString;

  /// Check if map file exists.
  Future<bool> existsMap() async {
    assert(_mapUriString != null, 'No uri provided through constructor.');

    final exists =
        await MapsforgeStoragePlatform.instance.existsMap(_mapUriString!);

    return exists;
  }

  /// Delete map file.
  Future<bool> deleteMap() async {
    assert(_mapUriString != null, 'No uri provided through constructor.');

    final exists =
        await MapsforgeStoragePlatform.instance.deleteMap(_mapUriString!);

    return exists;
  }

  /// Check if application has permission to read/write map file.
  Future<bool> hasPermission() async {
    assert(
      _mapUriString != null,
      'No mapUriString provided through constructor.',
    );

    final hasPermission =
        await MapsforgeStoragePlatform.instance.hasPermission(_mapUriString!);

    return hasPermission;
  }

  /// Ask Android to grant write permission to create a file, or read permission for existing file.
  ///
  /// [type] determines whether `read` or `write` permission is required. When `write` permission is
  /// required, an optional [filename] can be provided.
  Future<String?> askPermission(PermissionType type, {String? filename}) async {
    final uriString = await MapsforgeStoragePlatform.instance.askPermission(
      type,
      filename: filename,
    );

    // Only save uriString of selected map when user has not cancelled FilePicker.
    _mapUriString = uriString ?? _mapUriString;

    return uriString;
  }

  /// Write downloaded map data to sdcard.
  ///
  /// Write [bytes] to [uriString].
  Future<void> writeMapFile(String uriString, Uint8List bytes) async {
    await MapsforgeStoragePlatform.instance.writeMapFile(uriString, bytes);
  }

  /// Get the size of the map file.
  Future<int?> getLength() async {
    assert(_mapUriString != null, 'No uri provided through constructor.');

    final length =
        await MapsforgeStoragePlatform.instance.getLength(_mapUriString!);

    return length;
  }

  /// Read data from the map file.
  ///
  /// Read [length] number of bytes, starting at [offset].
  /// If [offset] is `null`, reading will start at end of previous read action.
  Future<Uint8List?> readMapFile(int? offset, int length) async {
    assert(_mapUriString != null, 'No uri provided through constructor.');

    final data = await MapsforgeStoragePlatform.instance
        .readMapFile(_mapUriString!, offset ?? _currentOffset, length);

    if (offset == null) {
      _currentOffset += length;
    } else {
      _currentOffset = offset + length;
    }

    return data;
  }
}
