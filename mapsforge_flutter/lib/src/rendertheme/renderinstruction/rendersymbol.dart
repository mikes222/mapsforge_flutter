import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/bitmapmixin.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/rendertheme/xml/xmlutils.dart';
import 'package:xml/xml.dart';

import '../rendercallback.dart';
import '../rendercontext.dart';

///
/// Represents an icon on the map. The rendertheme.xml has the possiblity to define a symbol by id and use that symbol later by referring to this id.
/// The [RenderSymbol] class holds a symbol (=bitmap) and refers it by it's id. The class can be used by several other [RenderInstruction] implementation.
///
class RenderSymbol extends RenderInstruction with BitmapMixin {
  Display display = Display.IFSPACE;
  String? id;
  int priority = 0;

  RenderSymbol(GraphicFactory graphicFactory, SymbolCache symbolCache, DisplayModel displayModel) : super(graphicFactory, displayModel) {
    this.symbolCache = symbolCache;
  }

  void parse(XmlElement rootElement, List<RenderInstruction> initPendings) {
    rootElement.attributes.forEach((element) {
      String name = element.name.toString();
      String value = element.value;

      if (RenderInstruction.SRC == name) {
        this.bitmapSrc = value;
      } else if (RenderInstruction.CAT == name) {
        this.category = value;
      } else if (RenderInstruction.DISPLAY == name) {
        this.display = Display.values.firstWhere((e) => e.toString().toLowerCase().contains(value));
      } else if (RenderInstruction.ID == name) {
        this.id = value;
      } else if (RenderInstruction.PRIORITY == name) {
        this.priority = int.parse(value);
      } else if (RenderInstruction.SYMBOL_HEIGHT == name) {
        this.bitmapHeight = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else if (RenderInstruction.SYMBOL_PERCENT == name) {
        this.bitmapPercent = XmlUtils.parseNonNegativeInteger(name, value);
      } else if (RenderInstruction.SYMBOL_SCALING == name) {
// no-op
      } else if (RenderInstruction.SYMBOL_WIDTH == name) {
        this.bitmapWidth = XmlUtils.parseNonNegativeInteger(name, value) * displayModel.getScaleFactor();
      } else {
        throw Exception("Symbol probs");
      }
    });
    if (bitmapSrc != null) initPendings.add(this);
  }

  String? getId() {
    return this.id;
  }

  @override
  void renderNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    if (bitmap != null) {
      renderCallback.renderPointOfInterestSymbol(renderContext, this.display, priority, bitmap!, poi, bitmapPaint);
    }
  }

  @override
  void renderWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return;
    }

    if (way.getCoordinatesAbsolute(renderContext.projection).length == 0) return;

    if (bitmap != null) {
      renderCallback.renderAreaSymbol(renderContext, this.display, priority, bitmap!, way, bitmapPaint);
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

  ///
  /// Returns the specified bitmap or null if loading the bitmap fails
  ///
  // Future<Bitmap> getBitmap(GraphicFactory graphicFactory) async {
  //   return getOrCreateBitmap(graphicFactory, src);
  // }

  @override
  Future<RenderSymbol> initResources(GraphicFactory graphicFactory) async {
    if (Display.NEVER == this.display) {
      //_log.info("display is never for $textKey");
      return this;
    }
    await initBitmap(graphicFactory);
    return this;
  }
}
