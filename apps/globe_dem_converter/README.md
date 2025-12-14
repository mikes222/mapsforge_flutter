## globe_dem_converter

Converts NOAA/NCEI **GLOBE** DEM tiles (uncompressed `A10G..P10G`) into smaller, regularly gridded lat/lon chunk tiles.

### Input

- A directory that contains one or more uncompressed GLOBE elevation tiles.
- Files must be raw **int16 little-endian**, row-major, without headers.
- Expected filenames:
  - `A10G..P10G` (uppercase) or
  - `a10g..p10g` (lowercase)

### Output

- Raw `int16` little-endian, row-major, **no header** (`.bin` extension)
- Filename format:

`tile_{latMin}_{lonMin}_{latMax}_{lonMax}.bin`

Coordinates are written with 6 decimals.

### Important constraints (current implementation)

- The converter currently supports **Option A** only (no resampling).
- All degree values must align to the native GLOBE grid:
  - `1 cell = 30 arc-seconds = 1/120°`
  - therefore `tileWidth`, `tileHeight`, `startLat`, `startLon`, `endLat`, `endLon` must be multiples of `1/120`.
- Tiles are aligned to the provided start/end parameters.
- **Partial tiles** are generated at the edges if the extent is not divisible by the requested tile size.

### Usage

From the repo root:

```bash
# Show global help
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart --help

# Show command help
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart help convert
```

Convert example:

```bash
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart convert \
  -i "D:\\globe\\tiles" \
  -o "D:\\globe\\chunks" \
  -w 1.0 \
  --tileHeight 1.0 \
  --startLat 47.0 --startLon 10.0 \
  --endLat 49.0 --endLon 12.0
```

Dry run (prints planned tiles but does not write files):

```bash
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart convert \
  -i "D:\\globe\\tiles" \
  -w 1.0 \
  --tileHeight 1.0 \
  --startLat 47.0 --startLon 10.0 \
  --endLat 49.0 --endLon 12.0 \
  --dryRun
```
