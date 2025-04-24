# mapsforge_flutter

Truly Offline Maps for Flutter. 

mapsforge_flutter brings pure offline mapping capabilities to Flutter by porting the well-established [mapsforge library](https://github.com/mapsforge/mapsforge) from Java/Android.

With this library, you can load and render *mapfiles* directly from a user’s device—no internet connection required. 
Perfect for offline navigation, custom mapping applications, and seamless user experiences!

## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

## Features and Examples

Start with the [simplified_example/README.md](simplified_example/README.md) or explore a wide range of examples in [example/README.md](example/README.md), covering:

- Day and Night Themes
- World Map Support
- Indoor Mapping
- Hillshading
- Context Menus
- Interactive Markers & Drag-and-Drop
- Online & Offline Maps
- Map Rotation
- Bonus: Convert PBF files to mapsforge files
- Bonus: Convert PBF files to osm files

## Why mapsforge_flutter?

*Fully Offline*: No internet? No problem! Load and render maps without network access.

*Support for online maps*: If you ADDITIONALLY need online maps you can do so easily with the same codebase and api.

*High Customizability*: Supports custom rendering themes, allowing you to tailor the map’s look and feel.

*Lightweight & Efficient*: Designed for mobile, mapsforge uses optimized mapfiles that provide rich geographical data in a compact format.

*Advanced Features*: Indoor navigation, hillshading, map rotation and more!

## Getting Started

### Prerequisites

Add the library to your ``pubspec.yaml``:

```yaml
  mapsforge_flutter: ^3.0.1
```

For development you can also include the github repository directly.

Make sure to list all required assets in your ``pubspec.yaml`` (see pubspec file from example project)

```yaml
    flutter:

      assets:
        - packages/mapsforge_flutter/assets/patterns/coniferous.svg
        - packages/mapsforge_flutter/assets/patterns/coniferous_and_deciduous.svg
        - packages/mapsforge_flutter/assets/patterns/deciduous.svg
      # and more
```

### Initializing mapsforge

1. Load a mapfile with openstreetmap &reg; data

> Mapfiles are files specifically designed for mobile use and provide the information about an area in condensed form. Please visit the original project for more information about how to download/generate them.

    Datastore datastore = IsolateMapfile(filename);

or

    Datastore datastore = await MapFile.from(filename, null, null);

Tip: If reading from memory, use ``MapFile.using(content, null, null)``

2. Create a symbol cache for assets (e.g. parking signs, bus stop icons)

> Assets are mostly small images to display in the map

    SymbolCache symbolCache = FileSymbolCache();

3. Define display settings

> Create the displayModel which defines and holds the view/display settings like maximum zoomLevel.

    DisplayModel displayModel = DisplayModel();

Tip: For crisper maps consider to set the deviceScaleFactor to a higher value, e.g. 2

4. Set up a render theme

> Render themes define how the map looks—think of them as CSS for mapsforge.

    RenderTheme renderTheme = await
    RenderThemeBuilder.create(displayModel, "assets/render_themes/defaultrender.xml");

5. Create the Renderer.

> The renderer converts the map data into visual tiles. 

    JobRenderer jobRenderer = MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

*Alternative:* Use an online renderer instead (no mapfiles required)

    JobRenderer jobRenderer = MapOnlineRenderer();

6. Optionally set up a tile cache

> cache rendered tiles for better performance and persistence

    TileBitmapCache bitmapCache = await FileTileBitmapCache.create(jobRenderer.getRenderKey());

or

    TileBitmapCache bitmapCache = await MemoryTileBitmapCache.create();

7. Integrate everything into MapModel & ViewModel

    MapModel mapModel = MapModel(
        displayModel: displayModel,
        renderer: jobRenderer,
        symbolCache: symbolCache,
        tileBitmapCache: bitmapCache,
    );
    
    ViewModel viewModel = ViewModel(displayModel: displayModel);


8. Add the map widget to your Flutter app

    Scaffold(
        body: 
            MapviewWidget(
                displayModel: displayModel,
                createMapModel: () async => mapModel,
                createViewModel: () async => viewModel,
            ),
    );

*Done!* You now have a fully functional offline map in your Flutter app.

---

## Dynamic Map Interaction

Move the map programmatically

    viewModel.setMapViewPosition(48.0901926 , 16.308939);

Additional methods exists for zooming and rotation.

---

## Credits

A huge shout-out to the original mapsforge developer for building such an incredible project! 
Also, thanks to Chemnitz University of Technology for implementing indoor map support.

## License

mapsforge_flutter is released under the LGPL-v3 license, just like the original mapsforge project.

## Contributing

We welcome contributions! If you find a bug or have an enhancement, feel free to submit a Pull Request or create an issue on GitHub.

## Recent changes

### IsolateMapfile Support

The system now supports mapfiles running in isolates. Instead of using ``Mapfile.from()`` just use ``IsolateMapfile()``

### Marker Context Update

Use ``MarkerContext`` instead of ``MarkerCallback`` for markers.

### leftUpper()

Avoid using ``mapViewPosition.getLeftUpper()``. Use ``mapViewPosition.getCenter()`` instead.

### Changes for markers

In markers use ``markerContext.mapCenter``.

This is because we do not redraw the map for every position-update but rather only if the position
gets out of the boundary of the map. 
``mapViewPosition.getCenter()`` returns the CURRENT center (=position)
whereas ``markerContext.mapCenter`` returns the center of the map which may be different if the map moved since the 
last redraw.

### Improved Marker Captions

Old method: 

    xxxMarker(
        markerCaption: MarkerCaption(
            text: "abc",
        ...
        ),
    )

New method:

    xxxxMarker(
        ...
    )..addCaption(
        caption: "abc",
        ...
    );

### Problems with impeller

Impeller is the new rendering engine for flutter. 
It seems there are still some problems with it. In case you experience some flaws try disabling impeller. 

To disable impeller add this parameter as "additional run args": 

``--no-enable-impeller``

or 

in ``AndroidManifest.xml``:

    <meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />

*Note:* Give impeller a chance and enable it from time to time to see if it already working for you.

## Documentation

See [doc/usage.md](doc/usage.md)

See [doc/structure.md](doc/structure.md)

See [doc/combine_osm_files.md](doc/combine_osm_files.md)

See [doc/build_indoor_map_files.md](doc/build_indoor_map_files.md)

See [doc/render_indoor_elements.md](doc/render_indoor_elements.md)

See [doc/overlay.md](doc/overlay.md)

## Important

If your app requires an internet connection, consider using a simpler online mapping library instead. mapsforge_flutter is optimized for offline maps.

Start building your offline mapping experience today with mapsforge_flutter!