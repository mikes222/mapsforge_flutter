import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/filter.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/boundary_filter.dart';
import 'package:test/test.dart';

class _WayholderSnapshot {
  final List<List<ILatLong>> inner;
  final List<List<ILatLong>> closedOuters;
  final List<List<ILatLong>> openOuters;

  _WayholderSnapshot({required this.inner, required this.closedOuters, required this.openOuters});
}

_WayholderSnapshot _snapshotWayholder(Wayholder wayholder) {
  List<List<ILatLong>> snap(List<Waypath> paths) => paths.map((p) => List<ILatLong>.from(p.path)).toList();

  return _WayholderSnapshot(inner: snap(wayholder.innerRead), closedOuters: snap(wayholder.closedOutersRead), openOuters: snap(wayholder.openOutersRead));
}

void _expectWayholderUnchanged(Wayholder original, _WayholderSnapshot snapshot) {
  const eq = DeepCollectionEquality();
  expect(eq.equals(original.innerRead.map((p) => p.path).toList(), snapshot.inner), isTrue);
  expect(eq.equals(original.closedOutersRead.map((p) => p.path).toList(), snapshot.closedOuters), isTrue);
  expect(eq.equals(original.openOutersRead.map((p) => p.path).toList(), snapshot.openOuters), isTrue);
}

Wayholder _createWayholder({required List<Waypath> closedOuters, List<Waypath> openOuters = const [], List<Waypath> inner = const []}) {
  Wayholder w = Wayholder(tagholderCollection: TagholderCollection.fromWay({'highway': 'residential'}));
  w.closedOutersAddAll(closedOuters);
  if (openOuters.isNotEmpty) w.openOutersAddAll(openOuters);
  if (inner.isNotEmpty) w.innerAddAll(inner);
  return w;
}

Waypath _square(double minLat, double minLon, double maxLat, double maxLon) {
  return Waypath(path: [LatLong(maxLat, minLon), LatLong(maxLat, maxLon), LatLong(minLat, maxLon), LatLong(minLat, minLon), LatLong(maxLat, minLon)]);
}

Waypath _polyline(List<ILatLong> pts) => Waypath(path: pts);

void main() {
  group('WaySizeFilter immutability', () {
    test('filter() does not mutate input and returns new Wayholder when filtering happens', () {
      Waypath big = _square(0, 0, 10, 10);
      Waypath tiny = _square(0, 0, 0.000001, 0.000001);
      Wayholder original = _createWayholder(closedOuters: [big, tiny]);

      final snap = _snapshotWayholder(original);

      WaySizeFilter filter = WaySizeFilter(10, 100); // big pixel threshold => filters tiny
      Wayholder? result = filter.filter(original);

      expect(result, isNotNull);
      expect(identical(result, original), isFalse);

      _expectWayholderUnchanged(original, snap);
    });

    test('filter() returns original Wayholder when nothing is filtered', () {
      Waypath big = _square(0, 0, 10, 10);
      Wayholder original = _createWayholder(closedOuters: [big]);
      final snap = _snapshotWayholder(original);

      WaySizeFilter filter = WaySizeFilter(10, 0.0000001);
      Wayholder? result = filter.filter(original);

      expect(identical(result, original), isTrue);
      _expectWayholderUnchanged(original, snap);
    });
  });

  group('WaySimplifyFilter immutability', () {
    test('reduce() does not mutate input and does not share Waypath instances', () {
      // A polyline with many points (force simplification).
      List<ILatLong> pts = List.generate(20, (i) => LatLong(0, i.toDouble()));
      Waypath longLine = _polyline(pts);
      Waypath shortLine = _polyline([LatLong(0, 0), LatLong(0, 1), LatLong(0, 2)]);
      Wayholder original = _createWayholder(openOuters: [longLine, shortLine], closedOuters: []);

      final snap = _snapshotWayholder(original);

      WaySimplifyFilter filter = WaySimplifyFilter(10, 2);
      Wayholder? result = filter.reduce(original);

      expect(identical(result, original), isFalse);
      _expectWayholderUnchanged(original, snap);
    });
  });

  group('WayCropper immutability', () {
    test('cropWay() does not mutate input and does not share Waypath instances', () {
      Waypath area = _square(0, 0, 10, 10);
      Wayholder original = _createWayholder(closedOuters: [area]);
      final snap = _snapshotWayholder(original);

      // Crop to a smaller box in the middle.
      BoundingBox tile = const BoundingBox(2, 2, 8, 8);
      WayCropper cropper = const WayCropper();
      Wayholder? result = cropper.cropWay(original, tile, 10);

      expect(result, isNotNull);
      expect(identical(result, original), isFalse);
      _expectWayholderUnchanged(original, snap);

      for (final wp in result!.closedOutersRead) {
        expect(original.closedOutersRead.any((o) => identical(o, wp)), isFalse);
      }
    });

    test('cropWay() returns null when nothing intersects and still does not mutate input', () {
      Waypath area = _square(0, 0, 1, 1);
      Wayholder original = _createWayholder(closedOuters: [area]);
      final snap = _snapshotWayholder(original);

      BoundingBox tile = const BoundingBox(10, 10, 11, 11);
      WayCropper cropper = const WayCropper();
      Wayholder? result = cropper.cropWay(original, tile, 10);

      expect(result, isNull);
      _expectWayholderUnchanged(original, snap);
    });
  });

  group('BoundaryFilter immutability (Wayholder paths)', () {
    test('filter() does not mutate Wayholder paths', () async {
      Waypath area = _square(0, 0, 10, 10);
      Wayholder originalWay = _createWayholder(closedOuters: [area]);
      final waySnap = _snapshotWayholder(originalWay);

      PoiWayCollections collections = PoiWayCollections();
      IWayholderCollection whc = WayholderCollection();
      whc.add(originalWay);
      collections.wayholderCollections[0] = whc;

      BoundaryFilter filter = BoundaryFilter();
      BoundingBox tile = const BoundingBox(5, 5, 6, 6);
      PoiWayCollections res = await filter.filter(collections, tile);

      expect(res.wayholderCollections[0]!.length, 1);
      _expectWayholderUnchanged(originalWay, waySnap);
    });
  });
}
