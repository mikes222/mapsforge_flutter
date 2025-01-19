import '../nodeproperties.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';

/// A RenderInstruction is a basic graphical primitive to draw a map. It reads the
/// instructions from an xml file. It can be seen like a CSS-file for html.
abstract class RenderInstruction {
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

  String? category;

  RenderInstruction();

  String? getCategory() {
    return this.category;
  }

  /// @param renderCallback a reference to the receiver of all render callbacks.
  /// @param renderContext
  /// @param poi
  void renderNode(final RenderContext renderContext, NodeProperties container);

  /// @param renderCallback a reference to the receiver of all render callbacks.
  /// @param renderContext
  /// @param way
  void renderWay(final RenderContext renderContext, WayProperties way);

  Scale scaleFromValue(String value) {
    if (value == (ALL)) {
      return Scale.ALL;
    } else if (value == (NONE)) {
      return Scale.NONE;
    }
    return Scale.STROKE;
  }

  /// prepares the renderinstruction for the given zoomLevel. Returns the
  /// new RenderInstruction or NULL if it would never draw anything
  RenderInstruction? prepareScale(int zoomLevel);
}

/////////////////////////////////////////////////////////////////////////////

enum Scale { ALL, NONE, STROKE }
