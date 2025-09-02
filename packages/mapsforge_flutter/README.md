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

### Point of Interest (POI) Markers

POI markers display icons or symbols at specific geographic locations.

```dart
// Create a POI marker with custom icon
final poiMarker = PoiMarker<String>(
  key: "restaurant_1",
  latLong: LatLong(52.5200, 13.4050),
  src: "assets/icons/restaurant.png",
  width: 32,
  height: 32,
  positioning: MapPositioning.CENTER,
  rotateWithMap: false,
  rotation: 0, // degrees clockwise
  zoomlevelRange: ZoomlevelRange(12, 18),
);

// Add to marker datastore
final markerDatastore = DefaultMarkerDatastore();
markerDatastore.addMarker(poiMarker);

// Create overlay for rendering
final markerOverlay = MarkerDatastoreOverlay(
  markerDatastore: markerDatastore,
);

// Add to your map stack
Stack(
  children: [
    MapsforgeView(mapModel: mapModel),
    markerOverlay,
  ],
)
```

### Circle Markers

Circle markers create circular shapes with customizable fill and stroke.

```dart
final circleMarker = CircleMarker<String>(
  key: "location_1",
  latLong: LatLong(52.5200, 13.4050),
  radius: 50, // radius in pixels
  fillColor: 0x80FF0000, // Semi-transparent red
  strokeColor: 0xFF000000, // Black border
  strokeWidth: 2.0,
  position: MapPositioning.CENTER,
  zoomlevelRange: ZoomlevelRange(10, 16),
);
```

### Area Markers

Area markers render polygon shapes defined by coordinate paths.

```dart
final areaMarker = AreaMarker<String>(
  key: "park_area",
  path: [
    LatLong(52.5200, 13.4050),
    LatLong(52.5210, 13.4060),
    LatLong(52.5190, 13.4070),
    LatLong(52.5180, 13.4040),
  ],
  fillColor: 0x8000FF00, // Semi-transparent green
  strokeColor: 0xFF008000, // Dark green border
  strokeWidth: 2.0,
  zoomlevelRange: ZoomlevelRange(8, 15),
);
```

### Polyline Markers

Polyline markers draw lines and paths between coordinates.

```dart
final polylineMarker = PolylineMarker<String>(
  key: "route_1",
  path: [
    LatLong(52.5200, 13.4050),
    LatLong(52.5250, 13.4100),
    LatLong(52.5300, 13.4150),
  ],
  strokeColor: 0xFF0000FF, // Blue line
  strokeWidth: 4.0,
  strokeDasharray: [10.0, 5.0], // Dashed line pattern
  zoomlevelRange: ZoomlevelRange(10, 18),
);
```

### Caption Markers

Caption markers display text labels at specific locations.

```dart
final captionMarker = CaptionMarker<String>(
  key: "label_1",
  latLong: LatLong(52.5200, 13.4050),
  text: "Berlin",
  fontSize: 16.0,
  fontColor: 0xFF000000,
  strokeColor: 0xFFFFFFFF, // White outline
  strokeWidth: 1.0,
  positioning: MapPositioning.CENTER,
  zoomlevelRange: ZoomlevelRange(8, 16),
);
```

### Marker Management

```dart
// Create marker datastore
final markerDatastore = DefaultMarkerDatastore();

// Add multiple markers
markerDatastore.addMarker(poiMarker);
markerDatastore.addMarker(circleMarker);
markerDatastore.addMarker(areaMarker);

// Remove markers
markerDatastore.removeMarker(poiMarker);

// Clear all markers
markerDatastore.clearMarkers();

// Handle marker taps
markerDatastore.onTap = (marker, tapEvent) {
  print("Tapped marker: ${marker.key}");
  // Handle marker interaction
};
```

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
2. Add tests for new marker types and overlays
3. Update documentation for API changes
4. Ensure performance optimizations are maintained
5. Test with various map data sources and scenarios

## Examples

Check the `apps/complete_example` directory for comprehensive usage examples including:
- Basic map setup with markers and overlays
- Custom marker implementations
- Advanced gesture handling
- Performance optimization techniques
- Indoor mapping integration

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

## Related Packages

- **`mapsforge_flutter_core`**: Core utilities and data structures
- **`mapsforge_flutter_renderer`**: High-performance tile rendering
- **`mapsforge_flutter_rendertheme`**: Theme processing and styling
- **`dart_mapfile`**: Map file reading and processing
- **`mapsforge_flutter`**: Complete Flutter mapping solution
