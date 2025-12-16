## Screenshots

![Austria offline](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-30-638.jpeg)
![Austria Satellite](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-30-50-948.jpeg)
![Indoor navigation](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-31-25-355.jpeg)
![Contour](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-34-11-891.jpeg)
![City](https://raw.githubusercontent.com/mikes222/mapsforge_flutter/master/doc/Screenshot_2021-11-30-13-36-05-612.jpeg)

See [mapsforge_flutter](https://pub.dev/packages/mapsforge_flutter) for more details.

----

Converts a pbf or osm file to a mapfile or osm file. It uses a rendertheme file to determine which points/ways should be kept and which can be omitted in the destination file. This makes sure that only necessary informations are included in the destination file.

Currently the base zoomlevel must be equal to the min zoomlevel.

**Usage**: mapfile_converter convert [arguments]

-h, --help                           Print this usage information.

-r, --rendertheme                    Render theme filename

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

**sourcefiles**:

"#"-separated list of sourcefiles. If you omit the ``boundary`` parameter the boundary of the first sourcefile is used. PBF and osm is currently supported.

**destinationfile**:

path to the destinationfile. mapfile, pbf or osm is currently supported.

**rendertheme**:

path to the render theme file. All information which are not used to draw something according to the render theme are ignored and will be omitted in the output file.

**zoomlevels**: 
 
"#"-separated list of zoomlevels. The last one is the max zoomlevel. This is used when creating mapfiles. 
For example for zoomlevels 0#5#8#12 the mapfile consists of 3 subfiles, one for zoomlevel 0-4 (base zoomlevel 0), one for zoomlevel 5-7 (base zoomlevel 5), one for zoomlevel 8-12 (base zoomlevel 8).  

**boundary**:

"#"-separated list of boundaries in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the first sourcefile is used.

**debug**:

if set, debug informations are added to the mapfile. This increases the size of the mapfile significantly. Do not use for production.

**maxdeviation**:

Maximum deviation allowed in pixels to simplify ways. If a way consists of many nodes we try to remove some nodes as long as the new way does not deviate more from the original way than specified by maxdeviation.

**maxgap**: 

Maximum gap in meters to be allowed to "close" open ways. 

**languagesPreference**:

List of languages which should be included in the output file. If omitted all available languages from the inputfile are included. This property can shrink the destination filesize significantly.

Note that the program creates temporary files in the current directory so it must have write access to the current directory.


## Compile and run

Download and install flutter, depending on your operating system

    apt-get install flutter

Download the git repository:

    git clone https://mikes222/mapsforge_flutter

Enter the directory:

    cd apps/mapsforge_converter

Compile:
    
    flutter create .
    dart build cli
    dart run

Now you can access the executable directly: 

``mapsforge_flutter/apps/mapsforge_converter/build/cli/windows_x64/bundle/bin/mapfile_converter.exe`` for windows

Or 

``mapsforge_flutter/apps/mapsforge_converter/build/cli/linux_x64/bundle/bin/mapfile_converter`` for linux

## Examples 

Getting help (from development environment):  

    dart run mapfile_converter convert --help

Run with assert() enabled:

    dart run --enable-asserts mapfile_converter convert --help

Getting help (direct execution of the resulting binary):

    mapsforge_flutter/apps/mapsforge_converter/build/linux/x64/debug/bundle/mapfile_converter convert --help

Converting monaco from [geofabrik](https://download.geofabrik.de/europe/monaco.html) to mapfile:

    dart run mapfile_converter convert --rendertheme=../complete_example/assets/render_theme/defaultrender.xml --sourcefiles=test/monaco-latest.pbf --destinationfile=monaco.map

Converting coastal information from pbf to osm:

    dart run mapfile_converter convert --rendertheme=../example/assets/render_themes/lightrender.xml --sourcefiles=map_lowres_coast.pbf --destinationfile=lowres_coast.osm --maxgap=20000

Converting coastal information from osm to mapfile:

    dart run mapfile_converter convert --rendertheme=../example/assets/render_themes/lightrender.xml --sourcefiles=lowres_coast.osm --destinationfile=lowres_coast.map --zoomlevels=0#5#9#12

Converting 2 pbf files to mapfile:
 
    dart run mapfile_converter convert --rendertheme=../example/assets/render_themes/lightrender.xml --sourcefiles=map_default_44_12.pbf#lowres_coast.pbf --destinationfile=test.map --maxgap=100 --boundary=44#12#46#14

## ProtoC support

ProtoC is the file format used by PBF files. We use this library to read pbf files. The following documentation is only necessary to update the sources. 

Download ``protoc-33.2-win64.zip`` from https://github.com/protocolbuffers/protobuf/releases/tag/v33.2

copy the files to ``c:\develop\protoc``

add ``C:\Users\micro\AppData\Local\Pub\Cache\bin`` to your path

restart android studio

````bash
flutter pub global activate protoc_plugin
cd apps/mapfile_converter
\develop\protoc\bin\protoc.exe --dart_out=. lib\pbfproto\fileformat.proto
\develop\protoc\bin\protoc.exe --dart_out=. lib\pbfproto\osmformat.proto
\develop\protoc\bin\protoc.exe --dart_out=. .\lib\waycacheproto\osm_waycache.proto
```
