import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:path_provider/path_provider.dart';

class HgtDebugDatastore extends DefaultMarkerDatastore {
  HgtProvider? hgtProvider;

  HgtInfo? _info;

  HgtFile? _hgtFile;

  HgtDebugDatastore() {
    getTemporaryDirectory().then((directory) {
      // may throw an error because the hgtProvider may not be initialized in time but this is just for debugging purposes so never mind
      hgtProvider = HgtFileProvider(directoryPath: directory.path);
      requestRepaint();
    });
  }

  @override
  void askChangeZoomlevel(int zoomlevel, BoundingBox boundingBox, PixelProjection projection) {
    super.askChangeZoomlevel(zoomlevel, boundingBox, projection);
    if (hgtProvider == null) return;
    _rebuild(boundingBox, projection);
  }

  void _rebuild(BoundingBox boundingBox, PixelProjection projection) {
    final center = boundingBox.getCenterPoint();
    HgtFile hgtFile = hgtProvider!.getForLatLon(center.latitude, center.longitude);
    HgtInfo info = HgtInfo(projection: projection, hgtProvider: hgtProvider!);
    if (_info == null || _hgtFile != hgtFile) {
      _hgtFile = hgtFile;
      _info = info;
      clearMarkers();
      addMarker(
        RectMarker(
          minLatLon: LatLong(hgtFile.baseLat.toDouble(), hgtFile.baseLon.toDouble()),
          maxLatLon: LatLong((hgtFile.baseLat + hgtFile.latHeight).toDouble(), (hgtFile.baseLon + hgtFile.lonWidth).toDouble()),
        ),
      );
      double latStep = hgtFile.latHeight / (hgtFile.rows - 1);
      double lonStep = hgtFile.lonWidth / (hgtFile.columns - 1);
      for (double lat = hgtFile.baseLat.toDouble(); lat <= (hgtFile.baseLat + hgtFile.latHeight).toDouble(); lat += latStep) {
        double latY = projection.latitudeToPixelY(lat);
        for (double lon = hgtFile.baseLon.toDouble(); lon <= (hgtFile.baseLon + hgtFile.lonWidth).toDouble(); lon += lonStep) {
          int? elevation = hgtFile.elevationAt(lat, lon);
          if (elevation == HgtFile.ocean) {
            addMarker(CircleMarker(latLong: LatLong(lat, lon), radius: 3, strokeColor: 0xff0000ff));
          } else {
            addMarker(
              CircleMarker(latLong: LatLong(lat, lon), radius: 3)
                ..addCaption(caption: "$elevation", fontSize: 20, zoomlevelRange: const ZoomlevelRange(14, 25)),
            );
          }
        }
      }
      //print("min: $minLat, max: $maxLat");
    }
  }

  @override
  void askChangeBoundingBox(int zoomlevel, BoundingBox boundingBox) {
    super.askChangeBoundingBox(zoomlevel, boundingBox);
    if (hgtProvider == null) return;
    //_rebuild(boundingBox, projection);
  }
}
