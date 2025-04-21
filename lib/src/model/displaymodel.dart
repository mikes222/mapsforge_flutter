import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

/// Encapsulates the display characteristics for a MapView, such as tile size and background color. The size of map tiles
/// is used to adapt to devices with differing pixel densities and users with different preferences: The larger the tile,
/// the larger everything is rendered, the effect is one of effectively stretching everything. The default device
/// dependent scale factor is determined at the GraphicFactory level, while the DisplayModel allows further adaptation to
/// cater for user needs or application development (maybe a small map and large map, or to prevent upscaling for
/// downloaded tiles that do not scale well).
class DisplayModel {
  /// the tile size. At zoomLevel 0 the whole world fits onto 1 tile, zoomLevel 1 needs 2*2=4 tiles to fit on it and so on.
  static const int DEFAULT_TILE_SIZE = 256;

  /// start to thicken the strokes at this zoomlevel
  static const int STROKE_MIN_ZOOMLEVEL = 13;

  /// start to thicken the strokes of texts at this zoomlevel
  static const int STROKE_MIN_ZOOMLEVEL_TEXT = 18;

  int DEFAULT_ZOOM = 10;

  int DEFAULT_INDOOR_LEVEL = 0;

  double DEFAULT_ROTATION = 0;

  /// Device scale factor. The bigger that value the larger the size of the tiles and hence the map. In [ViewModel] the map will be shrinked again
  /// by the same factor so that the size stays the same but the quality of the image increases.
  final double deviceScaleFactor;

  /// scale factor requested by the user. The bigger that value the larger the size of the tiles.
  /// That also means that the map shows more details at a certain zoomLevel.
  final double userScaleFactor;

  /// sets the scale factor for fonts and symbols. The size of a font or symbol is dependent on the renderertheme,
  /// and this property.
  final double fontScaleFactor;

  /// The maximum width of a text is dependent on the tile size. We calculate neighbors of
  /// a tile to draw remaining text. If the text is larger than one tile it may span
  /// more than one neighbor which lead to truncated texts.
  final double maxTextWidthFactor;

  int backgroundColor;

  late double maxTextWidth;

  /// The size of a tile in mappixel. The default is 256, but if
  /// deviceScaleFactor or userScaleFactor is not 1 the tileSize will be
  /// stretched accordingly.
  //late int tileSize;

  /// maximum zoomlevel
  ZoomlevelRange zoomlevelRange;

  /**
   * Returns the device scale factor.
   *
   * @return the device scale factor.
   */
  double getDeviceScaleFactor() {
    return deviceScaleFactor;
  }

  DisplayModel({
    int maxZoomLevel = 25,
    //this.tileSize = DEFAULT_TILE_SIZE,
    this.deviceScaleFactor = 1.0,
    this.userScaleFactor = 1.0,
    this.maxTextWidthFactor = 0.9,
    this.fontScaleFactor = 1.0,
    this.backgroundColor = 0xffeeeeee,
    int tilesize = DEFAULT_TILE_SIZE,
  })  : assert(maxZoomLevel <= 30 && maxZoomLevel > 0),
        assert(maxTextWidthFactor > 0),
        assert(tilesize > 0),
        zoomlevelRange = ZoomlevelRange(0, maxZoomLevel) {
    this._setTileSize(tilesize);
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
   * Returns the maximum width of text beyond which the text is broken into lines. This should be
   * used in the graphicsFactory but is currently not used at all
   *
   * @return the maximum text width
   */
  double getMaxTextWidth() {
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
  // int getTileSize() {
  //   return tileSize;
  // }

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

  void _setMaxTextWidth() {
    this.maxTextWidth = MapsforgeConstants().tileSize * maxTextWidthFactor;
  }

  void _setTileSize(int tilesize) {
    MapsforgeConstants().tileSize = (tilesize * getScaleFactor());
  }
}
