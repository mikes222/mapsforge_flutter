import 'package:test/test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/src/multimap_datastore.dart';

/// Mock datastore for testing boundary optimization
class MockDatastore extends Datastore {
  final BoundingBox _boundary;
  final String name;
  bool _supportsTileCalled = false;
  bool _readMapDataCalled = false;

  MockDatastore(this.name, this._boundary);

  bool get supportsTileCalled => _supportsTileCalled;
  bool get readMapDataCalled => _readMapDataCalled;

  void resetCallFlags() {
    _supportsTileCalled = false;
    _readMapDataCalled = false;
  }

  @override
  void dispose() {}

  @override
  Future<BoundingBox> getBoundingBox() async {
    return _boundary;
  }

  @override
  Future<bool> supportsTile(Tile tile) async {
    _supportsTileCalled = true;
    // Simulate that this datastore supports tiles within its boundary
    BoundingBox tileBoundary = tile.getBoundingBox();
    return _boundary.intersects(tileBoundary);
  }

  @override
  Future<DatastoreBundle?> readMapDataSingle(Tile tile) async {
    _readMapDataCalled = true;
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }

  @override
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) async {
    _readMapDataCalled = true;
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }

  @override
  Future<DatastoreBundle?> readLabelsSingle(Tile tile) async {
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }

  @override
  Future<DatastoreBundle?> readLabels(Tile upperLeft, Tile lowerRight) async {
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }

  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile) async {
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }

  @override
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    return DatastoreBundle(pointOfInterests: [], ways: []);
  }
}

void main() {
  group('MultimapDatastore Boundary Optimization Tests', () {
    late MultimapDatastore multimap;
    late MockDatastore datastore1;
    late MockDatastore datastore2;
    late MockDatastore datastore3;

    setUp(() async {
      multimap = MultimapDatastore(DataPolicy.RETURN_ALL);
      
      // Create mock datastores with different boundaries
      // Datastore 1: Europe region (approximate)
      datastore1 = MockDatastore(
        'Europe',
        BoundingBox(35.0, -10.0, 70.0, 40.0), // minLat, minLon, maxLat, maxLon
      );
      
      // Datastore 2: North America region (approximate)
      datastore2 = MockDatastore(
        'North America',
        BoundingBox(25.0, -125.0, 60.0, -60.0),
      );
      
      // Datastore 3: Asia region (approximate)
      datastore3 = MockDatastore(
        'Asia',
        BoundingBox(10.0, 60.0, 55.0, 150.0),
      );

      await multimap.addDatastore(datastore1);
      await multimap.addDatastore(datastore2);
      await multimap.addDatastore(datastore3);
    });

    test('should cache datastore boundaries on add', () async {
      expect(multimap.datastoreBoundaries.length, equals(3));
      expect(multimap.datastoreBoundaries.containsKey(datastore1), isTrue);
      expect(multimap.datastoreBoundaries.containsKey(datastore2), isTrue);
      expect(multimap.datastoreBoundaries.containsKey(datastore3), isTrue);
    });

    test('should only query datastores with intersecting boundaries', () async {
      // Reset call flags
      datastore1.resetCallFlags();
      datastore2.resetCallFlags();
      datastore3.resetCallFlags();

      // Create a tile in Europe (should only intersect with datastore1)
      Tile europeTile = Tile(2048, 1365, 12, 0); // Approximately Berlin, Germany at zoom 12
      
      await multimap.readMapDataSingle(europeTile);

      // Only datastore1 should have been queried since the tile is in Europe
      expect(datastore1.supportsTileCalled, isTrue, reason: 'Europe datastore should be queried for European tile');
      expect(datastore2.supportsTileCalled, isFalse, reason: 'North America datastore should NOT be queried for European tile');
      expect(datastore3.supportsTileCalled, isFalse, reason: 'Asia datastore should NOT be queried for European tile');
    });

    test('should query multiple datastores for tiles at boundary intersections', () async {
      // Reset call flags
      datastore1.resetCallFlags();
      datastore2.resetCallFlags();
      datastore3.resetCallFlags();

      // Create a tile that intersects with Europe (datastore1)
      // Using coordinates that should fall within Europe boundary (35.0, -10.0, 70.0, 40.0)
      Tile europeTile = Tile(1050, 680, 11, 0); // Should be in Europe region at zoom 11
      
      await multimap.readMapDataSingle(europeTile);

      // At least datastore1 should be queried since the tile is in Europe
      expect(datastore1.supportsTileCalled, isTrue, reason: 'Europe datastore should be queried for European tile');
    });

    test('should handle datastore removal and boundary cleanup', () async {
      expect(multimap.datastoreBoundaries.length, equals(3));
      
      // Remove datastore covering Europe region
      await multimap.removeDatastore(35.0, -10.0, 70.0, 40.0);
      
      // Datastore1 should be removed from both lists
      expect(multimap.datastores.contains(datastore1), isFalse);
      expect(multimap.datastoreBoundaries.containsKey(datastore1), isFalse);
      expect(multimap.datastoreBoundaries.length, equals(2));
    });

    test('should clear all boundaries when removing all datastores', () async {
      expect(multimap.datastoreBoundaries.length, equals(3));
      
      multimap.removeAllDatastores();
      
      expect(multimap.datastores.length, equals(0));
      expect(multimap.datastoreBoundaries.length, equals(0));
    });

    test('should optimize supportsTile calls with boundary checking', () async {
      // Reset call flags
      datastore1.resetCallFlags();
      datastore2.resetCallFlags();
      datastore3.resetCallFlags();

      // Create a tile in Europe
      Tile europeTile = Tile(2048, 1365, 12, 0);
      
      bool supports = await multimap.supportsTile(europeTile);

      // Should return true if any datastore supports the tile
      expect(supports, isTrue);
      
      // Only relevant datastores should be queried
      expect(datastore1.supportsTileCalled, isTrue);
      // Other datastores should not be queried due to boundary optimization
      expect(datastore2.supportsTileCalled, isFalse);
      expect(datastore3.supportsTileCalled, isFalse);
    });

    test('should handle getBoundingBox with cached boundaries', () async {
      BoundingBox overallBoundary = await multimap.getBoundingBox();
      
      // The overall boundary should encompass all datastore boundaries
      expect(overallBoundary, isNotNull);
      
      // Should include parts of all three regions
      expect(overallBoundary.minLatitude, lessThanOrEqualTo(10.0)); // Asia's min
      expect(overallBoundary.maxLatitude, greaterThanOrEqualTo(70.0)); // Europe's max
      expect(overallBoundary.minLongitude, lessThanOrEqualTo(-125.0)); // North America's min
      expect(overallBoundary.maxLongitude, greaterThanOrEqualTo(150.0)); // Asia's max
    });
  });
}
