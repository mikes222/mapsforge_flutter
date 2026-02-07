import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';

abstract class HgtProvider {
  HgtFile getForLatLon(double latitude, double longitude);
}
