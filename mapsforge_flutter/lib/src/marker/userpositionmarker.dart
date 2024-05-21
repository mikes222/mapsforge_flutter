import 'dart:async';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/model/pos.dart';
import 'package:mapsforge_flutter/src/model/usercurrentposition.dart';
import 'package:mapsforge_flutter/src/service/gpsservice.dart';

class UserPositionMarker extends MarkerByItemDataStore {
  final SymbolCache symbolCache;
  final DisplayModel displayModel;
  final ViewModel viewModel;
  final String assetIcon;
  Pos? position;
  late StreamSubscription gpsSub;
  late StreamSubscription markerSub;

  UserPositionMarker(
      {required this.assetIcon,
      required this.symbolCache,
      required this.displayModel,
      required this.viewModel,
      this.position}) {
    gpsSub = GpsService.observe.listen((pos) {
      position = Pos(pos.latitude, pos.longitude);
      viewModel.updateUserLocation(UserLocation(
          latitude: position!.latitude, longitude: position!.longitude));
    });

    markerSub = viewModel.observeUserLocation.listen((userLocation) {
      position = Pos(userLocation.latitude, userLocation.longitude);
      setRepaint();
    });
  }

  @override
  Future<void> retrieveMarkersFor(BoundingBox boundary, int zoomLevel) async {
    if (position != null) {
      replaceMarker("USER_POSITION", await _createMarker());
      setRepaint();
    }
  }

  Future<BasicMarker> _createMarker() async {
    PoiMarker marker = PoiMarker(
      item: "USER_POSITION",
      displayModel: displayModel,
      latLong: LatLong(position!.lat, position!.lon),
      src: assetIcon,
      width: 45,
      height: 45,
    );
    await marker.initResources(symbolCache);

    return marker;
  }

  @override
  void dispose() {
    super.dispose();
    gpsSub.cancel();
    markerSub.cancel();
  }
}
