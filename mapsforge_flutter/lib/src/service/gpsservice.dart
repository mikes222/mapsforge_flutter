import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

class GpsService {
  static final Subject<Position> _inject = BehaviorSubject<Position>();

  static Stream<Position> get observe => _inject.stream;

  StreamSubscription<Position>? gpsStream;

  Position? get lastPos {
    return _lastPos;
  }

  Position? _lastPos;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high)
        .then((pos) {
      _lastPos = pos;
      _inject.add(_lastPos!);
      return _lastPos!;
    }).catchError((e) {
      print('Error getting location: $e');
      throw e;
    });
  }

  void startPositioning() {
    if (gpsStream != null) {
      return;
    }
    gpsStream = Geolocator.getPositionStream().listen((event) {
      _lastPos = event;
      _inject.add(event);
    }, onError: (e) {
      print('Error in position stream: $e');
    });
  }

  void stopPositioning() {
    if (gpsStream == null) {
      return;
    }
    gpsStream!.cancel();
    gpsStream = null;
  }
}
