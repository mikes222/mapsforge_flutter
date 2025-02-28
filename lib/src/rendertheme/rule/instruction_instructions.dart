import 'package:mapsforge_flutter/src/rendertheme/rule/instructions.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/shape_instructions.dart';

import '../shape/shape.dart';
import '../xml/renderinstruction/renderinstruction_node.dart';
import '../xml/renderinstruction/renderinstruction_way.dart';

class InstructionInstructions implements Instructions {
  final List<RenderInstructionNode> renderInstructionNodes;
  final List<RenderInstructionWay> renderInstructionOpenWays;
  final List<RenderInstructionWay> renderInstructionClosedWays;

  InstructionInstructions(
      {required this.renderInstructionNodes,
      required this.renderInstructionOpenWays,
      required this.renderInstructionClosedWays});

  @override
  bool isEmpty() {
    return renderInstructionNodes.isEmpty &&
        renderInstructionOpenWays.isEmpty &&
        renderInstructionClosedWays.isEmpty;
  }

  ShapeInstructions createShapeInstructions(int zoomlevel) {
    List<Shape> shapeNodes = [];
    for (RenderInstructionNode ri in renderInstructionNodes) {
      Shape? newRi = ri.prepareScale(zoomlevel);
      if (newRi != null) shapeNodes.add(newRi);
    }

    List<Shape> shapeOpenWays = [];
    for (RenderInstructionWay ri in renderInstructionOpenWays) {
      Shape? newRi = ri.prepareScale(zoomlevel);
      if (newRi != null) shapeOpenWays.add(newRi);
    }

    List<Shape> shapeClosedWays = [];
    for (RenderInstructionWay ri in renderInstructionClosedWays) {
      Shape? newRi = ri.prepareScale(zoomlevel);
      if (newRi != null) shapeClosedWays.add(newRi);
    }

    return ShapeInstructions(
        shapeNodes: shapeNodes,
        shapeOpenWays: shapeOpenWays,
        shapeClosedWays: shapeClosedWays);
  }

  @override
  bool hasInstructionsNodes() {
    return renderInstructionNodes.isNotEmpty;
  }

  @override
  bool hasInstructionsOpenWays() {
    return renderInstructionOpenWays.isNotEmpty;
  }

  @override
  bool hasInstructionsClosedWays() {
    return renderInstructionClosedWays.isNotEmpty;
  }
}
