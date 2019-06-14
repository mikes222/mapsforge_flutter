import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

import 'markercallback.dart';

class BasicMarker {
  final String caption;

  Bitmap _bitmap;
  bool _bitmapInvalid = false;

  String _src;
  final Display display;

  final int width;

  final int height;

  final int percent;

  double latitude;

  double longitude;

  final SymbolCache symbolCache;

  double imageOffsetX = 0;

  double imageOffsetY = 0;

  double captionOffsetX = 0;

  double captionOffsetY = 0;

  final double fontSize;

  MapPaint stroke;

  double strokeWidth;

  int strokeColor;

  MapPaint imagePaint;

  int imageColor;

  int minZoomLevel;

  int maxZoomLevel;

  double rotation;

  BasicMarker({
    this.caption,
    src,
    this.display = Display.ALWAYS,
    this.width = 20,
    this.height = 20,
    this.percent,
    this.symbolCache,
    this.latitude,
    this.longitude,
    this.fontSize = 10,
    this.minZoomLevel = 0,
    this.maxZoomLevel = 65535,
    this.strokeWidth = 1,
    this.strokeColor = 0xff000000,
    this.imageColor = 0xff000000,
    this.rotation,
  })  : assert(caption != null || src != null),
        assert(display != null),
        assert(fontSize != null && fontSize > 0),
        assert(minZoomLevel >= 0),
        assert(maxZoomLevel <= 65535),
        assert(rotation == null || (rotation >= 0 && rotation <= 360)),
        assert(strokeWidth >= 0),
        assert(strokeColor != null),
        assert(imageColor != null) {
    _src = src;
  }

  @override
  void dispose() {
    if (this._bitmap != null) {}
  }

  void renderNode(MarkerCallback markerCallback) {
    if (Display.NEVER == this.display) {
      return;
    }
    if (latitude == null || longitude == null) return;

    initRessources(markerCallback);
    renderBitmap(markerCallback);
    renderCaption(markerCallback);
  }

  void initRessources(MarkerCallback markerCallback) {
    if (stroke == null && strokeWidth > 0) {
      this.stroke = markerCallback.graphicFactory.createPaint();
      this.stroke.setColorFromNumber(strokeColor);
      this.stroke.setStyle(Style.STROKE);
      this.stroke.setStrokeWidth(strokeWidth);
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
      markerCallback.renderBitmap(_bitmap, latitude, longitude, imageOffsetX, imageOffsetY, rotation, imagePaint);
    }
  }

  void renderCaption(MarkerCallback markerCallback) {
    if (caption != null) {
      markerCallback.renderText(caption, latitude, longitude, captionOffsetX, captionOffsetY, stroke, fontSize);
    }
  }

  void set src(String src) {
    _bitmap = null;
    _bitmapInvalid = false;
    _src = src;
  }

  bool shouldPaint(BoundingBox boundary, int zoomLevel) {
    return minZoomLevel <= zoomLevel && maxZoomLevel >= zoomLevel && boundary.contains(latitude, longitude);
  }
}
