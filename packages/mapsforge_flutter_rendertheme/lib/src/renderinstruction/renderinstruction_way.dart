import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

/// A RenderInstruction is a basic graphical primitive to draw a map. It reads the
/// instructions from an xml file. It can be seen like a CSS-file for html.
abstract class RenderinstructionWay implements Renderinstruction {
  RenderinstructionWay();

  /// Creates a copy of itself with the data needed for the given zoomlevel. Note that this should only be called from [Rendertheme]
  /// and NOT from [RenderthemeZoomlevel]
  RenderinstructionWay forZoomlevel(int zoomlevel, int level);
}
