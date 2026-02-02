import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';

/// A kind of cache for hgt calculation. The projections is always the same while calculating for a tile and the file is mostly the same - except for calculations
/// beyond the boundary of the hgt file.
class HgtInfo {
  final PixelProjection projection;

  HgtFile _hgtFile;

  late MapRectangle _rectangle;

  HgtInfo({required HgtFile hgtFile, required this.projection}) : _hgtFile = hgtFile {
    _rectangle = MapRectangle(
      projection.longitudeToPixelX(hgtFile.baseLon.toDouble()),
      projection.latitudeToPixelY((hgtFile.baseLat + hgtFile.latHeight).toDouble()),
      projection.longitudeToPixelX((hgtFile.baseLon + hgtFile.lonWidth).toDouble()),
      projection.latitudeToPixelY(hgtFile.baseLat.toDouble()),
    );
  }

  void takeOver(HgtInfo other) {
    assert(projection.mapsize == other.projection.mapsize);
    _hgtFile = other._hgtFile;
    _rectangle = other._rectangle;
  }

  /// Only for HillshadingRenderer
  int? elevationAt(double latitude, double longitude) {
    return _hgtFile.elevationAt(latitude, longitude);
  }

  bool isInside(double x, double y) {
    return _rectangle.containsCoordinates(x, y);
  }

  MapRectangle get rectangle => _rectangle;

  HgtFile get hgtFile => _hgtFile;
}
