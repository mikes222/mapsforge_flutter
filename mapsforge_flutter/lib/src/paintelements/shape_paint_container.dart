import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';

import 'shape/shapecontainer.dart';

/// A container which holds a shape and is able to draw the shape to the canvas (=Tile)
abstract class ShapePaintContainer<T extends ShapeContainer> {
  final double dy;
  final T shapeContainer;

  const ShapePaintContainer(this.shapeContainer, this.dy);

  Future<void> draw(MapCanvas canvas, SymbolCache symbolCache);
}
