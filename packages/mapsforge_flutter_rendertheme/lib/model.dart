/// Data models and structures for map rendering and styling.
///
/// This library contains the core data models used throughout the rendering
/// system, including layer management, geometric primitives, styling properties,
/// and rendering context information.
///
/// Key model categories:
/// - **Layer Management**: [LayerContainer], [LayerContainerCollection]
/// - **Geometric Primitives**: [LineSegment], [LineSegmentPath]
/// - **Styling Properties**: [MapCap], [MapJoin], [MapFontFamily], [MapFontStyle]
/// - **Positioning**: [MapPositioning] for element placement
/// - **Feature Properties**: [NodeProperties], [WayProperties]
/// - **Rendering Context**: [RenderContext], [RenderInfo] and variants
/// - **Graphics**: [ShapePainter] for custom drawing operations
library;

export 'src/model/layer_container.dart';
export 'src/model/layer_container_collection.dart';
export 'src/model/line_segment.dart';
export 'src/model/line_segment_path.dart';
export 'src/model/map_cap.dart';
export 'src/model/map_display.dart';
export 'src/model/map_fillrule.dart';
export 'src/model/map_font_family.dart';
export 'src/model/map_font_style.dart';
export 'src/model/map_join.dart';
export 'src/model/map_positioning.dart';
export 'src/model/nodeproperties.dart';
export 'src/model/render_context.dart';
export 'src/model/render_info.dart';
export 'src/model/render_info_collection.dart';
export 'src/model/render_info_node.dart';
export 'src/model/render_info_way.dart';
export 'src/model/shape_painter.dart';
export 'src/model/wayproperties.dart';
