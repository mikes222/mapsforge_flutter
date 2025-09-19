# Mapsforge Flutter Simple Example

A beginner-friendly Flutter application demonstrating how to use the Mapsforge library for offline map rendering. This example shows a basic implementation of displaying an interactive map using Mapsforge's vector map format.

## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

See [mapsforge_flutter](https://pub.dev/packages/mapsforge_flutter) for more details.

## Features Demonstrated

This simple example showcases:

- ✅ Loading a map file from assets (`monaco.map`)
- ✅ Applying a custom render theme (`defaultrender.xml`)
- ✅ Interactive map controls (zoom, pan)
- ✅ Setting initial map position and zoom level
- ✅ Asynchronous map model creation
- ✅ Error handling and loading states

## Prerequisites

Before running this example, ensure you have:

- **Flutter SDK** (3.9.0 or higher)
- **Dart SDK** (compatible with Flutter version)
- An IDE with Flutter support (VS Code, Android Studio, or IntelliJ)
- A device or emulator for testing

## Quick Start

### 1. Clone and Setup

```bash
# Navigate to the simple_example directory
cd apps/simple_example

# Get dependencies
flutter pub get
```

### 2. Run the Application

```bash
# Create the necessary runtime
flutter create .

# Run on connected device/emulator
flutter run

# Or run in debug mode
flutter run --debug
```

### 3. What You'll See

The app will display:
- A map of Monaco (included as sample data)
- Interactive controls for zooming and panning
- A green border around the map view
- Loading indicator while the map initializes

## Understanding the Code Structure

### Code Flow

1. **Initialization** - App starts and creates the map model asynchronously
2. **Asset Loading** - Loads map file and render theme from assets
3. **Renderer Setup** - Creates renderer with map data and styling
4. **Model Creation** - Instantiates MapModel with renderer and zoom limits
5. **Position Setting** - Sets initial map position (Monaco coordinates)
6. **Display** - MapsforgeView widget renders the interactive map

## Customization Guide

### Changing the Map Location

To display a different area, modify the `MapPosition` in `createModel()`:

```dart
// Example: New York City
MapPosition mapPosition = MapPosition(40.7128, -74.0060, 12);
```

### Using Your Own Map File

1. Obtain a `.map` file (from OpenStreetMap data using mapsforge-map-writer)
2. Place it in the `assets/` folder
3. Update `pubspec.yaml` to include your map file
4. Modify the asset loading code:

```dart
ByteData mapContent = await rootBundle.load("assets/your-map.map");
```

### Customizing Map Appearance

Edit `assets/defaultrender.xml` to change:
- Colors and styling of roads, buildings, water
- Font sizes and types
- Icon visibility and sizing
- Layer rendering order

## Common Issues and Solutions

### Position Not Set
- **Always set initial position** - maps won't display without coordinates
- **Use map file bounds** - get default position from `mapFile.boundingBox`

## Next Steps

After understanding this simple example, explore:

1. **Complete Example** (`../complete_example/`) - Advanced features like GPS, file downloads
2. **Custom Render Themes** - Create your own map styling
3. **Multiple Map Layers** - Overlay additional data

## License

This example is part of the Mapsforge Flutter project. See the main project LICENSE file for details.
