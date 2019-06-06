# mapsforge_flutter

A port of mapsforge for pure flutter. The library is in a very, very early stage. 

Please take a look at the original:

https://github.com/mapsforge/mapsforge

Same license as the original mapsforge project. LPGL-v3

## Limitations

Currently flutter has no support for dashed lines

## TODO

A lot of things. 

graphics:
 rotate symbols
 rotate path text
 animate movement, animate zoom
 
Input:
  completely missing
  
Layers:
  Support multiple layers
  
Speed:
  implement symbol cache
  support for more than one concurrent job in the jobqueue


## Getting Started

include the library in your pubspec.yaml:

  mapsforge_flutter:
    path: ../mapsforge_flutter

include a list of all used assets in your pubspec.yaml (see example pubspec file)

    flutter:
    
      assets:
       - packages/mapsforge_flutter/assets/patterns/coniferous.svg
       - packages/mapsforge_flutter/assets/patterns/coniferous_and_deciduous.svg
       - packages/mapsforge_flutter/assets/patterns/deciduous.svg
    ...

Load the mapfile which holds the openstreetmap (r) data:

    String _localPath = await FileHelper.findLocalPath();

    File file = File(_localPath + "/" + Constants.mapfile);
    print("opening mapfile");
    RandomAccessFile raf = await file.open();
    MapFile mapFile = MapFile(raf, null, null);
    await mapFile.init();
    //await mapFile.debug();

Create the displayModel which defines the most important settings for mapsforge

    final DisplayModel displayModel = DisplayModel();

Create the graphicFactory wich implements the drawing algorithms for flutter

    GraphicFactory graphicFactory = FlutterGraphicFactory();

Create the rendering builder which specifies how to render the informations from the mapfile

    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);
    String content = await rootBundle.loadString("assets/defaultrender.xml");
    print("Rendering instructions has ${content.length} bytes");
    await renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

Create the labelstore which is a cache for the labels/captions

    TileBasedLabelStore labelStore = TileBasedLabelStore(100);
    
Create the renderer which is the rendering engine for the mapfiles

    MapDataStoreRenderer dataStoreRenderer = MapDataStoreRenderer(mapFile, renderTheme, graphicFactory, true, labelStore);

Another cache (these are by far not the only ones)

    TileCache tileCache = MemoryTileCache(50);

Glue everything together

    MapModel mapModel = MapModel(
      displayModel: displayModel,
      graphicsFactory: graphicFactory,
      renderer: dataStoreRenderer,
      tileCache: tileCache,
    );

In your build function include the mapsview:

    FlutterMapView( mapModel: mapModel,  ),

In order to change the position in the map call the mapModel with the new position

    mapModel.setMapViewPosition(48.0901926, 16.308939);
    


Help is appreciated...
