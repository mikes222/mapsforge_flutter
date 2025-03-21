import '../../../core.dart';
import '../../../datastore.dart';
import '../../../maps.dart';
import '../../../special.dart';
import '../../utils/douglas_peucker_latlong.dart';

class WaySimplifyFilter {
  final DouglasPeuckerLatLong dpl = DouglasPeuckerLatLong();

  final PixelProjection projection;

  final double maxDeviationPixel;

  late final double maxDeviationLatLong;

  final BoundingBox boundingBox;

  WaySimplifyFilter(int zoomlevel, this.maxDeviationPixel, this.boundingBox) : projection = PixelProjection(zoomlevel) {
    maxDeviationLatLong = projection.latitudeDiffPerPixel((boundingBox.minLatitude + boundingBox.maxLatitude) / 2, maxDeviationPixel);
    //print("maxDeviationLatLong: $maxDeviationLatLong for maxZoom: $zoomlevel");
  }

  Wayholder reduce(Wayholder wayholder) {
    List<List<ILatLong>> newLatLongs = [];
    for (List<ILatLong> latLongs in wayholder.way.latLongs) {
      newLatLongs.add(reduceWay(latLongs));
    }
    Wayholder result = wayholder.cloneWith(way: Way(wayholder.way.layer, wayholder.way.tags, newLatLongs, wayholder.way.labelPosition));

    newLatLongs = [];
    for (List<ILatLong> latLongs in wayholder.otherOuters) {
      newLatLongs.add(reduceWay(latLongs));
    }
    result.otherOuters = newLatLongs;
    return result;
  }

  List<ILatLong> reduceWay(List<ILatLong> latLongs) {
    if (latLongs.length <= 5) {
      return latLongs;
    }
    List<ILatLong> res1 = dpl.simplify(latLongs, maxDeviationLatLong);
    // if (res1.length > 32767) {
    //   print("${res1.length} too much at zoomlevel ${projection.scalefactor.zoomlevel} and $maxDeviationPixel ($maxDeviationLatLong) and $boundingBox");
    // }
    return res1;
  }

  List<ILatLong> reduceWayEnsureMax(List<ILatLong> latLongs) {
    if (latLongs.length <= 5) {
      return latLongs;
    }
    return _reduceWayEnsureMax(latLongs, maxDeviationLatLong);
  }

  List<ILatLong> _reduceWayEnsureMax(List<ILatLong> latLongs, double maxDeviation) {
    List<ILatLong> res1 = dpl.simplify(latLongs, maxDeviation);
    if (res1.length > 32767) return _reduceWayEnsureMax(latLongs, maxDeviation + maxDeviationLatLong);
    return res1;
  }
}
