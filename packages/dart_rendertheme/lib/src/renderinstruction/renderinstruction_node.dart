import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/layer_container.dart';
import 'package:dart_rendertheme/src/model/wayproperties.dart';

/// A RenderInstruction is a basic graphical primitive to draw a map. It reads the
/// instructions from an xml file. It can be seen like a CSS-file for html.
abstract class RenderinstructionNode implements Renderinstruction {
  RenderinstructionNode();

  /// Creates a copy of itself with the data needed for the given zoomlevel. Note that this should only be called from [Rendertheme]
  /// and NOT from [RenderthemeZoomlevel]
  RenderinstructionNode forZoomlevel(int zoomlevel);

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}
}
