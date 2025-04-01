Converts a pbf file to a mapfile or osm file. It uses a rendertheme file to determine which points/ways should be kept and which can be omitted in the destination file.

Currently the base zoomlevel must be equal to the min zoomlevel

flutter: Converts a pbf file to mapfile

Usage: mapfile_converter convert [arguments]
-h, --help                           Print this usage information.
-r, --rendertheme                    Render theme filename
(defaults to "rendertheme.xml")
-s, --sourcefile (mandatory)         Source filename (PBF file)
-d, --destinationfile (mandatory)    Destination filename (mapfile or osm)
-z, --zoomlevels                     Comma-separated zoomlevels. The last one is the max zoomlevel
(defaults to "0,5,9,13,16,20")
-b, --boundary                       Boundary in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the source file is used
-f, --[no-]debug                     Writes debug information in the mapfile
-m, --maxdeviation                   Max deviation in pixels to simplify ways
(defaults to "5")
-g, --maxgap                         Max gap in meters to connect ways
(defaults to "200")


Documentation is not yet done.

Just try

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=monaco-latest.osm.pbf --dart-entrypoint-args --destinationfile=monaco.map

or

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=map_default_46_16.pbf --dart-entrypoint-args --destinationfile=test.map

or

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=map_lowres_coast.pbf --dart-entrypoint-args --destinationfile=test.map --dart-entrypoint-args --zoomlevels=0_5_9_12 --dart-entrypoint-args --maxdeviation=20 --dart-entrypoint-args --maxgap=1000

or

    flutter run --dart-entrypoint-args convert --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=map_lowres_coast.pbf --dart-entrypoint-args --destinationfile=lowres_coast.osm --dart-entrypoint-args --zoomlevels=0_5_9_12 --dart-entrypoint-args --maxgap=10000

type 

    flutter run --dart-entrypoint-args --help

for more infos.

