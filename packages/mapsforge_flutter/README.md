# mapsforge_flutter

A comprehensive Flutter widget library for interactive map visualization with advanced marker and overlay support. 
This package provides the main UI components for the Mapsforge Flutter ecosystem, enabling rich mapping experiences with customizable overlays, markers, and gesture handling.

# Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

# Overview

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
- Hillshading
- Drag-and-drop support
- Online and Offline Maps
- Map rotation
- Convert PBF files to mapsforge files
- Convert PBF files to osm files

# Core Components

## Map Widget
- **`MapsforgeView`**: Complete map widget with all standard features
- **`TileView`**: Core tile rendering widget
- **`LabelView`**: Label rendering with rotation support
- **`MapModel`**: Central state management for map data

## Gesture System
- **`MoveGestureDetector`**: Pan and drag gestures
- **`ScaleGestureDetector`**: Pinch-to-zoom gestures
- **`RotationGestureDetector`**: Two-finger rotation
- **`TapGestureDetector`**: Single and long tap handling
- **`DoubleTapGestureDetector`**: Double-tap zoom

## Overlay System
- **`ZoomOverlay`**: Zoom in/out buttons
- **`DistanceOverlay`**: Scale ruler display
- **`IndoorlevelOverlay`**: Indoor level controls
- **`ContextMenuOverlay`**: Contextual menu system

## Marker System
- **`PoiMarker`**: Point of interest markers with icons
- **`CircleMarker`**: Circular markers with customizable styling
- **`AreaMarker`**: Polygon area markers
- **`RectMarker`**: Rectangular markers
- **`PolylineMarker`**: Line and path markers
- **`CaptionMarker`**: Text label markers

# Installation

Add these packages to your `pubspec.yaml`:

```yaml
dependencies:
  mapsforge_flutter: ^4.0.0
  mapsforge_flutter_core: ^4.0.0
  mapsforge_flutter_mapfile: ^4.0.0
  mapsforge_flutter_renderer: ^4.0.0
  mapsforge_flutter_rendertheme: ^4.0.0
```

Note: See [doc/install](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/install.md) for working with a local copy of mapsforge_flutter. 


# Quick Start

## Basic Map Setup

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

# Markers

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

See also [doc/marker](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/marker.md)

# Overlays

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

See also [doc/overlay](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/overlay.md)

# Context Menus

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

# Gesture Customization

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

# Dependencies

- **`mapsforge_flutter`**: Flutter UI framework
- **`mapsforge_flutter_core`**: Core utilities and data models
- **`mapsforge_flutter_renderer`**: Rendering engine integration (online and offline)
- **`mapsforge_flutter_rendertheme`**: Theme and styling support
- **`mapsforge_flutter_mapfile`**: Map file reading and processing


# Contributing

1. Follow the existing code style and patterns
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure performance optimizations are maintained
5. Test with various map data sources and scenarios

# Examples

Check the `apps/simple_example` directory for a basic map setup.

Check the `apps/online_renderer_example` directory for a basic setup for pure online rendering.

Check the `apps/complete_example` directory for comprehensive usage examples including:
- Basic map setup with markers
- Custom marker implementations
- Advanced gesture handling
- Indoor mapping integration

# License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

# Related Packages

- **`mapsforge_flutter_core`**: Core utilities and data structures
- **`mapsforge_flutter_renderer`**: High-performance tile rendering for offline mapfiles as well as online renderers
- **`mapsforge_flutter_rendertheme`**: Theme processing and styling for offline mapfiles
- **`mapsforge_flutter_mapfile`**: Map file reading and processing
- **`mapsforge_flutter`**: Complete Flutter mapping solution with markers, overlays, and gesture handling

# Documentation

Decision why/how we use melos: [doc/melos](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/melos.md)

Setting up a new project which contains mapsforge_flutter: [doc/install](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/install.md)

Upgrading to a newer version: [doc/changes](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/changes.md)

Known issue: [doc/known_issues](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/known_issues.md)

Working with markers: [doc/marker](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/marker.md)

Performance considerations during development: [doc/performance](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/performance.md)

Enhanced usage of the library:  [doc/enhanced_usage](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/enhanced_usage.md)
