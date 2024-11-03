class MapsforgeConstants {

  static MapsforgeConstants? _instance;

  /// The size of a tile in mappixel. The default is 256, but if
  /// deviceScaleFactor or userScaleFactor is not 1 the tileSize will be
  /// stretched accordingly.
  double _tileSize = 0;

  factory MapsforgeConstants() {
    if (_instance != null) return _instance!;
    _instance = MapsforgeConstants._();
    return _instance!;
  }

  MapsforgeConstants._();

  double get tileSize  {
    if (_tileSize == 0) throw Exception("Tilesize not set, init Displaymodel first");
    return _tileSize;
  }

  void set tileSize(double tileSize) {
    if (_tileSize != 0 && _tileSize != tileSize) {
      throw Exception("tilesize already set to $_tileSize, it must be the same");
    }
    _tileSize = tileSize;
  }

}