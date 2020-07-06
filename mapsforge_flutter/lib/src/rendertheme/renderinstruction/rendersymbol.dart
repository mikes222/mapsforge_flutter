import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/// Represents an icon on the map.
class RenderSymbol extends RenderInstruction {
  Bitmap bitmap;
  bool bitmapInvalid = false;
  Future<Bitmap> _future;
  Display display;
  String id;
  int priority = 0;
  final String relativePathPrefix;
  String src;
  MapPaint symbolPaint;

  RenderSymbol(GraphicFactory graphicFactory, DisplayModel displayModel, symbolCache, this.relativePathPrefix)
      : super(graphicFactory, displayModel, symbolCache) {
    this.display = Display.IFSPACE;
    symbolPaint = graphicFactory.createPaint();
  }

  @override
  void destroy() {
    if (this.bitmap != null) {
      this.bitmap.decrementRefCount();
    }
  }

  Future<void> parse(XmlElement rootElement) async {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.src = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.ID == name) {
        this.id = value;
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.height = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.percent = XmlUtils.parseNonNegativeInteger(name, value);
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.width = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else {
        throw Exception("Symbol probs");
      }
    });
    if (this.bitmap == null && !bitmapInvalid) {
      _future = createBitmap(relativePathPrefix, src);
      _future.then((value) {
        this.bitmap = value;
        this.bitmap.incrementRefCount();
        _future = null;
      }).catchError((ioException) {
        print(ioException.toString());
        //print(stacktrace);
        this.bitmapInvalid = true;
        _future = null;
      });
    }
  }

  String getId() {
    return this.id;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (bitmap != null) {
      renderCallback.renderPointOfInterestSymbol(renderContext, this.display, this.priority, this.bitmap, poi, symbolPaint);
    } else if (_future != null) {
      print("Bitmap not yet loaded");
    }
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (bitmap != null) {
      renderCallback.renderAreaSymbol(renderContext, this.display, this.priority, this.bitmap, way, symbolPaint);
    } else if (_future != null) {
      print("Bitmap not yet loaded");
    }
  }

  @override
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  @override
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    // do nothing
  }

  Future<Bitmap> getBitmap() async {
    if (bitmap != null) return Future.value(bitmap);
    return _future;
  }
}
