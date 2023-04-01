import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_storage/mapsforge_storage.dart';

import 'mapsforge_storage_platform_interface.dart';

/// An implementation of [MapsforgeStoragePlatform] that uses method channels.
class MethodChannelMapsforgeStorage extends MapsforgeStoragePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mapsforge_storage');

  @override
  Future<bool> existsMap(String uriString) async {
    return await methodChannel.invokeMethod<bool>('existsMap', {
      'uriString': uriString,
    }) ?? false;
  }

  @override
  Future<bool> deleteMap(String uriString) async {
    return await methodChannel.invokeMethod<bool>('deleteMap', {
      'uriString': uriString,
    }) ?? false;
  }

  @override
  Future<bool> hasPermission(String uriString) async {
    final hasPermission = await methodChannel.invokeMethod<bool?>('hasPermission', {
          'uriString': uriString,
        }) ??
        false;

    return hasPermission;
  }

  @override
  Future<String?> askPermission(PermissionType type, {String? filename}) async {
    final uriString = await methodChannel.invokeMethod<String>('askPermission', {
      'type': type.name,
      'filename': filename,
    });

    return uriString;
  }

  @override
  Future<bool> writeMapFile(String uriString, Uint8List bytes) async {
    final isSaved = await methodChannel.invokeMethod<bool>('writeMapFile', {
      'uriString': uriString,
      'data': bytes,
    });

    if (isSaved != null) {
      return isSaved;
    } else {
      throw Exception('No mapfile created.');
    }
  }

  @override
  Future<int?> getLength(String uriString) async {
    return await methodChannel.invokeMethod<int>('getLength', {
      'uriString': uriString,
    });
  }

  @override
  Future<Uint8List?> readMapFile(String uriString, int? offset, int length) async {

    final result = await methodChannel.invokeMethod<Uint8List>('readMapFile', {
      'uriString': uriString,
      'offset': offset ?? offset,
      'length': length,
    });

    return result;
  }
}
