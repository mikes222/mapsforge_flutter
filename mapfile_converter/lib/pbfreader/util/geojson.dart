import 'geometry.dart';

enum GeoJsonType { Feature, FeatureCollection }

class VectorTileValue {}

class GeoJson<T extends Geometry> {
  final GeoJsonType type = GeoJsonType.Feature;
  Map<String, VectorTileValue>? properties;
  T? geometry;

  GeoJson({this.properties, this.geometry});
}

class GeoJsonPoint extends GeoJson<GeometryPoint> {
  GeoJsonPoint({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonMultiPoint extends GeoJson<GeometryMultiPoint> {
  GeoJsonMultiPoint({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonLineString extends GeoJson<GeometryLineString> {
  GeoJsonLineString({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonMultiLineString extends GeoJson<GeometryMultiLineString> {
  GeoJsonMultiLineString({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonPolygon extends GeoJson<GeometryPolygon> {
  GeoJsonPolygon({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonMultiPolygon extends GeoJson<GeometryMultiPolygon> {
  GeoJsonMultiPolygon({required properties, required geometry})
      : super(properties: properties, geometry: geometry);
}

class GeoJsonFeatureCollection extends GeoJson {
  @override
  final GeoJsonType type = GeoJsonType.FeatureCollection;
  List<GeoJson?> features;

  GeoJsonFeatureCollection({required this.features}) : super();
}
