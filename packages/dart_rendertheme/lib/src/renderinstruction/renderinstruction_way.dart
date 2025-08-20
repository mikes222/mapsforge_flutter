import 'package:dart_rendertheme/rendertheme.dart';

/// A RenderInstruction is a basic graphical primitive to draw a map. It reads the
/// instructions from an xml file. It can be seen like a CSS-file for html.
abstract class RenderInstructionWay implements Renderinstruction {
  RenderInstructionWay();

  RenderInstructionWay forZoomlevel(int zoomlevel);
}
