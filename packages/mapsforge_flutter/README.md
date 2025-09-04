# mapsforge_view

A comprehensive Flutter widget library for interactive map visualization with advanced marker and overlay support. This package provides the main UI components for the Mapsforge Flutter ecosystem, enabling rich mapping experiences with customizable overlays, markers, and gesture handling.

## Overview

The `mapsforge_view` package is the primary UI layer for Mapsforge Flutter applications. It provides a complete set of widgets, overlays, and markers that work seamlessly with the underlying rendering engine to create interactive, feature-rich map applications.

**Key Features:**
- Complete map widget with gesture support
- Rich marker system for POIs, areas, and custom elements
- Overlay system for UI controls and information display
- Context menu support with customizable actions
- Indoor mapping support with level controls
- Performance-optimized rendering with caching

## Core Components

### Map Widget
- **`MapsforgeView`**: Complete map widget with all standard features
- **`TileView`**: Core tile rendering widget
- **`LabelView`**: Label rendering with rotation support
- **`MapModel`**: Central state management for map data

### Gesture System
- **`MoveGestureDetector`**: Pan and drag gestures
- **`ScaleGestureDetector`**: Pinch-to-zoom gestures
- **`RotationGestureDetector`**: Two-finger rotation
- **`TapGestureDetector`**: Single and long tap handling
- **`DoubleTapGestureDetector`**: Double-tap zoom

### Overlay System
- **`ZoomOverlay`**: Zoom in/out buttons
- **`DistanceOverlay`**: Scale ruler display
- **`IndoorlevelOverlay`**: Indoor level controls
- **`ContextMenuOverlay`**: Contextual menu system

### Marker System
- **`PoiMarker`**: Point of interest markers with icons
- **`CircleMarker`**: Circular markers with customizable styling
- **`AreaMarker`**: Polygon area markers
- **`RectMarker`**: Rectangular markers
- **`PolylineMarker`**: Line and path markers
- **`CaptionMarker`**: Text label markers

## Installation

Add these packages to your `pubspec.yaml`:

```yaml
dependencies:
  mapsforge_flutter: ^1.0.0
  mapsforge_flutter_core: ^1.0.0
  mapsforge_flutter_mapfile: ^1.0.0
  mapsforge_flutter_renderer: ^1.0.0
  mapsforge_flutter_rendertheme: ^1.0.0
```

Note: See doc/install.md for working with a local copy of mapsforge_flutter. 

## Quick Start

### Basic Map Setup

```dart
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/overlay.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapModel mapModel;

  @override
  void initState() {
    super.initState();
    mapModel = MapModel(
      renderer: yourRenderer, // DatastoreRenderer or other
      position: MapPosition(
        latitude: 52.5200,
        longitude: 13.4050,
        zoomLevel: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapsforgeView(mapModel: mapModel),
    );
  }
}
```

## Markers

```dart
// Create a POI marker with custom icon
final poiMarker = PoiMarker<String>(
  latLong: LatLong(52.5200, 13.4050),
  src: "assets/icons/restaurant.png",
);

// Add to marker datastore
final markerDatastore = DefaultMarkerDatastore();
markerDatastore.addMarker(poiMarker);

// Add to your map stack
Stack(
  children: [
    MapsforgeView(mapModel: mapModel),
    MarkerDatastoreOverlay(markerDatastore: markerDatastore),
  ],
)
```

See also [doc/marker](doc/marker.md)

## Overlays

### Zoom Controls

Zoom overlays provide interactive zoom in/out buttons.

```dart
// Standard zoom overlay with positioned buttons
ZoomOverlay(
  mapModel: mapModel,
  top: 50,    // Position from top
  right: 20,  // Position from right
)

// Alternative: zoom-in only overlay
ZoomInOverlay(
  mapModel: mapModel,
  bottom: 100,
  right: 20,
)
```

### Distance Scale

Distance overlays show a scale ruler for measuring distances.

```dart
DistanceOverlay(mapModel: mapModel)
```

The distance overlay automatically:
- Updates scale based on current zoom level
- Shows appropriate units (meters, kilometers)
- Positions itself in the bottom-left corner
- Fades in/out during map interactions

### Indoor Level Controls

Indoor level overlays provide controls for navigating building floors.

```dart
IndoorlevelOverlay(mapModel: mapModel)
```

Features:
- Automatic detection of indoor data
- Floor level selection buttons
- Smooth transitions between levels
- Integration with indoor-enabled map data

### Context Menus

Context menu overlays handle long-press interactions with customizable menus.

```dart
// Custom context menu
final contextMenu = SimpleContextMenu(
  items: [
    ContextMenuItem(
      title: "Add Marker",
      icon: Icons.place,
      onTap: (position) {
        // Add marker at tapped position
        final marker = PoiMarker(
          latLong: position,
          src: "assets/icons/pin.png",
        );
        markerDatastore.addMarker(marker);
      },
    ),
    ContextMenuItem(
      title: "Get Info",
      icon: Icons.info,
      onTap: (position) {
        // Show location information
        showLocationInfo(position);
      },
    ),
  ],
);

// Add to overlay stack
ContextMenuOverlay(
  mapModel: mapModel,
  contextMenu: contextMenu,
)
```

## Advanced Usage

### Custom Marker Types

Create custom markers by extending the base `Marker` class:

```dart
class CustomMarker<T> extends Marker<T> {
  final String customProperty;
  
  CustomMarker({
    required this.customProperty,
    required LatLong latLong,
    super.zoomlevelRange,
    super.key,
  });

  @override
  Future<void> changeZoomlevel(int zoomlevel, PixelProjection projection) async {
    // Implement zoom-level specific rendering
  }

  @override
  void render(UiRenderContext renderContext) {
    // Implement custom rendering logic
  }

  @override
  bool isTapped(TapEvent tapEvent) {
    // Implement custom tap detection
    return false;
  }
}
```

### Marker Clustering

For performance with large marker sets, implement clustering:

```dart
class ClusteredMarkerDatastore extends MarkerDatastore {
  final double clusterRadius;
  
  ClusteredMarkerDatastore({this.clusterRadius = 50.0});
  
  @override
  List<Marker> getVisibleMarkers(BoundingBox boundary, int zoomLevel) {
    final markers = super.getVisibleMarkers(boundary, zoomLevel);
    
    if (zoomLevel < 12) {
      return clusterMarkers(markers);
    }
    
    return markers;
  }
  
  List<Marker> clusterMarkers(List<Marker> markers) {
    // Implement clustering algorithm
    // Return cluster markers instead of individual markers
  }
}
```

### Performance Optimization

```dart
// Use zoom level ranges to control marker visibility
final marker = PoiMarker(
  latLong: position,
  src: "icon.png",
  zoomlevelRange: ZoomlevelRange(10, 18), // Only visible at these zoom levels
);

// Implement efficient marker filtering
class FilteredMarkerDatastore extends DefaultMarkerDatastore {
  String? categoryFilter;
  
  @override
  List<Marker> getVisibleMarkers(BoundingBox boundary, int zoomLevel) {
    var markers = super.getVisibleMarkers(boundary, zoomLevel);
    
    if (categoryFilter != null) {
      markers = markers.where((marker) {
        return marker.key?.toString().contains(categoryFilter!) ?? false;
      }).toList();
    }
    
    return markers;
  }
}
```

### Gesture Customization

```dart
// Create custom map widget with selective gestures
class CustomMapView extends StatelessWidget {
  final MapModel mapModel;
  final bool enableRotation;
  final bool enableZoom;
  
  const CustomMapView({
    required this.mapModel,
    this.enableRotation = true,
    this.enableZoom = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MoveGestureDetector(mapModel: mapModel),
        if (enableRotation) RotationGestureDetector(mapModel: mapModel),
        if (enableZoom) ScaleGestureDetector(mapModel: mapModel),
        TapGestureDetector(mapModel: mapModel),
        TileView(mapModel: mapModel),
        // Add your custom overlays
      ],
    );
  }
}
```

## Package Structure

```
lib/
├── mapsforge.dart              # Main map components
├── marker.dart                 # Marker system exports
├── overlay.dart                # Overlay system exports
├── context_menu.dart           # Context menu components
├── gesture.dart                # Gesture handling exports
└── src/
    ├── map_model.dart          # Core map state management
    ├── map_position.dart       # Position and viewport handling
    ├── mapsforge_view.dart     # Main map widget
    ├── marker/                 # Marker implementations
    ├── overlay/                # Overlay implementations
    ├── gesture/                # Gesture detector implementations
    └── context_menu/           # Context menu system
```

## Dependencies

- **`mapsforge_flutter_core`**: Core utilities and data models
- **`mapsforge_flutter_renderer`**: Rendering engine integration
- **`mapsforge_flutter_rendertheme`**: Theme and styling support
- **`flutter`**: Flutter framework
- **`rxdart`**: Reactive programming support
- **`ecache`**: Caching infrastructure
- **`logging`**: Logging support

## Performance Considerations

### Marker Performance
- Use appropriate zoom level ranges to limit marker visibility
- Implement clustering for large marker sets (>1000 markers)
- Consider marker pooling for frequently updated markers
- Use efficient marker datastores for large datasets

### Overlay Performance
- Overlays are rendered on every frame during interactions
- Keep overlay rendering lightweight
- Use animation controllers for smooth transitions
- Implement proper disposal to prevent memory leaks

### Memory Management
- Dispose of markers and overlays when no longer needed
- Use weak references for large marker collections
- Implement efficient caching strategies
- Monitor memory usage with large datasets

## Testing

The package includes comprehensive tests covering:
- Marker creation and rendering
- Overlay functionality and positioning
- Gesture handling and interactions
- Performance with large datasets
- Memory management and disposal

Run tests with:
```bash
flutter test
```

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure performance optimizations are maintained
5. Test with various map data sources and scenarios

## Examples

Check the `apps/simple_example` directory for a basic map setup.

Check the `apps/complete_example` directory for comprehensive usage examples including:
- Basic map setup with markers
- Custom marker implementations
- Advanced gesture handling
- Indoor mapping integration

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

## Related Packages

- **`mapsforge_flutter_core`**: Core utilities and data structures
- **`mapsforge_flutter_renderer`**: High-performance tile rendering for offline mapfiles as well as online renderers
- **`mapsforge_flutter_rendertheme`**: Theme processing and styling for offline mapfiles
- **`mapsforge_flutter_mapfile`**: Map file reading and processing
- **`mapsforge_flutter`**: Complete Flutter mapping solution with markers, overlays, and gesture handling

## Documentation

Decision why/how we use melos: [doc/melos](doc/melos.md)

Setting up a new project which contains mapsforge_flutter: [doc/install](doc/install.md)

Upgrading to a newer version: [doc/changes](doc/changes.md)

Known issue: [doc/known_issues](doc/known_issues.md)

Working with markers: [doc/marker](doc/marker.md)