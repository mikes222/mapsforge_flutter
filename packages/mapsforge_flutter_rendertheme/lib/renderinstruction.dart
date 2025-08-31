/// Rendering instructions for drawing map elements and features.
/// 
/// This library provides concrete implementations of rendering instructions
/// that define how different map elements should be drawn. Each instruction
/// type handles specific rendering operations like areas, lines, symbols, and text.
/// 
/// Available rendering instructions:
/// - **Base**: [RenderInstruction] - Abstract base class
/// - **Areas**: [RenderInstructionArea] - Filled polygons and shapes
/// - **Lines**: [RenderInstructionPolyline] - Stroked paths and boundaries
/// - **Symbols**: [RenderInstructionSymbol], [RenderInstructionIcon] - Point symbols
/// - **Text**: [RenderInstructionCaption], [RenderInstructionPolylineText] - Labels
/// - **Shapes**: [RenderInstructionCircle], [RenderInstructionRect] - Geometric shapes
/// - **Special**: [RenderInstructionHillshading] - Terrain visualization
/// - **Decorations**: [RenderInstructionLinesymbol] - Line decorations
library renderinstruction;

export 'src/renderinstruction/renderinstruction.dart';
export 'src/renderinstruction/renderinstruction_area.dart';
export 'src/renderinstruction/renderinstruction_caption.dart';
export 'src/renderinstruction/renderinstruction_circle.dart';
export 'src/renderinstruction/renderinstruction_hillshading.dart';
export 'src/renderinstruction/renderinstruction_icon.dart';
export 'src/renderinstruction/renderinstruction_linesymbol.dart';
export 'src/renderinstruction/renderinstruction_node.dart';
export 'src/renderinstruction/renderinstruction_polyline.dart';
export 'src/renderinstruction/renderinstruction_polyline_text.dart';
export 'src/renderinstruction/renderinstruction_rect.dart';
export 'src/renderinstruction/renderinstruction_symbol.dart';
export 'src/renderinstruction/renderinstruction_way.dart';
