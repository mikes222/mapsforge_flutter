import 'dart:math';

import '../graphics/filter.dart';
import 'observable.dart';

/// Encapsulates the display characteristics for a MapView, such as tile size and background color. The size of map tiles
/// is used to adapt to devices with differing pixel densities and users with different preferences: The larger the tile,
/// the larger everything is rendered, the effect is one of effectively stretching everything. The default device
/// dependent scale factor is determined at the GraphicFactory level, while the DisplayModel allows further adaptation to
/// cater for user needs or application development (maybe a small map and large map, or to prevent upscaling for
/// downloaded tiles that do not scale well).
class DisplayModel extends Observable {
  static final int DEFAULT_BACKGROUND_COLOR = 0xffeeeeee; // format AARRGGBB
  static final int DEFAULT_TILE_SIZE = 256;
  static final double DEFAULT_MAX_TEXT_WIDTH_FACTOR = 0.7;
  static final int DEFAULT_MAX_TEXT_WIDTH =
      (DEFAULT_TILE_SIZE * DEFAULT_MAX_TEXT_WIDTH_FACTOR).ceil();

  static double defaultUserScaleFactor = 1;
  static double deviceScaleFactor = 1;

  /**
   * Get the default scale factor for all newly created DisplayModels.
   *
   * @return the default scale factor to be applied to all new DisplayModels.
   */
  static double getDefaultUserScaleFactor() {
    return defaultUserScaleFactor;
  }

  /**
   * Returns the device scale factor.
   *
   * @return the device scale factor.
   */
  static double getDeviceScaleFactor() {
    return deviceScaleFactor;
  }

  /**
   * Set the default scale factor for all newly created DisplayModels, so can be used to apply user settings from a
   * device.
   *
   * @param scaleFactor the default scale factor to be applied to all new DisplayModels.
   */
  static void setDefaultUserScaleFactor(double scaleFactor) {
    defaultUserScaleFactor = scaleFactor;
  }

  /**
   * Set the device scale factor.
   *
   * @param scaleFactor the device scale factor.
   */
  static void setDeviceScaleFactor(double scaleFactor) {
    deviceScaleFactor = scaleFactor;
  }

  int backgroundColor = DEFAULT_BACKGROUND_COLOR;
  Filter filter = Filter.NONE;
  int fixedTileSize = DEFAULT_TILE_SIZE;
  int maxTextWidth = DEFAULT_MAX_TEXT_WIDTH;
  double maxTextWidthFactor = DEFAULT_MAX_TEXT_WIDTH_FACTOR;
  int tileSize = DEFAULT_TILE_SIZE;
  int tileSizeMultiple = 64;
  double userScaleFactor = defaultUserScaleFactor;

  DisplayModel() {
    this._setTileSize();
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
   * Returns the maximum width of text beyond which the text is broken into lines.
   *
   * @return the maximum text width
   */
  int getMaxTextWidth() {
    return maxTextWidth;
  }

  /**
   * Returns the overall scale factor.
   *
   * @return the combined device/user scale factor.
   */
  double getScaleFactor() {
    return deviceScaleFactor * this.userScaleFactor;
  }

  /**
   * Width and height of a map tile in pixel after system and user scaling is applied.
   */
  int getTileSize() {
    return tileSize;
  }

  /**
   * Gets the tile size multiple.
   */
  int getTileSizeMultiple() {
    return this.tileSizeMultiple;
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

  /**
   * Forces the tile size to a fixed value
   *
   * @param tileSize the fixed tile size to use if != 0, if 0 the tile size will be calculated
   */
  void setFixedTileSize(int tileSize) {
    this.fixedTileSize = tileSize;
    _setTileSize();
  }

  /**
   * Sets the factor to compute the maxTextWidth
   *
   * @param maxTextWidthFactor to compute maxTextWidth
   */
  void setMaxTextWidthFactor(double maxTextWidthFactor) {
    this.maxTextWidthFactor = maxTextWidthFactor;
    this.setMaxTextWidth();
  }

  /**
   * Clamps the tile size to a multiple of the supplied value.
   * <p/>
   * The default value of tileSizeMultiple will be overwritten with this call.
   * The default value should be good enough for most applications and setting
   * this value should rarely be required.
   * Applications that allow external renderthemes might negatively impact
   * their layout as area fills may depend on the default value being used.
   *
   * @param multiple tile size multiple
   */
  void setTileSizeMultiple(int multiple) {
    this.tileSizeMultiple = multiple;
    _setTileSize();
  }

  /**
   * Set the user scale factor.
   *
   * @param scaleFactor the user scale factor to use.
   */
  void setUserScaleFactor(double scaleFactor) {
    userScaleFactor = scaleFactor;
    _setTileSize();
  }

  void setMaxTextWidth() {
    this.maxTextWidth = (this.tileSize * maxTextWidthFactor).ceil();
  }

  void _setTileSize() {
    if (this.fixedTileSize == 0) {
      double temp = DEFAULT_TILE_SIZE * deviceScaleFactor * userScaleFactor;
      // this will clamp to the nearest multiple of the tileSizeMultiple
      // and make sure we do not end up with 0
      this.tileSize = max(tileSizeMultiple,
          (temp / this.tileSizeMultiple).round() * this.tileSizeMultiple);
    } else {
      this.tileSize = this.fixedTileSize;
    }
    this.setMaxTextWidth();
  }
}
