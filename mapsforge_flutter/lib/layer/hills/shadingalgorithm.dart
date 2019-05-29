import 'dart:io';
import 'dart:typed_data';

import '../../graphics/hillshadingbitmap.dart';

import 'hgtcache.dart';

abstract class ShadingAlgorithm {
//HillshadingBitmap convertTile(RawHillTileSource source, GraphicFactory graphicFactory);

  int getAxisLenght(HgtFileInfo source);

  RawShadingResult transformToByteBuffer(HgtFileInfo hgtFileInfo, int padding);
}

/////////////////////////////////////////////////////////////////////////////

/**
 * Abstracts the file handling and access so that ShadingAlgorithm implementations
 * could run on any height model source (e.g. on an android content provider for
 * data sharing between apps) as long as they understand the format of the stream
 */
abstract class RawHillTileSource {
  int getSize();

  File getFile();

/* for overlap */
  HillshadingBitmap getFinishedConverted();

  /**
   * A ShadingAlgorithm might want to determine the projected dimensions of the tile
   */
  double northLat();

  double southLat();

  double westLng();

  double eastLng();
}

/////////////////////////////////////////////////////////////////////////////

class RawShadingResult {
  final Uint8List bytes;
  final int width;
  final int height;
  final int padding;

  RawShadingResult(this.bytes, this.width, this.height, this.padding);

  /**
   * fill padding like clamp
   */
  void fillPadding(Border side) {
    int innersteps;
    int skip;
    int outersteps;
    int start;
    int sourceOffset;
    int sourceOuterStep;
    int sourceInnerStep;
    int lineLen = padding * 2 + width;
    if (side == Border.WEST || side == Border.EAST) {
      innersteps = padding;
      skip = width + padding;
      outersteps = height;
      if (side == Border.WEST) {
        start = padding * lineLen; // first col, after padding ignored lines
        sourceOffset = start + padding;
      } else {
        start = padding * lineLen +
            padding +
            width; // first padding col after padding ignored lines + nearly one line
        sourceOffset = start - 1;
      }
      sourceInnerStep = 0;
      sourceOuterStep = lineLen;
    } else {
      // horizontal
      innersteps = width;
      skip = 2 * padding;
      outersteps = padding;
      if (side == Border.NORTH) {
        start = padding;
        sourceOffset = start + padding * lineLen;
      } else {
        start = (height + padding) * lineLen + padding;
        sourceOffset = start - lineLen;
      }
      sourceInnerStep = 1;
      sourceOuterStep = -width; // "carriage return"
    }

    int dest = start;
    int src = sourceOffset;
    for (int o = 0; o < outersteps; o++) {
      for (int i = 0; i < innersteps; i++) {
        bytes[dest] = bytes[src];
        dest++;
        src += sourceInnerStep;
      }

      dest += skip;
      src += sourceOuterStep;
    }
  }

  void fillPaddingAll() {
    if (padding < 1) return;
    fillPadding(Border.EAST);
    fillPadding(Border.WEST);
    fillPadding(Border.NORTH);
    fillPadding(Border.SOUTH);

    // fill diagonal padding (this won't be blended with neighbors but the artifacts of that are truely minimal)
    int lineLen = padding * 2 + width;
    int widthOncePadded = width + padding;
    int heightOncePadded = height + padding;
    int nw = bytes[lineLen * padding + padding];
    int ne = bytes[lineLen * padding + widthOncePadded - 1];
    int se = bytes[lineLen * (heightOncePadded - 1) + padding];
    int sw = bytes[lineLen * (heightOncePadded - 1) + (widthOncePadded - 1)];

    int seOffset = lineLen * heightOncePadded;
    int swOffset = seOffset + widthOncePadded;
    for (int y = 0; y < padding; y++) {
      int yoff = lineLen * y;
      for (int x = 0; x < padding; x++) {
        bytes[x + yoff] = nw;
        bytes[x + yoff + widthOncePadded] = ne;
        bytes[x + yoff + seOffset] = se;
        bytes[x + yoff + swOffset] = sw;
      }
    }
  }
}
