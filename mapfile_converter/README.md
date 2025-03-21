Converts a pbf file to a mapfile. It uses a rendertheme file to determine which points/ways should be kept and which can be omitted in the destination file.

Currently the base zoomlevel must be equal to the min zoomlevel

Start with 

    flutter run --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=monaco-latest.osm.pbf --dart-entrypoint-args --destinationfile=monaco.map

or

    flutter run --dart-entrypoint-args --rendertheme=lightrender.xml --dart-entrypoint-args --sourcefile=map_default_46_16.pbf --dart-entrypoint-args --destinationfile=test.map --dart-entrypoint-args --boundary="47.6,16.6,48,16.9"

type

    flutter run --dart-entrypoint-args --help

for more infos.