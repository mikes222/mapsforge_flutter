/// Shape painting library for rendering map elements to canvas.
/// 
/// This library provides specialized painters for different types of map elements,
/// converting rendering instructions into actual visual output on the canvas.
/// Each painter handles specific geometric shapes and styling requirements.
/// 
/// Key exports:
/// - **ShapePainterArea**: Renders filled polygon areas
/// - **ShapePainterCaption**: Renders text labels and captions
/// - **ShapePainterCircle**: Renders circular shapes and markers
/// - **ShapePainterIcon**: Renders Flutter font-based icons
/// - **ShapePainterLinesymbol**: Renders symbols along line paths
/// - **ShapePainterPolyline**: Renders linear paths and roads
/// - **ShapePainterPolylineText**: Renders text along polyline paths
/// - **ShapePainterRect**: Renders rectangular shapes
/// - **ShapePainterSymbol**: Renders bitmap symbols and images
/// - **PainterFactory**: Factory for creating appropriate painters

export 'src/shape_painter/shape_painter_area.dart';
export 'src/shape_painter/shape_painter_caption.dart';
export 'src/shape_painter/shape_painter_circle.dart';
export 'src/shape_painter/shape_painter_icon.dart';
export 'src/shape_painter/shape_painter_linesymbol.dart';
export 'src/shape_painter/shape_painter_polyline.dart';
export 'src/shape_painter/shape_painter_polyline_text.dart';
export 'src/shape_painter/shape_painter_rect.dart';
export 'src/shape_painter/shape_painter_symbol.dart';
export 'src/util/painter_factory.dart';
