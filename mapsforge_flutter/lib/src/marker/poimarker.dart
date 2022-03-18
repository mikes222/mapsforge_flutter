import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PoiMarker<T> extends BasicPointMarker<T> with BitmapMixin {
  double imageOffsetX = 0;

  double imageOffsetY = 0;

  double rotation;

  PoiMarker({
    display = Display.ALWAYS,
    String? src,
    double width = 20,
    double height = 20,
    required latLong,
    minZoomLevel = 0,
    maxZoomLevel = 65535,
    imageColor = 0xff000000,
    this.rotation = 0,
    item,
    markerCaption,
  })  : assert(markerCaption != null || src != null),
        assert(display != null),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation >= 0 && rotation <= 360),
        assert(imageColor != null),
        super(
          markerCaption: markerCaption,
          display: display,
          minZoomLevel: minZoomLevel,
          maxZoomLevel: maxZoomLevel,
          item: item,
          latLong: latLong,
        ) {
    this.bitmapSrc = src;
    this.bitmapWidth = width;
    this.bitmapHeight = height;
  }

  @override
  Future<void> initResources( SymbolCache? symbolCache) async {
    await super.initResources( symbolCache);
    await initBitmap( symbolCache);
    if (markerCaption != null && markerCaption!.latLong == null) {
      markerCaption!.latLong = latLong;
    }

    if (bitmap != null) {
      imageOffsetX = -bitmap!.getWidth() / 2;
      imageOffsetY = -bitmap!.getHeight() / 2;

      if (markerCaption != null) {
        markerCaption!.captionOffsetX = 0;
        markerCaption!.captionOffsetY = bitmap!.getHeight() / 2;
      }
    }
  }

  @override
  void renderBitmap(MarkerCallback markerCallback, int zoomLevel) {
    if (bitmap != null && bitmapPaint != null) {
      markerCallback.renderBitmap(bitmap!, latLong.latitude, latLong.longitude,
          imageOffsetX, imageOffsetY, rotation, bitmapPaint!);
    }
  }

  @override
  bool isTapped(
      MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    if (bitmap == null) return false;
    double y = mapViewPosition.projection!.latitudeToPixelY(latLong.latitude);
    double x = mapViewPosition.projection!.longitudeToPixelX(latLong.longitude);
    x = x + imageOffsetX - mapViewPosition.leftUpper!.x;
    y = y + imageOffsetY - mapViewPosition.leftUpper!.y;
    return tappedX >= x &&
        tappedX <= x + bitmap!.getWidth() &&
        tappedY >= y &&
        tappedY <= y + bitmap!.getHeight();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
