## Source dataset

This hillshading pipeline is based on the NOAA/NCEI (formerly NGDC) **GLOBE** (Global Land One-kilometer Base Elevation) dataset.

Primary documentation:

- https://www.ngdc.noaa.gov/mgg/topo/report/

Download page for the elevation tiles:

- https://www.ngdc.noaa.gov/mgg/topo/gltiles.html

### What GLOBE provides (relevant for hillshading)

- **Coverage**: global, 180°W..180°E and 90°N..90°S.
- **Horizontal grid spacing**: **30 arc-seconds** in latitude and longitude (0.008333…°), i.e. **120 samples per degree**.
  - Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
  - Grid spacing varies in meters with latitude (longitude convergence); see: https://www.ngdc.noaa.gov/mgg/topo/report/s6/s6A.html
- **Coordinate reference**: geographic lat/lon referenced to **WGS84**.
- **Vertical units**: elevation in **meters above mean sea level**.
  - Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11H.html

### Important limitations / caveats

GLOBE is compiled from multiple sources and is not uniformly accurate; do not use it for life-critical navigation.
For hillshading rendering this is usually acceptable, but expect artifacts.

- Caveats summary: https://www.ngdc.noaa.gov/mgg/topo/report/s1/s1.html
- “Imperfections” discussion: https://www.ngdc.noaa.gov/mgg/topo/report/s6/s6.html

## Downloaded tile set

The download page provides tiles **A..P** as:

- `.zip` bundles per tile (e.g. `a10g.zip`) and
- individual `.gz` files per tile (e.g. `a10g.gz`).

Reference: https://www.ngdc.noaa.gov/mgg/topo/gltiles.html

### Naming convention and compression

From the GLOBE documentation:

- There are uncompressed files (no extension) and gzip-compressed files (`.gz`).
- CD-ROM filenames were stored in lowercase.

Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11A.html

## Elevation raster format (critical for reading)

### Binary layout

Each `?10G` and `?10B` elevation tile (where `?` is `A`..`P`) is:

- **16-bit signed integer** (int16) per sample
- **little-endian** byte order
- **row-major** storage
- **no embedded header/trailer** (pure raster values)

Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11D.html

### Tile dimensions

- Each tile has **10800 columns**.
- Rows are either:
  - **4800** (tiles at high latitudes: 50..90 and -90..-50)
  - **6000** (tiles in mid latitudes: 0..50 and -50..0)

Reference (Table 3): https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11C.html

### Geographic extent of the tiles

The tiles are contiguous (no overlap) and can be assembled by abutting.

From Table 3 (same reference as above), the extents are:

- **Rows 50..90** (north): A,B,C,D; each covers 40° latitude (4800 rows)
  - A: lon -180..-90
  - B: lon -90..0
  - C: lon 0..90
  - D: lon 90..180
- **Rows 0..50**: E,F,G,H; 50° latitude (6000 rows)
- **Rows -50..0**: I,J,K,L; 50° latitude (6000 rows)
- **Rows -90..-50** (south): M,N,O,P; 40° latitude (4800 rows)

Each tile covers **90° longitude**.

### NoData / ocean mask

- In GLOBE v1.0, **ocean areas are masked as “no data”** and are assigned a value of **-500**.
- Every tile contains values of -500 for oceans, with no values between -500 and the minimum land elevation for that tile.

Reference:

- General characteristics: https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
- Table note: https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11C.html

Practical implications for hillshading:

- Treat `-500` as **NoData** (do not use it for slope computation).
- When computing derivatives, guard against edge effects near coastlines:
  - if any neighbor in the 3x3 window is NoData, either skip shading for that pixel or use a fallback (e.g. clamp to nearest valid).

## Projection / georeferencing (needed for chunking and random access)

### Coordinate reference

Projection info:

- Geographic (latitude/longitude)
- Datum: WGS84
- Vertical units: meters above MSL
- Cell size: 30 arc-seconds in both lat and lon

Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s11/s11H.html

## Licensing / redistribution notes

Most of the dataset is **not copyright** and unrestricted, except:

- selected “B.A.D.” (Best Available Data) files contain restricted/copyright data
- in GLOBE v1.0, the only B.A.D. area is Australia (copyright AUSLIG)
- “G.O.O.D.” files (Globally Only Open-access Data) are unrestricted

If repackaging/redistributing:

- cite appropriately
- do not redistribute copyright data from `???B` tiles without permission

Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s3/s3B.html

## Hillshading as a dedicated tile layer (below the normal tile layer)

From a UI composition standpoint, hillshading works best as its own tile layer:

- **Bottom layer**: hillshading tiles (grayscale shading)
- **Top layer**: normal vector tile rendering (roads, labels, POIs)

This is important because hillshading is a full-tile raster effect. If it is painted on top, it will reduce readability of labels and roads.

```dart
        final hgtProvider = NoaaFileProvider(directoryPath: (await getTemporaryDirectory()).path);
        renderer = HgtRenderer(
          tileColorRenderer: HgtTileColorRenderer(maxElevation: 2000),
          hgtFileProvider: hgtProvider,
        );

        renderer2 = DatastoreRenderer(datastore, _rendertheme);

        _mapModel = MapModel(renderer: renderer, zoomlevelRange: const ZoomlevelRange(0, 21));
        _mapModel!.addRenderer(renderer2);

```

## Components used for hillshading / elevation tiles

This repository provides a small set of building blocks to render elevation-based tiles (e.g. colored elevation or hillshading) from NOAA/GLOBE or other DEM sources.

### `HgtTileColorRenderer`

Location:

- `packages/mapsforge_flutter_renderer/lib/src/hgt/hgt_tile_color_renderer.dart`

Purpose:

- Converts an elevation value (meters) into a color.
- Uses a precomputed lookup table (LUT) to avoid expensive per-pixel color interpolation.
- Writes pixels into the RGBA tile buffer (`Uint8List`) using packed 32-bit stores.

Constructor parameters:

- `minElevation` (int, default `0`)
  - Minimum elevation (meters) used for clamping / normalization.
- `maxElevation` (int, default `2000`)
  - Maximum elevation (meters) used for clamping / normalization.
- `metersPerColorStep` (int, default `5`)
  - Color compression factor.
  - Example: `5` means “one color for each 5m elevation band”. Higher values are faster and use less memory, but reduce detail.
- `colors` (List<Color>)
  - Gradient key colors.
  - Elevations are mapped across this gradient.
- `oceanColor` (Color)
  - Used when elevation is the ocean/NoData value (`-500`).

Notes:

- Ocean / NoData is encoded as `ElevationArea.ocean` (`-500`).

### `NoaaFileProvider`

Location:

- `packages/mapsforge_flutter_renderer/lib/src/hgt/noaa_file_provider.dart`

Purpose:

- Implements `IHgtFileProvider` for the NOAA/NCEI GLOBE tile layout.
- Given a lat/lon, it selects the correct source tile (e.g. `A10G..P10G`) and loads it as an `HgtFile`.
- Provides `elevationAround(...)` which returns an `ElevationArea` (4 corner elevations + the covered pixel rectangle) used by `HgtRenderer` for interpolation.

Constructor parameters:

- `directoryPath` (String)
  - Directory containing the uncompressed GLOBE tiles (`A10G..P10G` or lowercase variants).

Runtime behavior:

- Maintains an internal LRU-like cache of recently used `HgtFile` instances (currently capped at 4).

### `IHgtFileProvider` / `HgtFileProvider`

Interface location:

- `packages/mapsforge_flutter_renderer/lib/src/hgt/hgt_provider.dart`

Purpose:

- Abstraction used by `HgtRenderer` (and hillshading renderers) to obtain elevation data.
- Allows swapping different DEM backends without changing the renderer.

Key methods:

- `getForLatLon(double latitude, double longitude, PixelProjection projection)`
  - Returns an `HgtInfo` describing the current loaded elevation tile and its pixel-space extent.
- `elevationAround(HgtInfo hgtInfo, Mappoint leftUpper, int x, int y)`
  - Returns an `ElevationArea` for the pixel position `(x,y)` relative to the tile’s top-left.
  - `ElevationArea` contains:
    - `leftTop/rightTop/leftBottom/rightBottom` elevations
    - `minTileX/maxTileX/minTileY/maxTileY` rectangle the four corners cover
    - `isOcean` / `hasOcean` derived flags based on the `-500` ocean mask

`HgtFileProvider`:

- If your project also contains an `HgtFileProvider` (for classic `.hgt` 1°x1° SRTM tiles), it should implement the same `IHgtFileProvider` interface and can be used as a drop-in replacement.

## Theme tuning: make the top layer transparent enough

To actually see hillshading below the normal map rendering, the top tile layer must not be fully opaque everywhere.

Practical recommendations:

- Large polygon fills (forests, landuse, water overlays) should be:
  - disabled in the selected style, or
  - rendered with reduced opacity so the hillshading can shine through.
- Avoid painting large, fully opaque rectangles/polygons that would hide all relief.

This is usually controlled in the render theme:

- Use separate styles / categories for “heavy” fills and allow disabling them via `<stylemenu>`.
- Use lower opacity colors for fills.

## Performance and accuracy caveats

Hillshading is computationally expensive:

- It requires sampling multiple elevation values per output pixel (neighbors for gradient/slope).
- It can be very I/O heavy if elevation data is read from disk without an effective cache.

Accuracy limitations:

- The underlying dataset (GLOBE) is relatively low resolution (30 arc-seconds).
- Coastlines (sea/land border) are a common source of artifacts because the dataset uses `-500` as NoData/ocean mask.
- When NoData is present in the neighborhood window used for gradients, the resulting slope can be wrong or produce visible seams.

For best visual results you typically need:

- NoData-aware sampling (treat `-500` as missing data)
- Edge handling near chunk/tile borders
- Caching of recently used DEM chunks

## Converter tooling: globe_dem_converter

This repository contains an app to convert the large original GLOBE tiles into smaller chunk files better suited for runtime hillshading:

- `apps/globe_dem_converter`

It converts input tiles `A10G..P10G` into output `.dem` chunks:

- Raw `int16` little-endian
- Row-major
- No header

Usage (from repo root):

```bash
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart --help
dart run apps/globe_dem_converter/bin/globe_dem_converter.dart help convert

dart run apps/globe_dem_converter/bin/globe_dem_converter.dart convert \
  -i "D:\\globe\\tiles" \
  -o "D:\\globe\\chunks" \
  -w 1.0 \
  --tileHeight 1.0 \
  --startLat 47.0 --startLon 10.0 \
  --endLat 49.0 --endLon 12.0 \
  --resample 1
```

What `--resample` means:

- `resample=1` keeps original GLOBE grid (30 arc-seconds).
- `resample=N` averages over `N x N` blocks (NoData-aware for `-500`) to reduce resolution and speed up runtime.

Integration idea:

- Use the converter output directory as the DEM source for your hillshading tile layer.
- Ensure the runtime reader knows:
  - the chunk naming scheme
  - the chunk extent (`latMin/lonMin/latMax/lonMax`)
  - the effective sample spacing (`resample * 1/120°`)

## References

- Mapsforge RenderTheme documentation:
  - https://github.com/mapsforge/mapsforge/blob/master/docs/Rendertheme.md
- GLOBE documentation:
  - https://www.ngdc.noaa.gov/mgg/topo/report/
- globe_dem_converter (this repo):
  - `apps/globe_dem_converter/README.md`
