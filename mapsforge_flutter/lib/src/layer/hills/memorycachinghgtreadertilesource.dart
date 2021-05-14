import 'dart:io';

import '../../graphics/graphicfactory.dart';
import '../../graphics/hillshadingbitmap.dart';
import '../../layer/hills/shadetilesource.dart';
import '../../layer/hills/shadingalgorithm.dart';

import 'hgtcache.dart';

/**
 * Mutable configuration frontend for an underlying {@link HgtCache} (that will be replaced in one piece when parameters change)
 */
class MemoryCachingHgtReaderTileSource implements ShadeTileSource {
  final GraphicFactory graphicsFactory;
  HgtCache? currentCache;
  int mainCacheSize = 4;
  int neighborCacheSize = 4;
  bool enableInterpolationOverlap = true;
  File? demFolder;
  ShadingAlgorithm? algorithm;
  bool configurationChangePending = true;

  MemoryCachingHgtReaderTileSource(
      File demFolder, ShadingAlgorithm algorithm, this.graphicsFactory) {
    this.demFolder = demFolder;
    this.algorithm = algorithm;
  }

  @override
  void applyConfiguration(bool allowParallel) {
    HgtCache? before = currentCache;
    HgtCache? latest = latestCache();
    if (allowParallel && latest != null && latest != before)
      latest.indexOnThread();
  }

  HgtCache? latestCache() {
    HgtCache? ret = this.currentCache;
    if (ret != null && !configurationChangePending) return ret;
    if (demFolder == null || algorithm == null) {
      this.currentCache = null;
      return null;
    }
    if (ret == null ||
        enableInterpolationOverlap != this.currentCache!.interpolatorOverlap ||
        mainCacheSize != this.currentCache!.mainCacheSize ||
        neighborCacheSize != this.currentCache!.neighborCacheSize ||
        demFolder != this.currentCache!.demFolder ||
        algorithm != this.currentCache!.algorithm) {
//      ret = new HgtCache(demFolder, enableInterpolationOverlap, graphicsFactory,
//          algorithm, mainCacheSize, neighborCacheSize);
      this.currentCache = ret;
    }
    return ret;
  }

  @override
  void prepareOnThread() {
    if (currentCache != null) currentCache!.indexOnThread();
  }

  @override
  HillshadingBitmap? getHillshadingBitmap(int latitudeOfSouthWestCorner,
      int longituedOfSouthWestCorner, double pxPerLat, double pxPerLng) {
    if (latestCache() == null) {
      return null;
    }
    return currentCache!.getHillshadingBitmap(latitudeOfSouthWestCorner,
        longituedOfSouthWestCorner, pxPerLat, pxPerLng);
  }

  @override
  void setShadingAlgorithm(ShadingAlgorithm algorithm) {
    this.algorithm = algorithm;
  }

  @override
  void setDemFolder(File demFolder) {
    this.demFolder = demFolder;
  }

  /**
   * @param mainCacheSize number of recently used shading tiles (whole numer latitude/longitude grid) that are kept in memory (default: 4)
   */
  void setMainCacheSize(int mainCacheSize) {
    this.mainCacheSize = mainCacheSize;
  }

  /**
   * @param neighborCacheSize number of additional shading tiles to keep in memory for interpolationOverlap (ignored if enableInterpolationOverlap is false)
   */
  void setNeighborCacheSize(int neighborCacheSize) {
    this.neighborCacheSize = neighborCacheSize;
  }

  /**
   * @param enableInterpolationOverlap false is faster, but shows minor artifacts along the latitude/longitude
   *                                   (if true, preparing a shading tile for high resolution use requires all 4 neighboring tiles to be loaded if they are not in memory)
   */
  void setEnableInterpolationOverlap(bool enableInterpolationOverlap) {
    this.enableInterpolationOverlap = enableInterpolationOverlap;
  }

  int getMainCacheSize() {
    return mainCacheSize;
  }

  int getNeighborCacheSize() {
    return neighborCacheSize;
  }

  bool isEnableInterpolationOverlap() {
    return enableInterpolationOverlap;
  }

  File? getDemFolder() {
    return demFolder;
  }

  ShadingAlgorithm? getAlgorithm() {
    return algorithm;
  }
}
