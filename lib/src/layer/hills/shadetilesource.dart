import 'dart:io';

import '../../graphics/hillshadingbitmap.dart';
import '../../layer/hills/shadingalgorithm.dart';

/**
 * {@link MemoryCachingHgtReaderTileSource} or a wrapper thereof
 */
abstract class ShadeTileSource {
  /**
   * prepare anything lazily derived from configuration off this thread
   */
  void prepareOnThread();

  /**
   * main work method
   */
  HillshadingBitmap? getHillshadingBitmap(int latitudeOfSouthWestCorner,
      int longituedOfSouthWestCorner, double pxPerLat, double pxPerLng);

  void applyConfiguration(bool allowParallel);

  void setShadingAlgorithm(ShadingAlgorithm algorithm);

  void setDemFolder(File demFolder);
}
