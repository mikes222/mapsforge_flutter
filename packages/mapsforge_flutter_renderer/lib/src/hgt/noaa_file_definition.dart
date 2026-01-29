enum NoaaFileDefinition {
  a10g(fileName: 'a11g', latMin: 50, latMax: 90, lonMin: -180, lonMax: -90, rows: 4800),
  b10g(fileName: 'b10g', latMin: 50, latMax: 90, lonMin: -90, lonMax: 0, rows: 4800),
  c10g(fileName: 'c10g', latMin: 50, latMax: 90, lonMin: 0, lonMax: 90, rows: 4800),
  d10g(fileName: 'd10g', latMin: 50, latMax: 90, lonMin: 90, lonMax: 180, rows: 4800),
  e10g(fileName: 'e10g', latMin: 0, latMax: 50, lonMin: -180, lonMax: -90, rows: 6000),
  f10g(fileName: 'f10g', latMin: 0, latMax: 50, lonMin: -90, lonMax: 0, rows: 6000),
  g10g(fileName: 'g10g', latMin: 0, latMax: 50, lonMin: 0, lonMax: 90, rows: 6000),
  h10g(fileName: 'h10g', latMin: 0, latMax: 50, lonMin: 90, lonMax: 180, rows: 6000),
  i10g(fileName: 'i10g', latMin: -50, latMax: 0, lonMin: -180, lonMax: -90, rows: 6000),
  j10g(fileName: 'j10g', latMin: -50, latMax: 0, lonMin: -90, lonMax: 0, rows: 6000),
  k10g(fileName: 'k10g', latMin: -50, latMax: 0, lonMin: 0, lonMax: 90, rows: 6000),
  l10g(fileName: 'l10g', latMin: -50, latMax: 0, lonMin: 90, lonMax: 180, rows: 6000),
  m10g(fileName: 'm10g', latMin: -90, latMax: -50, lonMin: -180, lonMax: -90, rows: 4800),
  n10g(fileName: 'n10g', latMin: -90, latMax: -50, lonMin: -90, lonMax: 0, rows: 4800),
  o10g(fileName: 'o10g', latMin: -90, latMax: -50, lonMin: 0, lonMax: 90, rows: 4800),
  p10g(fileName: 'p10g', latMin: -90, latMax: -50, lonMin: 90, lonMax: 180, rows: 4800);

  final String fileName;
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;
  final int rows;

  const NoaaFileDefinition({
    required this.fileName,
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
    required this.rows,
  });

  double get width => lonMax - lonMin;

  double get height => latMax - latMin;

  static NoaaLatBand latBandFor(double lat) {
    if (lat >= 50) return NoaaLatBand.n50_90;
    if (lat >= 0) return NoaaLatBand.n0_50;
    if (lat >= -50) return NoaaLatBand.s50_0;
    return NoaaLatBand.s90_50;
  }

  static NoaaLonBand lonBandFor(double lon) {
    if (lon < -90) return NoaaLonBand.w180_90;
    if (lon < 0) return NoaaLonBand.w90_0;
    if (lon < 90) return NoaaLonBand.e0_90;
    return NoaaLonBand.e90_180;
  }

  static NoaaFileDefinition sourceTileFor(double lat, double lon) {
    final latBand = latBandFor(lat);
    final lonBand = lonBandFor(lon);
    return sourceTileForBands(latBand, lonBand);
  }

  static NoaaFileDefinition sourceTileForBands(NoaaLatBand latBand, NoaaLonBand lonBand) {
    switch (latBand) {
      case NoaaLatBand.n50_90:
        return switch (lonBand) {
          NoaaLonBand.w180_90 => NoaaFileDefinition.a10g,
          NoaaLonBand.w90_0 => NoaaFileDefinition.b10g,
          NoaaLonBand.e0_90 => NoaaFileDefinition.c10g,
          NoaaLonBand.e90_180 => NoaaFileDefinition.d10g,
        };
      case NoaaLatBand.n0_50:
        return switch (lonBand) {
          NoaaLonBand.w180_90 => NoaaFileDefinition.e10g,
          NoaaLonBand.w90_0 => NoaaFileDefinition.f10g,
          NoaaLonBand.e0_90 => NoaaFileDefinition.g10g,
          NoaaLonBand.e90_180 => NoaaFileDefinition.h10g,
        };
      case NoaaLatBand.s50_0:
        return switch (lonBand) {
          NoaaLonBand.w180_90 => NoaaFileDefinition.i10g,
          NoaaLonBand.w90_0 => NoaaFileDefinition.j10g,
          NoaaLonBand.e0_90 => NoaaFileDefinition.k10g,
          NoaaLonBand.e90_180 => NoaaFileDefinition.l10g,
        };
      case NoaaLatBand.s90_50:
        return switch (lonBand) {
          NoaaLonBand.w180_90 => NoaaFileDefinition.m10g,
          NoaaLonBand.w90_0 => NoaaFileDefinition.n10g,
          NoaaLonBand.e0_90 => NoaaFileDefinition.o10g,
          NoaaLonBand.e90_180 => NoaaFileDefinition.p10g,
        };
    }
  }
}

enum NoaaLatBand { n50_90, n0_50, s50_0, s90_50 }

enum NoaaLonBand { w180_90, w90_0, e0_90, e90_180 }
