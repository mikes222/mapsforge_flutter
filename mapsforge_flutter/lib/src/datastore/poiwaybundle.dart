import 'pointofinterest.dart';
import 'way.dart';

class PoiWayBundle {
  final List<PointOfInterest> pois;
  final List<Way> ways;

  PoiWayBundle(this.pois, this.ways);
}
