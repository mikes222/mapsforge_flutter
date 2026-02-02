import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_info.dart';

abstract class IHgtFileProvider {
  HgtInfo getForLatLon(double latitude, double longitude, PixelProjection projection);

  ElevationArea? elevationAround(HgtInfo hgtInfo, Mappoint leftUpper, int x, int y);
}

class ElevationArea {
  static const int ocean = -500;

  final int leftTop;

  final int rightTop;

  final int leftBottom;

  final int rightBottom;

  final int minTileX;

  final int maxTileX;

  final int minTileY;

  final int maxTileY;

  late bool isOcean;

  late bool hasOcean;

  ElevationArea(this.leftTop, this.rightTop, this.leftBottom, this.rightBottom, this.minTileX, this.maxTileX, this.minTileY, this.maxTileY)
    : assert(minTileX <= maxTileX),
      assert(minTileY <= maxTileY) {
    int count = 0;
    // -500 represents ocean, see https://www.ngdc.noaa.gov/mgg/topo/report/s4/s4.html
    if (leftTop == ocean) ++count;
    if (rightTop == ocean) ++count;
    if (leftBottom == ocean) ++count;
    if (rightBottom == ocean) ++count;
    isOcean = count >= 2;
    hasOcean = count == 1;
  }

  @override
  String toString() {
    return 'ElevationArea{leftTop: $leftTop, rightTop: $rightTop, leftBottom: $leftBottom, rightBottom: $rightBottom, minTileX: $minTileX, maxTileX: $maxTileX, minTileY: $minTileY, maxTileY: $maxTileY, isOcean: $isOcean, hasOcean: $hasOcean}';
  }
}
