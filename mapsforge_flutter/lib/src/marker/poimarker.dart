import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';

import 'basicmarker.dart';
import 'markercallback.dart';

class PoiMarker<T> extends BasicMarker<T> with BitmapMixin {
  double imageOffsetX = 0;

  double imageOffsetY = 0;

  PoiMarker({
    display = Display.ALWAYS,
    String? src,
    double width = 20,
    double height = 20,
    symbolCache,
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
          rotation: rotation,
          item: item,
          latLong: latLong,
        ) {
    this.src = src;
    this.width = width;
    this.height = height;
    this.symbolCache = symbolCache;
  }

  @override
  Future<void> initResources(GraphicFactory graphicFactory) async {
    super.initResources(graphicFactory);
    await initBitmap(graphicFactory);
    if (markerCaption != null && markerCaption!.latLong == null) {
      markerCaption!.latLong = latLong!;
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

  void renderBitmap(MarkerCallback markerCallback) {
    if (bitmap != null && symbolPaint != null) {
      markerCallback.renderBitmap(bitmap!, latLong!.latitude, latLong!.longitude, imageOffsetX, imageOffsetY, rotation, symbolPaint!);
    }
  }

  @override
  bool isTapped(MapViewPosition mapViewPosition, double tappedX, double tappedY) {
    if (bitmap == null) return false;
    double y = mapViewPosition.projection!.latitudeToPixelY(latLong!.latitude);
    double x = mapViewPosition.projection!.longitudeToPixelX(latLong!.longitude);
    x = x + imageOffsetX - mapViewPosition.leftUpper!.x;
    y = y + imageOffsetY - mapViewPosition.leftUpper!.y;
    return tappedX >= x && tappedX <= x + bitmap!.getWidth() && tappedY >= y && tappedY <= y + bitmap!.getHeight();
  }
}
