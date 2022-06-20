# Simplified example

A sample Flutter project using MapsForge and a local map file.

## Getting started
- Download a MapsForge map from, for example one of the servers mentioned by [mapforge.org](https://download.mapsforge.org/),  to your client.
- In `main.dart`, on line 42, update the path to the downloaded map.
  ```
  MapFile mapFile = await MapFile.from('/path/to/your.map', null, null);
  ```

## Known issues
- Compilation for Windows will sometimes fail.  
  A workaround is to comment the `assets` section in `pubspec.yaml` and run again. App will start but will throw an error because assets cannot be read. Then uncomment the `assets` section and rebuild. It should work then.

