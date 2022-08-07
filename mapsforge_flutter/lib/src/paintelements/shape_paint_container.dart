import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';

import 'shape/shapecontainer.dart';

abstract class ShapePaintContainer<T extends ShapeContainer> {
  final double dy;
  final T shapeContainer;

  const ShapePaintContainer(this.shapeContainer, this.dy);

  Future<void> draw(
      MapCanvas canvas, PixelProjection projection, SymbolCache symbolCache);
}
