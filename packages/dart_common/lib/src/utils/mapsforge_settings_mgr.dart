import 'dart:math';

class MapsforgeSettingsMgr {
  static MapsforgeSettingsMgr? _instance;

  /// The size of a tile in mappixel. The default is 256. It is discouraged to change this because the images received from most online renderers also
  /// have 256 pixels in size.
  double tileSize = 256;

  /// start to thicken the strokes at this zoomlevel
  int strokeMinZoomlevel = 13;

  /// start to thicken the strokes of texts at this zoomlevel
  int strokeMinZoomlevelText = 18;

  /// Factor of increasing strokes when zooming in.
  double _strokeIncreaseFactor = 1.5;

  /// Do NOT scale beyond this factor
  double _strokeMaxScaleFactor = 5;

  /// sets the scale factor for fonts and symbols. The size of a font or symbol is dependent on the [Rendertheme],
  /// and this property.
  double _fontScaleFactor = 1;

  /// Device scale factor. With value 1 one tile spans exactly [tileSize] pixels at screen. At value 2 the tile will be half the size on screen.
  ///
  /// This is used to make the tiles more crisp on screen.
  double _deviceScaleFactor = 1;

  /// scale factor requested by the user. The bigger that value the larger the size of the tiles.
  /// That also means that the map shows more details at a certain zoomLevel. This does NOT affect the text
  double _userScaleFactor = 1;

  /// The maximum width of a text is dependent on the tile size. We calculate neighbors of
  /// a tile to draw remaining text. If the text is larger than one tile it may span
  /// more than one neighbor which lead to truncated texts.
  final double maxTextWidthFactor = 0.95;

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

  void setDeviceScaleFactor(double deviceScaleFactor) {
    _deviceScaleFactor = deviceScaleFactor;
  }

  void setUserScaleFactor(double userScaleFactor) {
    _userScaleFactor = userScaleFactor;
  }

  void setFontScaleFactor(double fontScaleFactor) {
    _fontScaleFactor = fontScaleFactor;
  }

  /// Returns the scale factor for font-related items.
  double getFontScaleFactor() {
    return _fontScaleFactor;
  }

  double getUserScaleFactor() => _userScaleFactor;

  double getDeviceScaleFactor() => _deviceScaleFactor;

  /// Returns the maximum width of text beyond which the text is broken into lines. This should be
  /// used in the graphicsFactory but is currently not used at all
  ///
  /// @return the maximum text width
  double getMaxTextWidth() {
    return maxTextWidth;
  }

  set strokeIncreaseFactor(double strokeIncreaseFactor) => _strokeIncreaseFactor = strokeIncreaseFactor;

  set strokeMaxScaleFactor(double strokeMaxScaleFactor) => _strokeMaxScaleFactor = strokeMaxScaleFactor;

  /// Many items will be scaled starting at a defined zoomlevel to make them bigger when zooming in. This method calculates the scale factor.
  double calculateScaleFactor(int zoomlevel, int minZoomlevel) {
    int zoomLevelDiff = zoomlevel - minZoomlevel + 1;
    double scaleFactor = pow(_strokeIncreaseFactor, zoomLevelDiff) as double;
    return min(scaleFactor, _strokeMaxScaleFactor);
  }
}
