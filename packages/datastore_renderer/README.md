# datastore_renderer

A high-performance tile rendering engine for the Mapsforge Flutter ecosystem. This package provides comprehensive rendering capabilities for converting map data from various sources into visual tile representations with advanced caching, spatial indexing, and performance optimizations.

## Overview

The `datastore_renderer` package is the core rendering engine that transforms map data into beautiful, interactive tile images. It supports multiple data sources including local datastores, online tile services, and provides sophisticated shape painting capabilities for all types of map elements.

## Key Features

- **Multi-Source Rendering**: Support for local datastores, ArcGIS Online, and OpenStreetMap services
- **High-Performance Rendering**: Optimized tile generation with object pooling and caching
- **Spatial Indexing**: Grid-based collision detection for optimal label placement
- **Shape Painting**: Specialized painters for areas, lines, symbols, icons, and text
- **Asynchronous Processing**: Non-blocking rendering with job queue management
- **Symbol Caching**: Efficient bitmap symbol loading and scaling
- **Label Extraction**: Separate label rendering for rotation support
- **Canvas Abstraction**: Cross-platform rendering with Flutter integration

## Core Components

### Rendering Engines
- **`DatastoreRenderer`**: Main renderer for local map data with theme support
- **`ArcGISOnlineRenderer`**: Renderer for ArcGIS online tile services
- **`OSMOnlineRenderer`**: Renderer for OpenStreetMap tile services
- **`DummyRenderer`**: Placeholder renderer for testing and development

### Shape Painters
- **`ShapePaintArea`**: Renders filled polygon areas with patterns and strokes
- **`ShapePainterCaption`**: Renders text labels with positioning and styling
- **`ShapePainterCircle`**: Renders circular shapes and markers
- **`ShapePainterIcon`**: Renders Flutter font-based icons
- **`ShapePainterPolyline`**: Renders linear paths and roads
- **`ShapePainterSymbol`**: Renders bitmap symbols and images

### Caching System
- **`SymbolCacheMgr`**: Central manager for symbol caching operations
- **`FileSymbolCache`**: File-based symbol caching implementation
- **`ImageBundleLoader`**: Efficient loading of bundled image assets

### Utilities
- **`SpatialIndex`**: High-performance spatial indexing for collision detection
- **`PainterFactory`**: Factory for creating appropriate shape painters
- **`UICanvas`**: Canvas abstraction for cross-platform rendering

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  datastore_renderer: ^1.0.0
```

## Usage

### Basic Datastore Rendering

```dart
import 'package:datastore_renderer/renderer.dart';
import 'package:dart_common/datastore.dart';
import 'package:dart_rendertheme/rendertheme.dart';

// Create renderer with datastore and theme
final renderer = DatastoreRenderer(
  datastore,           // Your map datastore
  renderTheme,         // Rendering theme
  true                 // Render labels onto tiles
);

// Create rendering job
final jobRequest = JobRequest(tile);

// Execute rendering
final result = await renderer.executeJob(jobRequest);

if (result.result == JOBRESULT.NORMAL) {
  final tilePicture = result.picture;
  // Use the rendered tile picture
}
```

### Online Tile Rendering

```dart
// ArcGIS Online renderer
final arcgisRenderer = ArcGISOnlineRenderer(
  baseUrl: 'https://services.arcgisonline.com/...',
  userAgent: 'MyApp/1.0'
);

// OpenStreetMap renderer
final osmRenderer = OSMOnlineRenderer(
  baseUrl: 'https://tile.openstreetmap.org/',
  userAgent: 'MyApp/1.0'
);

final result = await osmRenderer.executeJob(jobRequest);
```

### Custom Shape Painting

```dart
// Create area painter
final areaPainter = await ShapePaintArea.create(areaInstruction);

// Create canvas for rendering
final canvas = UiCanvas.forRecorder(256, 256);

// Render the shape
await areaPainter.paint(canvas, renderContext);

// Get the rendered picture
final picture = canvas.endRecording();
```

### Symbol Caching

```dart
// Load and cache symbols
final symbolMgr = SymbolCacheMgr();
final symbolImage = await symbolMgr.getOrCreateSymbol(
  'assets/poi_restaurant.png',
  32,  // width
  32   // height
);
```

### Spatial Indexing for Collision Detection

```dart
// Create spatial index
final spatialIndex = SpatialIndex(cellSize: 256.0);

// Add items to index
spatialIndex.add(renderInfo);

// Check for collisions
if (!spatialIndex.hasCollision(newItem)) {
  // Safe to render without overlap
  spatialIndex.add(newItem);
}
```

## Package Structure

```
lib/
├── renderer.dart                 # Main rendering engines
├── cache.dart                    # Caching system
├── shape_painter.dart            # Shape painting library
├── ui.dart                       # UI components
└── src/
    ├── cache/                    # Symbol and image caching
    ├── job/                      # Job request/result management
    ├── shape_painter/            # Shape painter implementations
    ├── ui/                       # Canvas and UI abstractions
    ├── util/                     # Utilities and helpers
    └── exception/                # Custom exceptions
```

## Performance Optimizations

### Rendering Performance
- **Object Pooling**: Reuse of RenderInfo objects to reduce garbage collection
- **Spatial Indexing**: O(log n) collision detection with grid-based partitioning
- **Painter Caching**: Reuse of shape painters for identical instructions
- **Asynchronous Processing**: Non-blocking rendering with task queues

### Memory Management
- **Symbol Caching**: LRU cache for bitmap symbols with automatic scaling
- **Picture Recording**: Efficient tile caching with Flutter's Picture API
- **Sparse Grid Storage**: Memory-efficient spatial index implementation

### Rendering Strategies
- **Label Separation**: Optional label extraction for rotation support
- **Multi-tile Rendering**: Batch processing for larger areas
- **Error Handling**: Graceful degradation with error visualization

## Advanced Features

### Multi-Source Data Integration
```dart
// Combine multiple data sources
final hybridRenderer = DatastoreRenderer(
  CombinedDatastore([localDatastore, onlineDatastore]),
  renderTheme,
  false  // Separate label rendering for rotation
);
```

### Custom Painter Creation
```dart
// Implement custom shape painter
class CustomShapePainter extends UiShapePainter<CustomInstruction> {
  @override
  Future<void> paint(UiCanvas canvas, UIRenderContext renderContext) async {
    // Custom rendering logic
  }
}

// Register with factory
final factory = PainterFactory();
// Factory will automatically detect and create appropriate painters
```

### Performance Monitoring
```dart
// Track rendering statistics
final renderer = DatastoreRenderer(datastore, theme, true);
print('Painters created: ${factory.created}');

// Canvas performance metrics
final canvas = UiCanvas.forRecorder(256, 256);
// Render operations...
print('Actions: ${canvas.actions}, Bitmaps: ${canvas.bitmapCount}');
```

## Dependencies

- **`dart_common`**: Core utilities and data models
- **`dart_rendertheme`**: Theme processing and rendering instructions
- **`flutter`**: Flutter framework for UI rendering
- **`flutter_svg`**: SVG image support
- **`logging`**: Logging infrastructure
- **`task_queue`**: Asynchronous task management
- **`ecache`**: LRU caching implementation

## Testing

The package includes comprehensive tests covering:
- Spatial indexing performance and correctness
- Shape painter creation and rendering
- Symbol caching and loading
- Job processing and error handling
- Canvas operations and transformations

Run tests with:
```bash
flutter test
```

## Contributing

1. Follow the existing code style and documentation standards
2. Add comprehensive tests for new features
3. Update documentation for API changes
4. Ensure performance optimizations are maintained
5. Test with various data sources and rendering scenarios

## Performance Benchmarks

- **Spatial Index**: O(log n) collision detection with 1000+ items
- **Symbol Cache**: Sub-millisecond retrieval for cached symbols
- **Tile Rendering**: <100ms for complex tiles with full styling
- **Memory Usage**: Optimized object pooling reduces GC pressure

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

## Related Packages

- **`dart_common`**: Core utilities and data structures
- **`dart_rendertheme`**: Theme processing and styling rules
- **`dart_mapfile`**: Map file reading and processing
- **`mapsforge_flutter`**: Complete Flutter mapping solution
