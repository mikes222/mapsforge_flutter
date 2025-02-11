import 'package:mapsforge_flutter/src/rendertheme/rule/instructions.dart';

import '../shape/shape.dart';

class ShapeInstructions implements Instructions {
  final List<Shape> shapeNodes;
  final List<Shape> shapeOpenWays;
  final List<Shape> shapeClosedWays;

  ShapeInstructions(
      {required this.shapeNodes,
      required this.shapeOpenWays,
      required this.shapeClosedWays});

  @override
  bool isEmpty() {
    return shapeNodes.isEmpty &&
        shapeOpenWays.isEmpty &&
        shapeClosedWays.isEmpty;
  }
}
