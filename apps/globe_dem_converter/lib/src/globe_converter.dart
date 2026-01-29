import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:globe_dem_converter/src/noaa_file_definition.dart';
import 'package:logging/logging.dart';

class GlobeDemConverter {
  static final _log = Logger('GlobeDemConverter');

  GlobeDemConverter();

  // original files have 120 elevation information per degree lat/lon
  static const int dimensionPerDegree = 120;
  static const double _cellSizeDeg = 1.0 / 120.0;
  static const int _colsPerSourceTile = 10800;
  static const int _noDataValue = -500;

  Future<void> convert({
    required Directory inputDir,
    required Directory outputDir,
    required int tileWidthDeg,
    required int tileHeightDeg,
    required int startLat,
    required int startLon,
    required int endLat,
    required int endLon,
    required int resampleFactor,
    required bool dryRun,
    required String fileformat,
  }) async {
    if (!inputDir.existsSync()) {
      throw ArgumentError('Input directory does not exist: ${inputDir.path}');
    }

    if (resampleFactor < 1 || resampleFactor > 100) {
      throw ArgumentError('resampleFactor must be in range 1..100. Got $resampleFactor');
    }

    final outCellSizeDeg = _cellSizeDeg * resampleFactor;

    _ensureAligned(tileWidthDeg, 'tileWidth', outCellSizeDeg: outCellSizeDeg);
    _ensureAligned(tileHeightDeg, 'tileHeight', outCellSizeDeg: outCellSizeDeg);
    _ensureAligned(startLat, 'startLat', outCellSizeDeg: outCellSizeDeg);
    _ensureAligned(startLon, 'startLon', outCellSizeDeg: outCellSizeDeg);
    _ensureAligned(endLat, 'endLat', outCellSizeDeg: outCellSizeDeg);
    _ensureAligned(endLon, 'endLon', outCellSizeDeg: outCellSizeDeg);

    final planned = _planTiles(
      tileWidthDeg: tileWidthDeg,
      tileHeightDeg: tileHeightDeg,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      outCellSizeDeg: outCellSizeDeg,
    );

    _log.info('Planned output tiles: ${planned.length}');

    if (dryRun) {
      for (final t in planned.take(min(50, planned.length))) {
        _log.info('tile: ${t.latMin},${t.lonMin} -> ${t.latMax},${t.lonMax} (${t.rows}x${t.cols})');
      }
      if (planned.length > 50) {
        _log.info('... (${planned.length - 50} more)');
      }
      return;
    }

    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    final sourceCache = _SourceTileCache(inputDir: inputDir);

    try {
      for (final tile in planned) {
        final outName = _outputFilename(tile, fileformat, resampleFactor: resampleFactor);
        final outFile = File('${outputDir.path}${Platform.pathSeparator}$outName');

        _log.info('Writing ${outFile.path} (${tile.rows}x${tile.cols})');

        final rafOut = await outFile.open(mode: FileMode.write);
        try {
          await _writeTile(tile, sourceCache, rafOut, resampleFactor: resampleFactor, outCellSizeDeg: outCellSizeDeg);
        } finally {
          await rafOut.close();
        }
      }
    } finally {
      await sourceCache.close();
    }
  }

  Future<void> _writeTile(
    _OutTile tile,
    _SourceTileCache sourceCache,
    RandomAccessFile rafOut, {
    required int resampleFactor,
    required double outCellSizeDeg,
  }) async {
    // resampleFactor == 1 => direct copy (old behavior)
    if (resampleFactor == 1) {
      final rowBuffer = Uint8List(tile.cols * 2);
      for (int r = 0; r < tile.rows; r++) {
        final latCenter = tile.latMax - (r + 0.5) * outCellSizeDeg;
        final latBand = NoaaFileDefinition.latBandFor(latCenter);

        int colWritten = 0;
        for (final seg in tile.lonSegments) {
          final lonCenter = (seg.lonMin + seg.lonMax) / 2.0;
          final lonBand = NoaaFileDefinition.lonBandFor(lonCenter);

          final source = NoaaFileDefinition.sourceTileForBands(latBand, lonBand);
          final sourceTile = await sourceCache.open(source);

          final rowInSource = ((source.latMax - latCenter) * dimensionPerDegree).floor();
          final colStartInSource = ((seg.lonMin - source.lonMin) * dimensionPerDegree).floor();
          final colsToRead = seg.cols;

          final offsetBytes = (rowInSource * _colsPerSourceTile + colStartInSource) * 2;
          await sourceTile.raf.setPosition(offsetBytes);

          final bytes = await sourceTile.raf.read(colsToRead * 2);
          rowBuffer.setRange(colWritten * 2, colWritten * 2 + bytes.length, bytes);
          colWritten += colsToRead;
        }

        if (colWritten != tile.cols) {
          throw StateError('Internal error: row write mismatch, wrote $colWritten cols, expected ${tile.cols}');
        }
        await rafOut.writeFrom(rowBuffer);
      }
      return;
    }

    // Downsample: average resampleFactor x resampleFactor blocks.
    final outRowBytes = Uint8List(tile.cols * 2);
    final outRow = ByteData.sublistView(outRowBytes);

    for (int outR = 0; outR < tile.rows; outR++) {
      final latTop = tile.latMax - outR * outCellSizeDeg;
      final latBottom = latTop - outCellSizeDeg;
      final latCenter = (latTop + latBottom) / 2.0;

      final latBand = NoaaFileDefinition.latBandFor(latCenter);

      int outColWritten = 0;
      for (final seg in tile.lonSegments) {
        final lonCenter = (seg.lonMin + seg.lonMax) / 2.0;
        final lonBand = NoaaFileDefinition.lonBandFor(lonCenter);
        final source = NoaaFileDefinition.sourceTileForBands(latBand, lonBand);
        final sourceTile = await sourceCache.open(source);

        // Start row in source (top of output pixel block)
        final rowStartInSource = ((source.latMax - latTop) * dimensionPerDegree).round();

        // For this segment, we need seg.cols output columns. Each output column covers resampleFactor source columns.
        final srcColsToRead = seg.cols * resampleFactor;
        final colStartInSource = ((seg.lonMin - source.lonMin) * dimensionPerDegree).round();

        // Read resampleFactor rows into memory for this segment.
        final srcRowBytes = Uint8List(srcColsToRead * 2);
        final srcRowView = ByteData.sublistView(srcRowBytes);

        for (int outC = 0; outC < seg.cols; outC++) {
          int sum = 0;
          int count = 0;
          int max = _noDataValue;

          // For each row in the block
          for (int rr = 0; rr < resampleFactor; rr++) {
            final srcRow = rowStartInSource + rr;
            final offsetBytes = (srcRow * _colsPerSourceTile + colStartInSource) * 2;
            await sourceTile.raf.setPosition(offsetBytes);
            final bytes = await sourceTile.raf.read(srcColsToRead * 2);
            srcRowBytes.setRange(0, bytes.length, bytes);

            final srcColBase = outC * resampleFactor;
            for (int cc = 0; cc < resampleFactor; cc++) {
              final v = srcRowView.getInt16((srcColBase + cc) * 2, Endian.little);
              if (v == _noDataValue) continue;
              sum += v;
              count++;
              if (max == _noDataValue || max < v) {
                max = v;
              }
            }
          }

          // use maximum height instead of average.
          final outValue = count == 0 ? _noDataValue : max; //(sum / count).round();
          outRow.setInt16((outColWritten + outC) * 2, outValue, Endian.little);
        }

        outColWritten += seg.cols;
      }

      if (outColWritten != tile.cols) {
        throw StateError('Internal error: row write mismatch, wrote $outColWritten cols, expected ${tile.cols}');
      }

      await rafOut.writeFrom(outRowBytes);
    }
  }

  List<_OutTile> _planTiles({
    required int tileWidthDeg,
    required int tileHeightDeg,
    required int startLat,
    required int startLon,
    required int endLat,
    required int endLon,
    required double outCellSizeDeg,
  }) {
    final tiles = <_OutTile>[];

    for (int latMin = startLat; latMin < endLat; latMin += tileHeightDeg) {
      final latMax = min(latMin + tileHeightDeg, endLat);
      final rows = _degToSamples(latMax - latMin, outCellSizeDeg: outCellSizeDeg);

      for (int lonMin = startLon; lonMin < endLon; lonMin += tileWidthDeg) {
        final lonMax = min(lonMin + tileWidthDeg, endLon);
        final cols = _degToSamples(lonMax - lonMin, outCellSizeDeg: outCellSizeDeg);

        final lonSegments = _splitLonSegments(lonMin, lonMax, outCellSizeDeg: outCellSizeDeg);
        tiles.add(_OutTile(latMin: latMin, latMax: latMax, lonMin: lonMin, lonMax: lonMax, rows: rows, cols: cols, lonSegments: lonSegments));
      }
    }

    return tiles;
  }

  List<_LonSegment> _splitLonSegments(int lonMin, int lonMax, {required double outCellSizeDeg}) {
    // Split output tile into segments so that each segment belongs to exactly one source lon band.
    const boundaries = [-180, -90, 0, 90, 180];

    final segments = <_LonSegment>[];
    int cursor = lonMin;

    while (cursor < lonMax) {
      int next = lonMax;
      for (final b in boundaries) {
        if (b > cursor && b < next) next = b;
      }

      final segMin = cursor;
      final segMax = next;
      segments.add(
        _LonSegment(
          lonMin: segMin,
          lonMax: segMax,
          cols: _degToSamples(segMax - segMin, outCellSizeDeg: outCellSizeDeg),
        ),
      );
      cursor = next;
    }

    return segments;
  }

  static void _ensureAligned(int value, String name, {required double outCellSizeDeg}) {
    final steps = value / outCellSizeDeg;
    final rounded = steps.roundToDouble();
    if ((steps - rounded).abs() > 1e-9) {
      throw ArgumentError('$name must align to ${outCellSizeDeg}° steps. Got $value');
    }
  }

  static int _degToSamples(int deg, {required double outCellSizeDeg}) {
    final steps = deg / outCellSizeDeg;
    return steps.round();
  }

  static String _outputFilename(_OutTile t, String fileformat, {required int resampleFactor}) {
    String filename = fileformat;

    final latPrefix = t.latMin >= 0 ? 'N' : 'S';
    final lonPrefix = t.lonMin >= 0 ? 'E' : 'W';
    final latAbs = t.latMin.abs().toString().padLeft(2, '0');
    final lonAbs = t.lonMin.abs().toString().padLeft(3, '0');
    final int width = (t.lonMax - t.lonMin);
    final int height = (t.lonMax - t.lonMin);

    filename = filename.replaceAll('{latMin}', _fmtCoord(t.latMin));
    filename = filename.replaceAll('{lonMin}', _fmtCoord(t.lonMin));
    filename = filename.replaceAll('{latMax}', _fmtCoord(t.latMax));
    filename = filename.replaceAll('{lonMax}', _fmtCoord(t.lonMax));
    filename = filename.replaceAll('{resampleFactor}', "$resampleFactor");
    filename = filename.replaceAll('{latAbs}', "$latPrefix$latAbs");
    filename = filename.replaceAll('{lonAbs}', "$lonPrefix$lonAbs");
    filename = filename.replaceAll('{width}', "$width");
    filename = filename.replaceAll('{height}', "$height");

    return filename;
  }

  static String _fmtCoord(int v) {
    // fixed decimals to keep deterministic filenames.
    // also avoid "+" in filenames.
    final s = v.toStringAsFixed(0);
    return s.replaceAll('+', '');
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SourceTileHandle {
  final NoaaFileDefinition def;
  final RandomAccessFile raf;

  _SourceTileHandle(this.def, this.raf);
}

//////////////////////////////////////////////////////////////////////////////

class _SourceTileCache {
  static final _log = Logger('_SourceTileCache');
  final Directory inputDir;

  final Map<NoaaFileDefinition, _SourceTileHandle> _open = {};

  _SourceTileCache({required this.inputDir});

  Future<_SourceTileHandle> open(NoaaFileDefinition def) async {
    final existing = _open[def];
    if (existing != null) return existing;

    final file = _locateFile(def.fileName);
    if (file == null) {
      throw ArgumentError('Missing source tile ${def.fileName} in ${inputDir.path}');
    }

    // Verify file size matches expectation.
    final expectedBytes = def.rows * 10800 * 2;
    final actualBytes = await file.length();
    if (actualBytes != expectedBytes) {
      throw ArgumentError('Unexpected file size for ${file.path}: got $actualBytes bytes, expected $expectedBytes');
    }

    final raf = await file.open(mode: FileMode.read);
    final handle = _SourceTileHandle(def, raf);
    _open[def] = handle;
    return handle;
  }

  File? _locateFile(String baseName) {
    // Accept exact case and also lowercase.
    final candidates = <String>[baseName, baseName.toLowerCase()];
    for (final c in candidates) {
      final f = File('${inputDir.path}${Platform.pathSeparator}$c');
      if (f.existsSync()) return f;
    }
    return null;
  }

  Future<void> close() async {
    for (final h in _open.values) {
      await h.raf.close();
    }
    _open.clear();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _LonSegment {
  final int lonMin;
  final int lonMax;
  final int cols;

  _LonSegment({required this.lonMin, required this.lonMax, required this.cols});
}

//////////////////////////////////////////////////////////////////////////////

class _OutTile {
  final int latMin;
  final int latMax;
  final int lonMin;
  final int lonMax;

  final int rows;
  final int cols;

  final List<_LonSegment> lonSegments;

  _OutTile({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
    required this.rows,
    required this.cols,
    required this.lonSegments,
  });
}
