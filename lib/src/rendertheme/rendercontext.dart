import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_symbol.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../../core.dart';

/// A RenderContext contains all the information and data to render a map area, it is passed between
/// calls in order to avoid local data stored in the DatabaseRenderer.
class RenderContext {
  static final _log = new Logger('RenderContext');

  static final int MAX_DRAWING_LAYERS = 11;

  final Tile upperLeft;

  final int maxLevels;

  // The current drawing layer is the layer defined by the poi/way.
  late LayerPaintContainer currentDrawingLayer;

  /// The points to process. Points may be drawn directly into the tile or later onto the tile. Reason is that
  /// points should be drawn horizontally even if the underlying map (=tiles) are rotated.
  final List<RenderInfo> labels = [];

  late List<LayerPaintContainer> drawingLayers;

  /// A drawing layer for symbols which do not need to be rotated based on the current rotation of the map. This
  /// applies for example to arrows for one-way-streets. But before painting the arrows we want to avoid clashes.
  late LayerPaintContainer clashDrawingLayer;

  final PixelProjection projection;

  RenderContext(this.upperLeft, this.maxLevels) : projection = PixelProjection(upperLeft.zoomLevel) {
    this.drawingLayers = _createWayLists();
    currentDrawingLayer = drawingLayers[0];
    clashDrawingLayer = LayerPaintContainer(maxLevels);
  }

  void setDrawingLayers(int layer) {
    assert(layer >= 0);
    if (layer >= RenderContext.MAX_DRAWING_LAYERS) {
      layer = RenderContext.MAX_DRAWING_LAYERS - 1;
    }
    this.currentDrawingLayer = drawingLayers.elementAt(layer);
  }

  /// The level is the order of the renderinstructions in the xml-file
  void addToCurrentDrawingLayer(int level, RenderInfo element) {
    currentDrawingLayer.add(level, element);
  }

  void addToClashDrawingLayer(int level, RenderInfo element) {
    clashDrawingLayer.add(level, element);
  }

  Future<void> initDrawingLayers(SymbolCache symbolCache) async {
    Timing timing = Timing(log: _log);
    List<Future> futures = [];

    for (LayerPaintContainer layerPaintContainer in drawingLayers) {
      for (List<RenderInfo> wayList in layerPaintContainer.ways) {
        for (RenderInfo renderInfo in wayList) {
          futures.add(renderInfo.createShapePaint(symbolCache));
          if (futures.length > 100) {
            await Future.wait(futures);
            futures.clear();
          }
        }
      }
    }
    for (List<RenderInfo> wayList in clashDrawingLayer.ways) {
      for (RenderInfo renderInfo in wayList) {
        futures.add(renderInfo.createShapePaint(symbolCache));
        if (futures.length > 100) {
          await Future.wait(futures);
          futures.clear();
        }
      }
    }
    for (RenderInfo renderInfo in labels) {
      futures.add(renderInfo.createShapePaint(symbolCache));
      if (futures.length > 100) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    await Future.wait(futures);
    timing.done(100, "initDrawingLayers");
  }

  List<LayerPaintContainer> _createWayLists() {
    List<LayerPaintContainer> result = List.generate(MAX_DRAWING_LAYERS, (int idx) => LayerPaintContainer(maxLevels));
    return result;
  }

  void disposeLabels() {
    labels.clear();
  }

  void reduce() {
    drawingLayers.forEach((layerPaintContainer) => layerPaintContainer.reduce());
    drawingLayers.removeWhere((test) => test.ways.isEmpty);
    // int idx = 0;
    // List.of(drawingLayers).forEach((LayerPaintContainer layerPaintContainer) {
    //   layerPaintContainer.reduce();
    //   if (layerPaintContainer.ways.length == 0) {
    //     drawingLayers.removeAt(idx);
    //   } else {
    //     ++idx;
    //   }
    // });
    clashDrawingLayer.reduce();
  }

  @override
  String toString() {
    return 'RenderContext{maxLevels: $maxLevels, labels: ${labels.length}, drawingLayers: $drawingLayers, clashDrawingLayer: $clashDrawingLayer}';
  }

  void statistics() {
    int nullLabels = 0;
    Map<String, int> statLabels = {};
    labels.forEach((RenderInfo renderInfo) {
      if (renderInfo.caption == null) {
        if (renderInfo.shape is ShapeSymbol) {
          ShapeSymbol shapeSymbol = renderInfo.shape as ShapeSymbol;
          statLabels["ID: ${shapeSymbol.bitmapSrc}"] = (statLabels["ID: ${shapeSymbol.bitmapSrc}"] ?? 0) + 1;
        } else {
          ++nullLabels;
        }
        return;
      }
      if (statLabels.containsKey(renderInfo.caption))
        statLabels[renderInfo.caption!] = statLabels[renderInfo.caption!]! + 1;
      else
        statLabels[renderInfo.caption!] = 1;
    });
    print("Labels: ${labels.length}");
    if (nullLabels > 0) print("Label <null>: $nullLabels");
    statLabels.forEach((String key, int value) {
      print("Label ${key} : ${value}");
    });
    drawingLayers.forEachIndexed((int idx, LayerPaintContainer layerPaintContainer) {
      print("DrawingLayer $idx: ${layerPaintContainer.ways.length} levels");
      layerPaintContainer.ways.forEachIndexed((int idx, List<RenderInfo> renderInfos) {
        print("  Level $idx: ${renderInfos.length} renderInfos");
        Map<String, int> types = {};
        renderInfos.forEach((RenderInfo renderInfo) {
          int count = types[renderInfo.getShapeType()] ?? 0;
          ++count;
          types[renderInfo.getShapeType()] = count;
        });
        types.forEach((String key, int value) {
          print("    $key: $value");
        });
      });
    });
    print("ClashDrawingLayer: ${clashDrawingLayer.ways.length} levels");
    clashDrawingLayer.ways.forEachIndexed((int idx, List<RenderInfo> renderInfos) {
      print("  Level $idx: ${renderInfos.length} renderInfos");
      Map<String, int> types = {};
      renderInfos.forEach((RenderInfo renderInfo) {
        int count = types[renderInfo.getShapeType()] ?? 0;
        ++count;
        types[renderInfo.getShapeType()] = count;
      });
      types.forEach((String key, int value) {
        print("    $key: $value");
      });
    });
  }
}

/////////////////////////////////////////////////////////////////////////////

///
/// A container which holds all paintings for one layer. A layer is defined by the datastore. It is a property of the ways
/// in the datastore. So in other words you can define which way should be drawn in the back and which should be drawn
/// at the front.
class LayerPaintContainer {
  late List<List<RenderInfo>> ways;

  ///
  /// Define the maximum number of levels.
  LayerPaintContainer(int levels) {
    ways = List.generate(levels, (int index) => []);
  }

  void add(int level, RenderInfo element) {
    //_log.info("Adding level $level to layer with ${drawingLayers.length} levels");
    this.ways[level].add(element);
  }

  void reduce() {
    int idx = 0;
    ways.removeWhere((test) => test.isEmpty);
    // List.of(ways).forEach((List<RenderInfo> renderInfos) {
    //   if (renderInfos.length == 0) {
    //     ways.removeAt(idx);
    //   } else {
    //     ++idx;
    //   }
    // });
  }

  @override
  String toString() {
    return 'LayerPaintContainer{ways: ${ways.length} outer ways}';
  }
}
