# mapsforge_view

A comprehensive Flutter widget library for interactive map visualization with advanced marker and overlay support. 
This package provides the main UI components for the Mapsforge Flutter ecosystem, enabling rich mapping experiences with customizable overlays, markers, and gesture handling.

# Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

## Overview

With this library, you can load and render *mapfiles* directly from a user’s device. **No internet connection required!**
Perfect for offline navigation, custom mapping applications, and seamless user experiences!

The `mapsforge_view` package is the primary UI layer for Mapsforge Flutter applications. 
It provides a complete set of widgets, overlays, and markers that work seamlessly with the underlying rendering engine to create interactive, feature-rich map applications.

mapsforge_flutter brings pure offline mapping capabilities to Flutter by porting the well-established [mapsforge library](https://github.com/mapsforge/mapsforge) from Java/Android.

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
  mapsforge_flutter: ^4.0.0
  mapsforge_flutter_core: ^4.0.0
  mapsforge_flutter_mapfile: ^4.0.0
  mapsforge_flutter_renderer: ^4.0.0
  mapsforge_flutter_rendertheme: ^4.0.0
```

Note: See [doc/install](doc/install.md) for working with a local copy of mapsforge_flutter. 


## Quick Start

### Basic Map Setup

Find the device to pixel ratio end set the global property accordingly. 
This will shrink the tiles, requires to produce more tiles but makes the map crispier.

```dart
double ratio = MediaQuery.devicePixelRatioOf(context);
MapsforgeSettingsMgr().setDeviceScaleFactor(ratio);
```

Read the map from the assets folder. Since monaco is small, we can keep it in memory

```dart
ByteData mapContent = await rootBundle.load("assets/monaco.map");
Datastore datastore = await Mapfile.createFromContent(content: mapContent.buffer.asUint8List());
```

Alternatively read the map from the file system.

```dart
datastore = await Mapfile.createFromFile(filename: filename);
```

Now create the MapModel. 
Our map does not support zoomlevel beyond 21 so restrict the zoomlevel range. 
MapModel must be disposed after use.

```dart
_mapModel = await MapModelHelper.createOfflineMapModel(datastore: datastore, zoomlevelRange: const ZoomlevelRange(0, 21));
```

For demo purposes set a position and zoomlevel. 
Note that this information would come from e.g. a gps provider in the real world.

```dart
MapPosition mapPosition = MapPosition(43.7399, 7.4262, 18);
_mapModel!.setPosition(mapPosition);
```

Use the MapModel to view the map

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FutureBuilder(
          // retrieve the MapModel we just created
          future: _createModelFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.error != null) {
              // an error occured, show it on screen
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            if (snapshot.data != null) {
              // cool we have already the MapModel so we can start the view
              MapModel mapsforgeModel = snapshot.data;
              return MapsforgeView(mapModel: mapsforgeModel);
            }
            // mapModel is still not availabe or no position defined
            return const CircularProgressIndicator();
          },
      ),
    );
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

See also [doc/overlay](doc/overlay.md)

### Context Menus

Context menu overlays handle interactions with customizable menus.

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

Performance considerations during development: [doc/performance](doc/performance.md)

Enhanced usage of the library:  [doc/enhanced_usage](doc/enhanced_usage.md)
