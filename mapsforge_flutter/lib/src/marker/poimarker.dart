import 'package:mapsforge_flutter/core.dart';
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

  PoiMarker({
    src,
    display = Display.ALWAYS,
    this.width = 20,
    this.height = 20,
    this.percent,
    this.symbolCache,
    latLong,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    imageColor = 0xff000000,
    rotation,
    item,
    markerCaption,
  })  : assert(markerCaption != null || src != null),
        assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(imageColor != null),
        super(
          markerCaption: markerCaption,
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
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
    if (this._bitmap != null) {
      //_bitmap.decrementRefCount();
      _bitmap = null;
    }
  }

  @override
  Future<void> initResources(GraphicFactory graphicFactory) async {
    super.initResources(graphicFactory);
    if (markerCaption != null && markerCaption.latLong == null) {
      markerCaption.latLong = latLong;
    }
    if (imagePaint == null) {
      imagePaint = graphicFactory.createPaint();
      imagePaint.setColorFromNumber(imageColor);
    }

    if (this._bitmap == null && !_bitmapInvalid && _src != null && symbolCache != null) {
      try {
        this._bitmap = await symbolCache.getOrCreateBitmap(_src, width, height, percent);
        if (_bitmap != null) {
          imageOffsetX = -_bitmap.getWidth() / 2;
          imageOffsetY = -_bitmap.getHeight() / 2;

          if (markerCaption != null) {
            markerCaption.captionOffsetX = 0;
            markerCaption.captionOffsetY = _bitmap.getHeight() / 2;
          }
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

  set src(String src) {
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
