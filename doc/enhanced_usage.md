# Working with assets

The default configuration is to load assets from ``mapsforge_flutter_rendertheme`` project. 
Unfortunately flutter does not allow to use wildcards in pubspec.yaml when referencing assets in other packages. 
Therefore the developer needs to reference the assets in its own pubspec.yaml like so:

```yaml
flutter:
  assets:
    - packages/mapsforge_flutter_rendertheme/assets/patterns/dark_farmland.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/dark_military.png
    - packages/mapsforge_flutter_rendertheme/assets/patterns/coniferous.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/coniferous_and_deciduous.svg
    - packages/mapsforge_flutter_rendertheme/assets/patterns/deciduous.svg
...
```

See ``complete_example for the list of assets``. 

When using your own markers you might want to use assets from your own project. This might look like:

```yaml
flutter:
  assets:
    - assets/aircraft/plane1.png
    - assets/aircraft/plane2.png
...
```

In this case add a new Loader to the SymbolMgr before using it

```dart
SymbolCacheMgr().addLoader("assets/", ImageBundleLoader(bundle: rootBundle, pathPrefix: "assets/"));
```

All assets starting with the term ``assets/`` will be loaded from the bundle given to ``ImageBundleLoader``. The loader needs to add the prefix again in this case. 

Similarily you can use the ``ImageFileLoader`` to load images from the file system.

```dart
SymbolCacheMgr().addLoader("file:", ImageFileLoader(bundle: rootBundle, pathPrefix: "../symbolfiles/"));
```

In this example all files starting with "file:" will be loaded from the file system. The loader seeks for the files in the given directory.

Given you are in the directory ``/usr/lib/mapsforge/app`` and reference a file ``file:poi/hotel.svg``

The Loader expects the file at ``/usr/lib/mapsforge/symbolfiles/poi/hotel.svg``

Since the file is not part of the app it is NOT referenced in ``pubspec.yaml``.

