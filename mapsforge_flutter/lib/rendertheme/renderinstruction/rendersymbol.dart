import 'package:mapsforge_flutter/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/graphics/bitmap.dart';
import 'package:mapsforge_flutter/graphics/display.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/model/displaymodel.dart';
import 'package:mapsforge_flutter/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

/**
 * Represents an icon on the map.
 */
class RenderSymbol extends RenderInstruction {
  Bitmap bitmap;
  bool bitmapInvalid;
  Display display;
  String id;
  int priority;
  final String relativePathPrefix;
  String src;

  RenderSymbol(GraphicFactory graphicFactory, DisplayModel displayModel, this.relativePathPrefix) : super(graphicFactory, displayModel) {
    this.display = Display.IFSPACE;
  }

  @override
  void destroy() {
    if (this.bitmap != null) {
      this.bitmap.decrementRefCount();
    }
  }

  void parse(XmlElement rootElement) {
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
  }

  Bitmap getBitmap() {
    if (this.bitmap == null && !bitmapInvalid) {
      try {
        this.bitmap = createBitmap(relativePathPrefix, src);
      } catch (ioException) {
        this.bitmapInvalid = true;
      }
    }
    return this.bitmap;
  }

  String getId() {
    return this.id;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (getBitmap() != null) {
      renderCallback.renderPointOfInterestSymbol(renderContext, this.display, this.priority, this.bitmap, poi);
    }
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      return;
    }

    if (this.getBitmap() != null) {
      renderCallback.renderAreaSymbol(renderContext, this.display, this.priority, this.bitmap, way);
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
}
