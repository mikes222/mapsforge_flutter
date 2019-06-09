import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/color.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/style.dart';

import 'markercallback.dart';

class BasicMarker {
  final GraphicFactory graphicFactory;
  final String caption;

  Bitmap _bitmap;
  bool _bitmapInvalid = false;

  final String src;
  final Display display;

  final int width;

  final int height;

  final int percent;

  final double latitude;

  final double longitude;

  final SymbolCache symbolCache;

  double imageOffsetX = 0;

  double imageOffsetY = 0;

  double captionOffsetX = 0;

  double captionOffsetY = 0;

  final double fontSize;

  MapPaint stroke;

  BasicMarker({
    this.graphicFactory,
    this.caption,
    this.src,
    this.display = Display.ALWAYS,
    this.width = 20,
    this.height = 20,
    this.percent,
    this.symbolCache,
    this.latitude,
    this.longitude,
    this.fontSize = 10,
  })  : assert(graphicFactory != null),
        assert(caption != null || src != null),
        assert(display != null),
        assert(latitude != null),
        assert(longitude != null),
        assert(fontSize != null && fontSize > 0);

  void init() async {
    this.stroke = graphicFactory.createPaint();
    this.stroke.setColor(Color.BLACK);
    this.stroke.setStyle(Style.STROKE);

    if (this._bitmap == null && !_bitmapInvalid && src != null && symbolCache != null) {
      try {
        this._bitmap = await createBitmap(src);
        imageOffsetX = -_bitmap.getWidth() / 2;
        imageOffsetY = -_bitmap.getHeight() / 2;

        captionOffsetX = 0;
        captionOffsetY = _bitmap.getHeight() / 2;
      } catch (ioException, stacktrace) {
        print(ioException.toString());
        //print(stacktrace);
        this._bitmapInvalid = true;
      }
    }
  }

  @override
  void destroy() {
    if (this._bitmap != null) {}
  }

  Future<Bitmap> createBitmap(String src) async {
    if (null == src || src.isEmpty) {
      return null;
    }

    return symbolCache.getBitmap(src, width, height, percent);
  }

  void renderNode(MarkerCallback markerCallback) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (_bitmap != null) {
      markerCallback.renderBitmap(_bitmap, latitude, longitude, imageOffsetX, imageOffsetY);
    }
    if (caption != null) {
      markerCallback.renderText(caption, latitude, longitude, captionOffsetX, captionOffsetY, stroke, fontSize);
    }
  }
}
