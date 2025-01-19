import 'dart:io';

import '../../graphics/graphicfactory.dart';
import '../../graphics/hillshadingbitmap.dart';
import '../../layer/hills/shadetilesource.dart';
import '../../layer/hills/shadingalgorithm.dart';

import 'memorycachinghgtreadertilesource.dart';

/**
 * Mutable frontend for the hillshading cache/processing in {@link HgtCache}
 * <p>All changes are lazily applied when a tile is requested with {@link #getShadingTile}, which includes a full reindex of the .hgt files.
 * Eager indexing on a dedicated thread can be triggered with {@link #indexOnThread} (e.g. after a configuration change or during setup)</p>
 */
class HillsRenderConfig {
  ShadeTileSource? tileSource;

  double maginuteScaleFactor = 1;

//  HillsRenderConfig(ShadeTileSource tileSource) {
//    this.tileSource = tileSource;
//  }

  HillsRenderConfig(File demFolder, GraphicFactory graphicsFactory,
      ShadeTileSource tileSource, ShadingAlgorithm algorithm) {
    this.tileSource = (tileSource == null)
        ? new MemoryCachingHgtReaderTileSource(
            demFolder, algorithm, graphicsFactory)
        : tileSource;
    this.tileSource!.setDemFolder(demFolder);
    this.tileSource!.setShadingAlgorithm(algorithm);
  }

  /**
   * call after initialization, after a set of changes to the settable properties or after forceReindex to initiate background indexing
   */
  HillsRenderConfig indexOnThread() {
    ShadeTileSource? cache = tileSource;
    if (cache != null) cache.applyConfiguration(true);
    return this;
  }

  /**
   * @param latitudeOfSouthWestCorner  tile ID latitude (southwest corner, as customary in .hgt)
   * @param longituedOfSouthWestCorner tile ID longitude (southwest corner, as customary in .hgt)
   * @param pxPerLat                   pixels per degree of latitude (to determine padding quality requirements)
   * @param pxPerLng                   pixels per degree of longitude (to determine padding quality requirements)
   * @return
   * @throws ExecutionException
   * @throws InterruptedException
   */
  HillshadingBitmap? getShadingTile(int latitudeOfSouthWestCorner,
      int longituedOfSouthWestCorner, double pxPerLat, double pxPerLng) {
    ShadeTileSource? tileSource = this.tileSource;
    if (tileSource == null) return null;

    HillshadingBitmap? ret = tileSource.getHillshadingBitmap(
        latitudeOfSouthWestCorner,
        longituedOfSouthWestCorner,
        pxPerLat,
        pxPerLng);
    if (ret == null && (longituedOfSouthWestCorner).abs() > 178) {
      // don't think too hard about where exactly the border is (not much height data there anyway)
      int eastInt = longituedOfSouthWestCorner > 0
          ? longituedOfSouthWestCorner - 180
          : longituedOfSouthWestCorner + 180;
      ret = tileSource.getHillshadingBitmap(
          latitudeOfSouthWestCorner, eastInt, pxPerLat, pxPerLng);
    }

    return ret;
  }

  double getMaginuteScaleFactor() {
    return maginuteScaleFactor;
  }

  /**
   * Increase (&gt;1) or decrease (&lt;1) the hillshading magnitude relative to the value set in themes
   * <p>When designing a theme, this should be one</p>
   */
  void setMaginuteScaleFactor(double maginuteScaleFactor) {
    this.maginuteScaleFactor = maginuteScaleFactor;
  }

  ShadeTileSource? getTileSource() {
    return tileSource;
  }

  void setTileSource(ShadeTileSource tileSource) {
    this.tileSource = tileSource;
  }
}
