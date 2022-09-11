import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapsrcmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PoiMarker<T> extends BasicPointMarker<T> with BitmapSrcMixin {
  double _imageOffsetX = 0;

  double _imageOffsetY = 0;

  double rotation;

  ResourceBitmap? bitmap;

  PoiMarker({
    Display display = Display.ALWAYS,
    required String src,
    double width = 20,
    double height = 20,
    required ILatLong latLong,
    int minZoomLevel = 0,
    int maxZoomLevel = 65535,
    int bitmapColor = 0xff000000,
    this.rotation = 0,
    T? item,
    MarkerCaption? markerCaption,
  })  : assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation >= 0 && rotation <= 360),
        assert(width > 0),
        assert(height > 0),
        super(
          markerCaption: markerCaption,
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          latLong: latLong,
        ) {
    this.bitmapSrc = src;
    this.setBitmapWidth(width.round());
    this.setBitmapHeight(height.round());
    setBitmapColorFromNumber(bitmapColor);
  }

  @override
  @mustCallSuper
  void dispose() {
    bitmap?.dispose();
    bitmap = null;
    super.dispose();
  }

  Future<void> initResources(SymbolCache symbolCache) async {
    initBitmapSrcMixin(DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT);
    bitmap?.dispose();
    bitmap = null;
    bitmap = await loadBitmap(10, symbolCache);
    if (bitmap != null) {
      _imageOffsetX = -bitmap!.getWidth() / 2;
      _imageOffsetY = -bitmap!.getHeight() / 2;
    }
    if (markerCaption != null) {
      if (bitmap != null) {
        markerCaption!.setDy(bitmap!.getHeight() / 2);
      }
    }
  }

  @override
  void setMarkerCaption(MarkerCaption? markerCaption) {
    if (markerCaption != null) {
      if (bitmap != null) {
        markerCaption.setDy(bitmap!.getHeight() / 2);
      }
    }
    super.setMarkerCaption(markerCaption);
  }

  Future<void> setAndLoadBitmapSrc(
      String bitmapSrc, SymbolCache symbolCache) async {
    super.setBitmapSrc(bitmapSrc);
    await initResources(symbolCache);
  }

  @override
  void renderBitmap(MarkerCallback markerCallback) {
    if (bitmap != null) {
      markerCallback.renderBitmap(bitmap!, latLong.latitude, latLong.longitude,
          _imageOffsetX, _imageOffsetY, rotation, getBitmapPaint());
    }
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    double y = tapEvent.projection.latitudeToPixelY(latLong.latitude);
    double x = tapEvent.projection.longitudeToPixelX(latLong.longitude);
    x = x + _imageOffsetX - tapEvent.leftUpperX;
    y = y + _imageOffsetY - tapEvent.leftUpperY;
    return tapEvent.x >= x &&
        tapEvent.x <=
            x + getBitmapWidth(tapEvent.projection.scalefactor.zoomlevel) &&
        tapEvent.y >= y &&
        tapEvent.y <=
            y + getBitmapHeight(tapEvent.projection.scalefactor.zoomlevel);
  }
}
