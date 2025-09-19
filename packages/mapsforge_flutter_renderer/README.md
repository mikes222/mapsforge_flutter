# mapsforge_flutter_renderer

A high-performance tile rendering engine for the Mapsforge Flutter ecosystem. This package provides comprehensive rendering capabilities for converting map data from various sources into visual tile representations with advanced caching, spatial indexing, and performance optimizations.

## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

See [mapsforge_flutter](https://pub.dev/packages/mapsforge_flutter) for more details.

----

## Overview

The `mapsforge_flutter_renderer` package is the core rendering engine that transforms map data into beautiful, interactive tile images. It supports multiple data sources including local datastores, online tile services, and provides sophisticated shape painting capabilities for all types of map elements.

## Key Features

- **Multi-Source Rendering**: Support for local datastores, ArcGIS Online, and OpenStreetMap services
- **High-Performance Rendering**: Optimized tile generation with object pooling and caching
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

## Usage

### Basic Datastore Rendering

```dart
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_core/datastore.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

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

## Performance Optimizations

### Rendering Performance
- **Object Pooling**: Reuse of RenderInfo objects to reduce garbage collection
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

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

