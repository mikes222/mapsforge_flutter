class MapsforgeSettingsMgr {
  static MapsforgeSettingsMgr? _instance;

  /// The size of a tile in mappixel. The default is 256, but if
  /// deviceScaleFactor or userScaleFactor is not 1 the tileSize will be
  /// stretched accordingly.
  double _tileSize = 256;

  /// start to thicken the strokes at this zoomlevel
  int strokeMinZoomlevel = 13;

  /// start to thicken the strokes of texts at this zoomlevel
  int strokeMinZoomlevelText = 18;

  /// sets the scale factor for fonts and symbols. The size of a font or symbol is dependent on the renderertheme,
  /// and this property.
  double _fontScaleFactor = 1;

  /// Device scale factor. The bigger that value the larger the size of the tiles and hence the map. In [ViewModel] the map will be shrinked again
  /// by the same factor so that the size stays the same but the quality of the image increases.
  double _deviceScaleFactor = 1;

  /// scale factor requested by the user. The bigger that value the larger the size of the tiles.
  /// That also means that the map shows more details at a certain zoomLevel. This does NOT affect the text
  double _userScaleFactor = 1;

  /// The maximum width of a text is dependent on the tile size. We calculate neighbors of
  /// a tile to draw remaining text. If the text is larger than one tile it may span
  /// more than one neighbor which lead to truncated texts.
  final double maxTextWidthFactor = 0.9;

  late double maxTextWidth;

  factory MapsforgeSettingsMgr() {
    if (_instance != null) return _instance!;
    _instance = MapsforgeSettingsMgr._();
    return _instance!;
  }

  MapsforgeSettingsMgr._() {
    _setMaxTextWidth();
  }

  void _setMaxTextWidth() {
    maxTextWidth = tileSize * maxTextWidthFactor;
  }

  double get tileSize {
    if (_tileSize == 0) throw Exception("Tilesize not set, init Displaymodel first");
    return _tileSize;
  }

  /// Called by Displaymodel to provide easy access to the tilesize. Make sure that all maps are
  /// disposed() before setting a new tilesize. Rendering tiles with changing tilesizes could
  /// cause unexpected behavior.
  void set tileSize(double tileSize) {
    // if (_tileSize != 0 && _tileSize != tileSize) {
    //   throw Exception("tilesize already set to $_tileSize, it must be the same");
    // }
    _tileSize = tileSize;
  }

  void setDeviceScaleFactor(double deviceScaleFactor) {
    _deviceScaleFactor = deviceScaleFactor;
  }

  void setUserScaleFactor(double userScaleFactor) {
    _userScaleFactor = userScaleFactor;
  }

  /// Returns the overall scale factor for non-font related items.
  ///
  /// @return the combined device/user scale factor.
  double getScaleFactor() {
    return _deviceScaleFactor * _userScaleFactor;
  }

  /// Returns the scale factor for font-related items
  double getFontScaleFactor() {
    return _deviceScaleFactor * _fontScaleFactor;
  }

  /// Returns the maximum width of text beyond which the text is broken into lines. This should be
  /// used in the graphicsFactory but is currently not used at all
  ///
  /// @return the maximum text width
  double getMaxTextWidth() {
    return maxTextWidth;
  }
}
