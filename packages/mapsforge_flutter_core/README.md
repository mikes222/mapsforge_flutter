# mapsforge_flutter_core

Core utilities and common components for the Mapsforge Flutter project.

## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)
![Hillshading](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_20260201_104534.png)

See [mapsforge_flutter](https://pub.dev/packages/mapsforge_flutter) for more details.

----

## Overview

The `mapsforge_flutter_core` package provides essential building blocks and utilities used throughout the Mapsforge Flutter ecosystem. It contains fundamental data structures, algorithms, and interfaces for map rendering, geographic calculations, and data management.

## Key Components

### 📊 Data Models
- **Geographic Coordinates**: `LatLong`, `BoundingBox` for spatial data representation
- **Tile System**: `Tile` class for hierarchical map tile management
- **Map Features**: `Way`, `PointOfInterest`, `Tag` for map data structures
- **Data Bundles**: `DatastoreBundle` for organizing map data collections

### 🗃️ Data Storage
- **Abstract Datastore**: Base interface for map data access
- **Memory Datastore**: In-memory implementation for testing and dynamic data
- **Buffer Management**: Efficient binary data reading and processing

### 🌍 Geographic Projections
- **Mercator Projection**: Web Mercator (EPSG:3857) coordinate transformations
- **Pixel Projection**: Screen coordinate conversions for rendering
- **Tile Calculations**: Geographic to tile coordinate mappings

### 🛠️ Utilities
- **Geographic Calculations**: Distance, intersection, and spatial operations
- **Line Simplification**: Douglas-Peucker algorithm for polyline optimization
- **Performance Tools**: Timing utilities for debugging and profiling
- **Settings Management**: Global configuration for rendering parameters

## Usage Examples

### Working with Geographic Coordinates

```dart
import 'package:mapsforge_flutter_core/model.dart';

// Create a coordinate
final coordinate = LatLong(52.5200, 13.4050); // Berlin

// Create a bounding box
final bbox = BoundingBox(52.0, 13.0, 53.0, 14.0);

// Check if coordinate is within bounds
if (bbox.containsLatLong(coordinate)) {
  print('Berlin is within the bounding box');
}
```

### Using Projections

```dart
import 'package:mapsforge_flutter_core/projection.dart';

// Create a projection for zoom level 10
final projection = MercatorProjection.fromZoomlevel(10);

// Convert coordinates to tile numbers
final tileX = projection.longitudeToTileX(13.4050);
final tileY = projection.latitudeToTileY(52.5200);

// Create a tile
final tile = Tile(tileX, tileY, 10);
```

### Memory Datastore for Testing

```dart
import 'package:mapsforge_flutter_core/datastore.dart';
import 'package:mapsforge_flutter_core/model.dart';

// Create an in-memory datastore
final datastore = MemoryDatastore();

// Add some test data
final poi = PointOfInterest(
  position: LatLong(52.5200, 13.4050),
  tags: [Tag('name', 'Berlin')],
);
datastore.addPoi(poi);

// Query data for a tile
final tile = Tile(550, 335, 10);
final data = await datastore.readMapDataSingle(tile);
```

### Geographic Utilities

```dart
import 'package:mapsforge_flutter_core/utils.dart';

// Calculate distance between two points
final berlin = LatLong(52.5200, 13.4050);
final munich = LatLong(48.1351, 11.5820);
final distance = LatLongUtils.euclideanDistance(berlin, munich);

// Simplify a polyline
final simplifier = DouglasPeuckerLatLong();
final simplified = simplifier.simplify(coordinates, tolerance: 0.001);
```

## License

This package is part of the Mapsforge Flutter project and follows the same licensing terms.
