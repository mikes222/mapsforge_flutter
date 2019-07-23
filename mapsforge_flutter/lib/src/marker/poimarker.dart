import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PoiMarker<T> extends BasicMarker<T> {
  Bitmap _bitmap;

  bool _bitmapInvalid = false;

  String _src;

  final int width;

  final int height;

  final int percent;

  final SymbolCache symbolCache;

  final double fontSize;

  PoiMarker({
    caption,
    src,
    display = Display.ALWAYS,
    this.width = 20,
    this.height = 20,
    this.percent,
    this.symbolCache,
    latLong,
    this.fontSize = 10,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    strokeWidth = 1.0,
    strokeColor = 0xff000000,
    imageColor = 0xff000000,
    rotation,
    item,
  })  : assert(caption != null || src != null),
        assert(display != null),
        assert(fontSize != null && fontSize > 0),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(strokeWidth >= 0),
        assert(strokeColor != null),
        assert(imageColor != null),
        super(
          caption: caption,
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          strokeWidth: strokeWidth,
          strokeColor: strokeColor,
          imageColor: imageColor,
          rotation: rotation,
          item: item,
          latLong: latLong,
        ) {
    _src = src;
  }

  @override
  void dispose() {
    super.dispose();
    if (this._bitmap != null) {}
  }

  void initRessources(MarkerCallback markerCallback) {
    super.initRessources(markerCallback);
    if (stroke != null) {
      this.stroke.setTextSize(fontSize);
    }
    if (imagePaint == null) {
      imagePaint = markerCallback.graphicFactory.createPaint();
      imagePaint.setColorFromNumber(imageColor);
    }

    if (this._bitmap == null && !_bitmapInvalid && _src != null && symbolCache != null) {
      try {
        this._bitmap = symbolCache.getBitmap(_src, width, height, percent);
        if (_bitmap != null) {
          imageOffsetX = -_bitmap.getWidth() / 2;
          imageOffsetY = -_bitmap.getHeight() / 2;

          captionOffsetX = 0;
          captionOffsetY = _bitmap.getHeight() / 2;
        } else {
          // not yet in cache, hope that we can get it at next iteration
        }
      } catch (ioException, stacktrace) {
        print("Exception while loading image $_src: " + ioException.toString());
        print(stacktrace);
        this._bitmapInvalid = true;
      }
    }
  }

  void renderBitmap(MarkerCallback markerCallback) {
    if (_bitmap != null) {
      markerCallback.renderBitmap(_bitmap, latLong.latitude, latLong.longitude, imageOffsetX, imageOffsetY, rotation, imagePaint);
    }
  }

  void set src(String src) {
    _bitmap = null;
    _bitmapInvalid = false;
    _src = src;
  }

  @override
  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    if (_bitmap == null) return false;
    double y = mapViewPosition.mercatorProjection.latitudeToPixelY(latLong.latitude);
    double x = mapViewPosition.mercatorProjection.longitudeToPixelX(latLong.longitude);
    x = x + imageOffsetX - mapViewPosition.leftUpper.x;
    y = y + imageOffsetY - mapViewPosition.leftUpper.y;
    return tappedX >= x && tappedX <= x + _bitmap.getWidth() && tappedY >= y && tappedY <= y + _bitmap.getHeight();
  }
}
