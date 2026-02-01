# mapsforge_flutter_rendertheme

A comprehensive Dart package for rendering map themes in the Mapsforge ecosystem. This package provides a complete implementation of XML-based theme parsing and rendering instruction generation for creating beautiful, customizable map visualizations.

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

The `mapsforge_flutter_rendertheme` package is the core theming engine for Mapsforge Flutter applications. It processes XML theme files and converts them into rendering instructions that define how map features should be visually represented. The package supports complex styling rules, zoom-level dependent rendering, and high-performance caching for optimal map rendering performance.

## Key Features

- **XML Theme Processing**: Parse and process Mapsforge XML theme files
- **Rendering Instructions**: Generate optimized rendering instructions for map features
- **Zoom Level Support**: Dynamic styling based on zoom levels with automatic scaling
- **Performance Optimization**: LRU caching for rule matching and rendering instructions
- **Comprehensive Styling**: Support for areas, lines, symbols, icons, and text labels
- **Indoor Mapping**: 3D mapping support with indoor level handling
- **Rule Matching**: Efficient matching of map features against styling rules

## Core Components

## Usage

### Basic Theme Loading

```dart
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

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

## License

This package is part of the Mapsforge Flutter ecosystem. See the main project license for details.

