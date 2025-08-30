# dart_rendertheme

A comprehensive Dart package for rendering map themes in the Mapsforge ecosystem. This package provides a complete implementation of XML-based theme parsing and rendering instruction generation for creating beautiful, customizable map visualizations.

## Overview

The `dart_rendertheme` package is the core theming engine for Mapsforge Flutter applications. It processes XML theme files and converts them into rendering instructions that define how map features should be visually represented. The package supports complex styling rules, zoom-level dependent rendering, and high-performance caching for optimal map rendering performance.

## Key Features

- **XML Theme Processing**: Parse and process Mapsforge XML theme files
- **Rendering Instructions**: Generate optimized rendering instructions for map features
- **Zoom Level Support**: Dynamic styling based on zoom levels with automatic scaling
- **Performance Optimization**: LRU caching for rule matching and rendering instructions
- **Comprehensive Styling**: Support for areas, lines, symbols, icons, and text labels
- **Indoor Mapping**: 3D mapping support with indoor level handling
- **Rule Matching**: Efficient matching of map features against styling rules

## Core Components

### Theme Engine
- **`RenderTheme`**: Main theme engine managing rule hierarchies and zoom-dependent styling
- **`RenderThemeBuilder`**: XML parser for building theme instances from XML files
- **`RenderthemeZoomlevel`**: Zoom-specific theme with cached rule matching

### Rendering Instructions
- **`RenderinstructionArea`**: Polygon area rendering with fills and strokes
- **`RenderinstructionPolyline`**: Linear path rendering for roads and boundaries
- **`RenderinstructionCircle`**: Circular shape rendering for POI markers
- **`RenderinstructionCaption`**: Text label rendering with positioning control
- **`RenderinstructionSymbol`**: Bitmap symbol rendering with rotation support
- **`RenderinstructionIcon`**: Flutter font-based icon rendering

### Data Models
- **`MapPositioning`**: Element positioning relative to anchor points
- **`MapDisplay`**: Display mode control for rendering instructions
- **`LayerContainer`**: Hierarchical layer management for rendering order

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_rendertheme: ^1.0.0
```

## Usage

### Basic Theme Loading

```dart
import 'package:dart_rendertheme/rendertheme.dart';

// Load theme from XML file
final themeBuilder = RenderThemeBuilder();
final renderTheme = await themeBuilder.buildFromXml(xmlContent);

// Prepare theme for specific zoom level
renderTheme.prepareScale(zoomLevel);
```

### Rendering Map Features

```dart
// Match POI against theme rules
final instructions = renderTheme.matchNode(indoorLevel, pointOfInterest);

// Match area against theme rules
final areaInstructions = renderTheme.matchClosedWay(tile, way);

// Match linear way against theme rules
final lineInstructions = renderTheme.matchLinearWay(tile, way);
```

### Custom Styling

```dart
// Create custom area instruction
final areaInstruction = RenderinstructionArea(level: 5)
  ..fillColor = Colors.blue.value
  ..strokeColor = Colors.darkBlue.value
  ..strokeWidth = 2.0;

// Create custom text caption
final captionInstruction = RenderinstructionCaption(level: 10)
  ..textKey = TextKey('name')
  ..fontSize = 12.0
  ..fillColor = Colors.black.value
  ..position = MapPositioning.CENTER;
```

### Performance Optimization

```dart
// Enable caching for better performance
final zoomTheme = renderTheme.getRenderthemeZoomlevel(zoomLevel);

// Cached matching (automatic)
final cachedInstructions = zoomTheme.matchNode(indoorLevel, poi);
```

## Package Structure

```
lib/
├── rendertheme.dart              # Main theme engine exports
├── model.dart                    # Data models and structures
├── renderinstruction.dart        # Rendering instruction classes
└── src/
    ├── model/                    # Core data models
    ├── renderinstruction/        # Rendering instruction implementations
    ├── rule/                     # Rule matching and processing
    ├── xml/                      # XML parsing and utilities
    ├── matcher/                  # Feature matching algorithms
    └── util/                     # Utility classes and helpers
```

## Performance Considerations

### Caching Strategy
- **Rule Matching Cache**: LRU cache with 100-item capacity per feature type
- **Zoom Level Preparation**: Pre-computed themes for each zoom level
- **Instruction Reuse**: Cached rendering instructions for identical features

### Optimization Features
- **Douglas-Peucker Algorithm**: Optimized line simplification for better performance
- **Squared Distance Calculations**: Avoid expensive sqrt operations
- **Stack-based Processing**: Memory-efficient rule processing
- **Bitmap Scaling Control**: Prevent visual artifacts in linear features

## XML Theme Format

The package supports standard Mapsforge XML theme format:

```xml
<rendertheme xmlns="http://mapsforge.org/renderTheme" version="1">
  <rule e="way" k="highway" v="primary">
    <line stroke="#FF6600" stroke-width="3.0"/>
    <caption k="name" font-size="12" fill="#000000"/>
  </rule>
  
  <rule e="node" k="amenity" v="restaurant">
    <symbol src="restaurant.png"/>
    <caption k="name" position="below" font-size="10"/>
  </rule>
</rendertheme>
```

## Advanced Features

### Indoor Mapping
```dart
// Support for 3D indoor mapping
final indoorInstructions = renderTheme.matchNode(
  indoorLevel: 2,  // Second floor
  pointOfInterest: poi
);
```

### Custom Matchers
```dart
// Implement custom feature matching
class CustomMatcher extends AttributeMatcher {
  @override
  bool matches(Map<String, String> tags) {
    return tags['custom_key'] == 'custom_value';
  }
}
```

### Symbol Management
```dart
// Define reusable symbols
final symbolInstruction = RenderinstructionSymbol(level: 5)
  ..id = 'poi_restaurant'
  ..bitmapSrc = 'assets/restaurant.png'
  ..positioning = MapPositioning.CENTER;
```

## Dependencies

- **`mapsforge_flutter_core`**: Core utilities and data models
- **`xml`**: XML parsing and processing
- **`ecache`**: LRU caching implementation
- **`collection`**: Enhanced collection utilities

## Contributing

1. Follow the existing code style and documentation standards
2. Add comprehensive tests for new features
3. Update documentation for API changes
4. Ensure performance optimizations are maintained

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

## Related Packages

- **`mapsforge_flutter_core`**: Core utilities and data structures
- **`dart_mapfile`**: Map file reading and processing
- **`mapsforge_flutter`**: Complete Flutter mapping solution
