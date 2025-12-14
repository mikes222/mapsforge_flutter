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

### Grid math

Key constants:

- `cellSizeDeg = 30" = 30/3600 = 1/120 = 0.008333333333333333°`
- `samplesPerDegree = 120`

For a tile with geographic extent:

- `latMax` (north edge), `latMin` (south edge)
- `lonMin` (west edge), `lonMax` (east edge)

Assuming row-major order where **row 0 is the northernmost row** (typical for rasters), mapping would be:

- `lat(row) = latMax - (row + 0.5) * cellSizeDeg`
- `lon(col) = lonMin + (col + 0.5) * cellSizeDeg`

Random access mapping for a given lat/lon:

- `col = floor((lon - lonMin) * samplesPerDegree)`
- `row = floor((latMax - lat) * samplesPerDegree)`

Byte offset in a raw tile:

- `offsetBytes = (row * cols + col) * 2`

Notes:

- This assumes cell centers. For cell-boundary interpretation, keep consistent with rendering/hillshading sampling.
- Longitude wrap handling: input `lon` may be normalized to [-180, 180).

## Licensing / redistribution notes

Most of the dataset is **not copyright** and unrestricted, except:

- selected “B.A.D.” (Best Available Data) files contain restricted/copyright data
- in GLOBE v1.0, the only B.A.D. area is Australia (copyright AUSLIG)
- “G.O.O.D.” files (Globally Only Open-access Data) are unrestricted

If repackaging/redistributing:

- cite appropriately
- do not redistribute copyright data from `???B` tiles without permission

Reference: https://www.ngdc.noaa.gov/mgg/topo/report/s3/s3B.html

## Goal 1: Converter (combine/split into other chunk sizes)

### Converter responsibilities

- Input:
  - existing GLOBE tiles `A10G..P10G` (and optionally source/lineage tiles if present)
  - compressed `.gz` and/or uncompressed raw
- Output:
  - a chunked layout optimized for your rendering pipeline
  - with an index to support fast lookup by lat/lon (or by map tile)

### Suggested chunking strategies

You mentioned “one chunk per lat/lon”. There are two practical interpretations:

1) **One chunk per 1°x1°** (recommended)
   - Contains `120 x 120` samples
   - Natural unit because GLOBE is 120 samples per degree
   - Small enough to load quickly, big enough for good I/O amortization
2) **One chunk per integer latitude row or longitude column** (not recommended)
   - Extremely wide/long strips (poor cache behavior)
   - Harder to manage for random access

For hillshading you also often need a 1-sample border to compute gradients.
So for 1°x1° chunks, consider storing `122 x 122` (1-sample padding all sides), or handle borders by reading neighboring chunks.

### Converter plan

1. **Inventory / validation of input files**
   - detect which tiles are present (A..P)
   - verify file sizes match expected `(cols * rows * 2)`
     - 10800*4800*2 = 103,680,000 bytes
     - 10800*6000*2 = 129,600,000 bytes
2. **Define target chunk spec**
   - chunk size in degrees (e.g. 1°)
   - storage format (raw int16 LE, or compressed per chunk)
   - optional padding strategy
3. **Implement deterministic mapping**
   - for each output chunk, compute its source tile(s) and source window(s)
   - copy/transform data (including padding)
4. **Write an index**
   - mapping from chunk key (latDeg, lonDeg) -> file offset/path
   - keep it simple and fast (e.g. fixed naming scheme so index can be implicit)
5. **Verification**
   - spot-check coordinate->value correctness using known land/ocean values
   - verify seams between chunks are consistent

## Goal 2: Fast reader (random access for hillshading)

### Reader responsibilities

- Provide fast access to elevation samples needed to shade a map tile:
  - typically a grid window around a tile extent
  - plus a border for derivative computations
- Support either:
  - memory-mapped / in-memory caching of recently used chunks, or
  - direct random access reads from disk

### Recommended reader architecture

1) **Two-level addressing**
   - Level A: determine which chunk(s) intersect the requested map tile
   - Level B: within each chunk, compute sample indices and read the window

2) **Chunk cache**
   - LRU cache keyed by chunk id
   - store decoded int16 array (or bytes) plus metadata

3) **NoData-aware sampling**
   - treat -500 as NoData
   - ensure gradient computation is robust near NoData regions

### Reader plan

1. **Choose access unit**
   - If using converted 1° chunks: read small chunk files, cache decoded samples
   - If using original GLOBE tiles: random access inside the 10800x(4800|6000) tile (works but large file seeks)
2. **Implement coordinate transforms**
   - WGS84 lat/lon -> chunk id + sample indices
   - map tile boundary -> required sample window (+ border)
3. **Implement window read API**
   - read a rectangular region of samples efficiently
   - for disk-based access, prefer reading contiguous row segments
4. **Integrate with hillshading pipeline**
   - provide samples to hillshade renderer (slope/gradient algorithm)
   - define how to handle missing chunks / NoData
5. **Performance validation**
   - measure I/O time per rendered tile
   - tune cache size and chunk format

## Open questions / things to verify against the downloaded files

- Are your elevation tiles `?10G` (G.O.O.D.) or `?10B` (contains restricted data)?
- Are the files already uncompressed, or still `.gz` / inside `.zip`?
- Do you also have the **source/lineage** tiles (useful for ocean masking and attribution)?
- Confirm whether row 0 is northmost in the raw binary for the downloaded tiles (very likely, but we should validate by sampling known regions).

