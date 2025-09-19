# complete_example

# Mapsforge Flutter Complete Example

A comprehensive Flutter application showcasing the mapsforge_flutter library with all performance optimizations and a complete configuration system.

## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

See [mapsforge_flutter](https://pub.dev/packages/mapsforge_flutter) for more details.

----

## Features

### 🎯 **Renderer Selection**
- **Offline Renderer**: Uses local map files with customizable render themes
- **Online Renderers**: OpenStreetMap, Mapbox, Google Maps support
- **Conditional UI**: Render theme selection only available for offline rendering

### 🗺️ **Location Management**
- **Predefined Locations**: Monaco, Berlin, Paris, London, Tokyo, New York
- **Map File Association**: Each location corresponds to a specific .map file
- **Geographic Details**: Center coordinates, default zoom levels, country information

### 🎨 **Render Themes** (Offline Only)
- **Default Theme**: Standard mapsforge rendering
- **Elevation Hillshade**: Terrain visualization with elevation data
- **Osmarender**: OpenStreetMap-style rendering
- **OpenAndroMaps**: Specialized theme for outdoor activities

### ⚡ **Performance Optimizations**
- **Spatial Indexing**: O(log n) collision detection for tiles
- **Douglas-Peucker Algorithm**: Optimized line simplification
- **Isolate Processing**: CPU-intensive calculations in separate isolates
- **Enhanced Task Queue**: Priority-based task scheduling
- **Adaptive Memory Management**: Dynamic cache sizing based on memory pressure
- **Real-time Monitoring**: Performance profiling and metrics

## Usage

### 1. **Initial Setup**
```bash
cd apps/complete_example
flutter pub get
flutter run
```

### 2. **Configuration Flow**
1. Launch app → Main navigation screen
2. Tap "Configure Map Settings"
3. Select renderer type (offline/online)
4. Choose render theme (if offline selected)
5. Pick location from dropdown
6. Review configuration summary
7. Tap "Start Map View"

### 3. **Map View Features**
- **Performance Overlay**: Toggle with analytics icon
- **Live Metrics**: Memory pressure, cache capacity, active tasks
- **Performance Tests**: Run with floating action button
- **Configuration Info**: Current settings displayed at bottom

## Development

### Adding New Locations
```dart
// In MapLocations.availableLocations
MapLocation(
  name: 'Your City',
  description: 'Description of the area',
  mapFileName: 'yourcity.map',
  centerLatitude: 40.7128,
  centerLongitude: -74.0060,
  defaultZoomLevel: 12,
  country: 'Your Country',
)
```

### Adding New Render Themes
```dart
// In RenderTheme enum
newTheme('Display Name', 'theme_file.xml')
```

### Custom Renderers
```dart
// In RendererType enum
customRenderer('Custom Renderer Name')
```

## Testing

### Performance Testing
The app includes built-in performance tests accessible via the floating action button in map view:
- Line simplification benchmarks
- Concurrent task processing
- Memory management validation
- Profiler statistics

### Manual Testing
1. Test all renderer types
2. Verify theme selection for offline only
3. Check location switching
4. Monitor performance metrics
5. Validate configuration persistence

## License

This example app demonstrates the mapsforge_flutter library capabilities and is provided for educational and development purposes.

