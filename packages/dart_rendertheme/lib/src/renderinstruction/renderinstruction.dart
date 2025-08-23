import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:dart_rendertheme/src/model/display.dart';

/// A RenderInstruction is a basic graphical primitive to draw a map. It reads the
/// instructions from an xml file. It can be seen like a CSS-file for html.
abstract class Renderinstruction {
  static final String ALIGN_CENTER = "align-center";
  static final String ALL = "all";
  static final String CAT = "cat";
  static final String DISPLAY = "display";
  static final String DY = "dy";
  static final String FILL = "fill";
  static final String FONT_FAMILY = "font-family";
  static final String FONT_SIZE = "font-size";
  static final String FONT_STYLE = "font-style";
  static final String ID = "id";
  static final String K = "k";
  static final String NONE = "none";
  static final String POSITION = "position";
  static final String PRIORITY = "priority";
  static final String R = "r";
  static final String RADIUS = "radius";
  static final String REPEAT = "repeat";
  static final String REPEAT_GAP = "repeat-gap";
  static final String REPEAT_START = "repeat-start";
  static final String ROTATE = "rotate";
  static final String SCALE = "scale";
  static final String SCALE_RADIUS = "scale-radius";
  static final String SRC = "src";
  static final String STROKE = "stroke";
  static final String STROKE_DASHARRAY = "stroke-dasharray";
  static final String STROKE_LINECAP = "stroke-linecap";
  static final String STROKE_LINEJOIN = "stroke-linejoin";
  static final String STROKE_WIDTH = "stroke-width";
  static final String SYMBOL_HEIGHT = "symbol-height";
  static final String SYMBOL_ID = "symbol-id";
  static final String SYMBOL_PERCENT = "symbol-percent";
  static final String SYMBOL_SCALING = "symbol-scaling";
  static final String SYMBOL_WIDTH = "symbol-width";

  Display display = Display.IFSPACE;

  void renderinstructionScale(Renderinstruction base, int zoomlevel) {
    display = base.display;
  }

  String getType();

  ShapePainter? getPainter();

  /// Returns the boundary of this object around the center of the area or the poi. If the boundary cannot determined exactly we need to estimate it.
  /// This method is used only if the renderinstruction adds itself to label or clash (see [LayerContainer])
  MapRectangle getBoundary();

  /// Checks the nodeProperties and adds itself to the layerContainer if there is something to draw.
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties);

  /// Checks the wayProperties and adds itself to the layerContainer if there is something to draw.
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties);

  void secondPass(Rule rule) {}
}
