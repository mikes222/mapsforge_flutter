import 'package:flutter/foundation.dart';
import 'package:mapsforge_storage/mapsforge_storage.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mapsforge_storage_method_channel.dart';

abstract class MapsforgeStoragePlatform extends PlatformInterface {
  /// Constructs a MapsforgeStoragePlatform.
  MapsforgeStoragePlatform() : super(token: _token);

  static final Object _token = Object();

  static MapsforgeStoragePlatform _instance = MethodChannelMapsforgeStorage();

  /// The default instance of [MapsforgeStoragePlatform] to use.
  ///
  /// Defaults to [MethodChannelMapsforgeStorage].
  static MapsforgeStoragePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MapsforgeStoragePlatform] when
  /// they register themselves.
  static set instance(MapsforgeStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> existsMap(String uriString) {
    throw UnimplementedError('existsMap() has not been implemented.');
  }

  Future<bool> deleteMap(String uriString) {
    throw UnimplementedError('deleteMap() has not been implemented.');
  }

  Future<bool> hasPermission(String uriString) {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  Future<String?> askPermission(PermissionType type, {String? filename}) {
    throw UnimplementedError('askPermission() has not been implemented.');
  }

  Future<bool> writeMapFile(String uriString, Uint8List data) {
    throw UnimplementedError('writeMapFile() has not been implemented.');
  }

  Future<int?> getLength(String uriString) {
    throw UnimplementedError('getLength() has not been implemented.');
  }

  Future<Uint8List?> readMapFile(String uriString, int offset, int length) {
    throw UnimplementedError('readMapFile() has not been implemented.');
  }
}
