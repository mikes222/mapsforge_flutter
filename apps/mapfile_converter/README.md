Converts a pbf or osm file to a mapfile or osm file. It uses a rendertheme file to determine which points/ways should be kept and which can be omitted in the destination file. This makes sure that only necessary informations are included in the destination file.

Currently the base zoomlevel must be equal to the min zoomlevel.

Usage: mapfile_converter convert [arguments]
-h, --help                           Print this usage information.
-r, --rendertheme                    Render theme filename
(defaults to "rendertheme.xml")
-s, --sourcefiles (mandatory)        Source filenames (PBF or osm files), separated by #
-d, --destinationfile (mandatory)    Destination filename (mapfile PBF or osm)
-z, --zoomlevels                     Comma-separated zoomlevels. The last one is the max zoomlevel, separator=#
(defaults to "0#5#9#13#16#20")
-b, --boundary                       Boundary in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the source file is used, separator=#
-f, --[no-]debug                     Writes debug information in the mapfile
-m, --maxdeviation                   Max deviation in pixels to simplify ways
(defaults to "5")
-g, --maxgap                         Max gap in meters to connect ways
(defaults to "200")


## Explanation

sourcefiles:

"#"-separated list of sourcefiles. If you omit the ``boundary`` parameter the boundary of the first sourcefile is used. PBF and osm is currently supported.

destinationfile:

path to the destinationfile. mapfile, pbf or osm is currently supported.

rendertheme:

path to the render theme file. All information which are not used to draw something according to the render theme is ignored and will be omitted in the output file

zoomlevels: 
 
"#"-separated list of zoomlevels. The last one is the max zoomlevel. This is used when creating mapfiles. 
For example for zoomlevels 0#5#8#12 the mapfile consists of 3 subfiles, one for zoomlevel 0-4 (base zoomlevel 0), one for zoomlevel 5-7 (base zoomlevel 5), one for zoomlevel 8-12 (base zoomlevel 8).  

boundary:

"#"-separated list of boundaries in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the first sourcefile is used.

debug:

if set, debug informations are added to the mapfile. This increases the size of the mapfile significantly. Do not use for production.

maxdeviation:

Maximum deviation allowed in pixels to simplify ways. If a way consists of many nodes we try to remove some nodes as long as the new way does not deviate more from the original way than specified by maxdeviation.

maxgap: 

Maximum gap in meters to be allowed to "close" open ways. 

languagesPreference:

List of languages which should be included in the output file. If omitted all available languages from the inputfile are included. This property can shrink the destination filesize significantly.

Note that the program creates temporary files in the current directory so it must have write access to the current directory.


## Compile and run

Download and install flutter, depending on your Operating system

    apt-get install flutter

Download the git repository:

    git clone https://mikes222/mapsforge_flutter

Enter the directory:

    cd mapsforge_flutter/mapsforge_converter

Compile:
    
    flutter create .
    flutter run

Now you can access the executable directly: mapsforge_flutter/mapsforge_converter/build/windows/x64/runner/Debug/mapfile_converter.exe for windows
Or mapsforge_flutter/mapsforge_converter/build/linux/x64/debug/bundle/mapfile_converter for linux

## Examples 

These examples are meant to be run from the mapsforge_converter directory for debugging purposes. When executing the binary directly you do not need to specify the ``--dart-entrypoint-args`` argument.

Getting help (from development environment):  

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --help

Getting help (direct execution of the resulting binary):

    mapsforge_flutter/mapsforge_converter/build/linux/x64/debug/bundle/mapfile_converter convert --help

Converting monaco from [geofabrik](https://download.geofabrik.de/europe/monaco.html) to mapfile:

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=../example/assets/render_themes/lightrender.xml --dart-entrypoint-args --sourcefiles=monaco-latest.osm.pbf --dart-entrypoint-args --destinationfile=monaco.map

Converting coastal information from pbf to osm:

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=../example/assets/render_themes/lightrender.xml --dart-entrypoint-args --sourcefiles=map_lowres_coast.pbf --dart-entrypoint-args --destinationfile=lowres_coast.osm --dart-entrypoint-args --maxgap=20000

Converting coastal information from osm to mapfile:

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=../example/assets/render_themes/lightrender.xml --dart-entrypoint-args --sourcefiles=lowres_coast.osm --dart-entrypoint-args --destinationfile=lowres_coast.map --dart-entrypoint-args --zoomlevels=0#5#9#12

Converting 2 pbf files to mapfile:
 
    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=../example/assets/render_themes/lightrender.xml --dart-entrypoint-args --sourcefiles=map_default_44_12.pbf#lowres_coast.pbf --dart-entrypoint-args --destinationfile=test.map --dart-entrypoint-args --maxgap=100 --dart-entrypoint-args --boundary=44#12#46#14

## ProtoC support

Download protoc-30.2-win64.zip from https://github.com/protocolbuffers/protobuf/releases/tag/v30.2

copy the files to c:\develop\proto

add C:\Users\micro\AppData\Local\Pub\Cache\bin to your path

restart android studio

    flutter pub global activate protoc_plugin

    cd mapsforge_converter

    \develop\protoc\bin\protoc.exe --dart_out=. lib\pbfreader\proto\fileformat.proto
