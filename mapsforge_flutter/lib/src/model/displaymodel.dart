import '../graphics/filter.dart';

/// Encapsulates the display characteristics for a MapView, such as tile size and background color. The size of map tiles
/// is used to adapt to devices with differing pixel densities and users with different preferences: The larger the tile,
/// the larger everything is rendered, the effect is one of effectively stretching everything. The default device
/// dependent scale factor is determined at the GraphicFactory level, while the DisplayModel allows further adaptation to
/// cater for user needs or application development (maybe a small map and large map, or to prevent upscaling for
/// downloaded tiles that do not scale well).
class DisplayModel {
  /// the tile size. At zoomLevel 0 the whole world fits onto 1 tile, zoomLevel 1 needs 4 tiles to fit on it and so on.
  static const int DEFAULT_TILE_SIZE = 256;

  int DEFAULT_ZOOM = 10;

  int DEFAULT_INDOOR_LEVEL = 0;

  /// device scale factor. The bigger that value the larger the size of the tiles.
  /// That also means that the map shows more details at a certain zoomLevel. Think of it
  /// the following way: At zoom level 0 the whole world is shown in one tile. That tile is x
  /// times larger depenending on the deviceScaleFactor and userScaleFactor. Therefore a small
  /// widget may not be able to show the whole tile anymore so we see more details at larger
  /// scales.
  final double deviceScaleFactor;

  /// scale factor requested by the user. The bigger that value the larger the size of the tiles.
  /// That also means that the map shows more details at a certain zoomLevel.
  final double userScaleFactor;

  /// sets the scale factor for fonts and symbols. The size of a font or symbol is dependent on the renderertheme,
  /// the deviceScaleFactor, the userScaleFactor AND this property.
  final double fontScaleFactor;

  final double maxTextWidthFactor;

  int backgroundColor = 0xffeeeeee;

  Filter filter = Filter.NONE;

  late int maxTextWidth;

  late int tileSize;

  /// maximum zoomlevel
  int maxZoomLevel;

  /**
   * Returns the device scale factor.
   *
   * @return the device scale factor.
   */
  double getDeviceScaleFactor() {
    return deviceScaleFactor;
  }

  DisplayModel({
    this.maxZoomLevel = 25,
    //this.tileSize = DEFAULT_TILE_SIZE,
    this.deviceScaleFactor = 1.0,
    this.userScaleFactor = 1.0,
    this.maxTextWidthFactor = 0.7,
    this.fontScaleFactor = 1.0,
  }) : assert(maxZoomLevel <= 30 && maxZoomLevel > 0)
  //assert(tileSize >= 256)
  {
    this._setTileSize();
    _setMaxTextWidth();
  }

  /**
   * Returns the background color.
   *
   * @return the background color.
   */
  int getBackgroundColor() {
    return backgroundColor;
  }

  /**
   * Color filtering in map rendering.
   */
  Filter getFilter() {
    return this.filter;
  }

  /**
   * Returns the maximum width of text beyond which the text is broken into lines. This should be
   * used in the graphicsFactory but is currently not used at all
   *
   * @return the maximum text width
   */
  int getMaxTextWidth() {
    return maxTextWidth;
  }

  /**
   * Returns the overall scale factor for non-font related items.
   *
   * @return the combined device/user scale factor.
   */
  double getScaleFactor() {
    return deviceScaleFactor * this.userScaleFactor;
  }

  /// Returns the scale factor for font-related items
  double getFontScaleFactor() {
    return deviceScaleFactor * fontScaleFactor;
  }

  /**
   * Width and height of a map tile in pixel after system and user scaling is applied.
   */
  int getTileSize() {
    return tileSize;
  }

  /**
   * Returns the user scale factor.
   *
   * @return the user scale factor.
   */
  double getUserScaleFactor() {
    return this.userScaleFactor;
  }

  /**
   * Set the background color.
   *
   * @param color the color to use.
   */
  void setBackgroundColor(int color) {
    this.backgroundColor = color;
  }

  /**
   * Color filtering in map rendering.
   */
  void setFilter(Filter filter) {
    this.filter = filter;
  }

  void _setMaxTextWidth() {
    this.maxTextWidth = (this.tileSize * maxTextWidthFactor).ceil();
  }

  void _setTileSize() {
    tileSize = (DEFAULT_TILE_SIZE * deviceScaleFactor * userScaleFactor).ceil();
  }
}
