# Enhanced Usage Guide

This guide covers advanced asset management and symbol loading configurations for Mapsforge Flutter applications.

## Table of Contents
- [Asset Management Overview](#asset-management-overview)
- [Default Asset Configuration](#default-asset-configuration)
- [Custom Asset Configuration](#custom-asset-configuration)
- [Image Loaders](#image-loaders)
- [Practical Examples](#practical-examples)
- [Style Menus](#style-menus)
- [Best Practices](#best-practices)

## Asset Management Overview

Mapsforge Flutter uses a flexible asset loading system through the `SymbolCacheMgr` that supports multiple image sources:
- **Bundle Assets**: Images packaged with your Flutter app
- **File System Assets**: Images loaded from external directories
- **Multiple Loaders**: Different prefixes for different asset sources

## Default Asset Configuration

### Using Default Rendertheme Assets

By default, Mapsforge loads assets from the `mapsforge_flutter_rendertheme` package. Since Flutter doesn't support wildcards in `pubspec.yaml` for external package assets, you must explicitly reference each asset:

```yaml
# pubspec.yaml
flutter:
  assets:
    # Required rendertheme pattern assets
    - packages/mapsforge_flutter_rendertheme/assets/patterns/dark_farmland.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/dark_military.png
    - packages/mapsforge_flutter_rendertheme/assets/patterns/coniferous.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/coniferous_and_deciduous.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/deciduous.svg
    # ... add all required assets
```

> **💡 Tip**: Check the `complete_example` app for the complete list of required assets.

## Custom Asset Configuration

### When to Use Custom Assets

Configure custom asset loading when you need to:
- Use your own custom marker symbols
- Load custom renderthemes with custom symbols
- Access images from external directories
- Organize assets with different naming schemes

### SymbolCacheMgr Configuration

The `SymbolCacheMgr` manages asset loading through configurable loaders identified by URL prefixes.

## Image Loaders

### 1. ImageBundleLoader

Loads images from Flutter's asset bundle (packaged with your app).

**Configuration:**
```dart
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';

// Configure bundle loader for assets with "assets/" prefix
SymbolCacheMgr().addLoader(
  "assets/", 
  ImageBundleLoader(
    bundle: rootBundle, 
    pathPrefix: "assets/"
  )
);
```

**Required pubspec.yaml setup:**
```yaml
flutter:
  assets:
    - assets/aircraft/plane1.png
    - assets/aircraft/plane2.png
    - assets/map/s_pt_rail.svg
    # ... other assets
```

### 2. ImageFileLoader

Loads images from the file system (external to your app bundle).

**Configuration:**
```dart
// Configure file loader for assets with "file:" prefix
SymbolCacheMgr().addLoader(
  "file:", 
  ImageFileLoader(pathPrefix: "../symbolfiles/")
);
```

> **⚠️ Important**: Ensure images exist on the file system before referencing them. File assets are NOT included in `pubspec.yaml`.

## Practical Examples

### Example 1: Mixed Asset Sources

```dart
void configureAssetLoaders() {
  final symbolMgr = SymbolCacheMgr();
  
  // Load bundled assets (packaged with app)
  symbolMgr.addLoader(
    "assets/", 
    ImageBundleLoader(bundle: rootBundle, pathPrefix: "assets/")
  );
  
  // Load external files (from file system)
  symbolMgr.addLoader(
    "file:", 
    ImageFileLoader(pathPrefix: "/data/map_symbols/")
  );
  
  // Load custom icons with different prefix
  symbolMgr.addLoader(
    "icons/", 
    ImageBundleLoader(bundle: rootBundle, pathPrefix: "icons/")
  );
}
```

### Example 2: Asset Reference in Rendertheme

**Rendertheme XML:**
```xml
<symbol src="assets/map/s_pt_rail.svg" />
<symbol src="file:poi/hotel.svg" />
<symbol src="icons/custom_marker.png" />
```

**Corresponding Loader Setup:**
```dart
void setupLoaders() {
  final symbolMgr = SymbolCacheMgr();
  
  // Handles "assets/map/s_pt_rail.svg"
  symbolMgr.addLoader("assets/", ImageBundleLoader(
    bundle: rootBundle, 
    pathPrefix: "assets/"
  ));
  
  // Handles "file:poi/hotel.svg" → loads from "/data/symbols/poi/hotel.svg"
  symbolMgr.addLoader("file:", ImageFileLoader(
    pathPrefix: "/data/symbols/"
  ));
  
  // Handles "icons/custom_marker.png"
  symbolMgr.addLoader("icons/", ImageBundleLoader(
    bundle: rootBundle, 
    pathPrefix: "icons/"
  ));
}
```

### Example 3: Dynamic Asset Loading

```dart
class CustomMapView extends StatefulWidget {
  @override
  _CustomMapViewState createState() => _CustomMapViewState();
}

class _CustomMapViewState extends State<CustomMapView> {
  @override
  void initState() {
    super.initState();
    _configureAssets();
  }
  
  void _configureAssets() {
    final symbolMgr = SymbolCacheMgr();
    
    // Configure multiple asset sources
    symbolMgr.addLoader("bundle:", ImageBundleLoader(
      bundle: rootBundle, 
      pathPrefix: "map_assets/"
    ));
    
    symbolMgr.addLoader("external:", ImageFileLoader(
      pathPrefix: await _getExternalAssetsPath()
    ));
  }
  
  Future<String> _getExternalAssetsPath() async {
    // Get platform-specific external storage path
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/map_symbols/";
  }
}
```

## Style Menus

Mapsforge xml files support style menus. These are definitions of layers what may be rendered on the screen. 

See https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md#stylemenus for more information.

A stylemenu may be configured in the rendertheme xml file. 
It will be loaded automatically and the layer defined as standard layer will be shown per default. 

In order to change the layer used to render execute the following code:

```dart
Set<String> categories = _rendertheme!.styleMenu!.categoriesForLayer(layer);
_rendertheme!.setCategories(categories);
mapModel.renderChanged(RenderChangedEvent(BoundingBox.max()));
```

The first line retrieves all categories defined by the selected layer iteratively. 
``Rendertheme.setCategories()`` sets the categories and hence defines what to render. 
``MapModel.renderChanged()`` instructs the MapModel to clear the cache and rerender the view. 

For demo purposes there is a ``StyleMenuOverlay`` available which shows the possible layers on screen. 
See complete_example how to use it. 

## Best Practices

### 1. Loader Organization
```dart
// ✅ Good: Organize loaders by purpose
SymbolCacheMgr()
  ..addLoader("themes/", ImageBundleLoader(bundle: rootBundle, pathPrefix: "themes/"))
  ..addLoader("markers/", ImageBundleLoader(bundle: rootBundle, pathPrefix: "markers/"))
  ..addLoader("external:", ImageFileLoader(pathPrefix: "/external/symbols/"));

// ❌ Avoid: Generic prefixes that might conflict
SymbolCacheMgr().addLoader("", ImageBundleLoader(bundle: rootBundle, pathPrefix: ""));
```

## Troubleshooting

### Common Issues

1. **Asset Not Found**: Verify the asset is listed in `pubspec.yaml` (for bundle assets)
2. **File Not Found**: Check file system paths and permissions (for file assets)
3. **Prefix Conflicts**: Ensure loader prefixes don't overlap

