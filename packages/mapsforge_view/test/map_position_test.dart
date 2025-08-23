import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_view/src/map_position.dart';
import 'package:dart_common/model.dart';

void main() {
  group('MapPosition', () {
    late MapPosition position;
    
    setUp(() {
      position = MapPosition(52.52, 13.41, 10); // Berlin coordinates, zoom level 10
    });

    test('zoomIn increases zoom level by 1', () {
      final newPosition = position.zoomIn();
      expect(newPosition.zoomLevel, equals(position.zoomLevel + 1));
    });

    test('zoomInAround sets new coordinates and increases zoom level', () {
      final newLat = 48.8566; // Paris
      final newLon = 2.3522;
      final newPosition = position.zoomInAround(newLat, newLon);
      
      expect(newPosition.zoomLevel, equals(position.zoomLevel + 1));
      expect(newPosition.latitude, equals(newLat));
      expect(newPosition.longitude, equals(newLon));
    });

    test('zoomOut decreases zoom level by 1, but not below 0', () {
      // Test normal zoom out
      var newPosition = position.zoomOut();
      expect(newPosition.zoomLevel, equals(position.zoomLevel - 1));
      
      // Test zoom out at zoom level 0
      final minZoomPosition = MapPosition(52.52, 13.41, 0);
      newPosition = minZoomPosition.zoomOut();
      expect(newPosition.zoomLevel, equals(0)); // Should not go below 0
    });

    test('zoomTo sets specific zoom level', () {
      final newZoom = 15;
      final newPosition = position.zoomTo(newZoom);
      expect(newPosition.zoomLevel, equals(newZoom));
    });

    test('zoomTo does not set zoom level below 0', () {
      final newPosition = position.zoomTo(-5);
      expect(newPosition.zoomLevel, equals(0));
    });

    test('zoomToAround sets new coordinates and zoom level', () {
      final newLat = 48.8566; // Paris
      final newLon = 2.3522;
      final newZoom = 15;
      final newPosition = position.zoomToAround(newLat, newLon, newZoom);
      
      expect(newPosition.zoomLevel, equals(newZoom));
      expect(newPosition.latitude, equals(newLat));
      expect(newPosition.longitude, equals(newLon));
    });

    test('indoorLevelUp increases indoor level by 1', () {
      final newPosition = position.indoorLevelUp();
      expect(newPosition.indoorLevel, equals(position.indoorLevel + 1));
    });

    test('indoorLevelDown decreases indoor level by 1', () {
      // Start with indoor level 1 to avoid negative levels
      final positionWithIndoor = MapPosition(52.52, 13.41, 10, 1);
      final newPosition = positionWithIndoor.indoorLevelDown();
      expect(newPosition.indoorLevel, equals(0));
    });

    test('withIndoorLevel sets specific indoor level', () {
      final newLevel = 3;
      final newPosition = position.withIndoorLevel(newLevel);
      expect(newPosition.indoorLevel, equals(newLevel));
    });

    test('scaleAround sets new scale and focal point', () {
      final newScale = 2.0;
      final focalPoint = const Offset(100, 100);
      final newPosition = position.scaleAround(focalPoint, newScale);
      
      expect(newPosition.scale, equals(newScale));
      expect(newPosition.focalPoint, equals(focalPoint));
    });

    test('scaleAround throws for non-positive scale', () {
      expect(
        () => position.scaleAround(const Offset(0, 0), 0),
        throwsA(isA<AssertionError>()),
      );
      
      expect(
        () => position.scaleAround(const Offset(0, 0), -1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('moveTo sets new coordinates', () {
      final newLat = 48.8566; // Paris
      final newLon = 2.3522;
      final newPosition = position.moveTo(newLat, newLon);
      
      expect(newPosition.latitude, equals(newLat));
      expect(newPosition.longitude, equals(newLon));
      // Other properties should remain the same
      expect(newPosition.zoomLevel, equals(position.zoomLevel));
      expect(newPosition.indoorLevel, equals(position.indoorLevel));
    });

    test('rotateTo sets specific rotation', () {
      final rotation = 90.0;
      final newPosition = position.rotateTo(rotation);
      
      expect(newPosition.rotation, equals(rotation));
      expect(newPosition.rotationRadian, closeTo(rotation * (3.14159 / 180.0), 0.0001));
    });

    test('rotateTo throws for invalid rotation values', () {
      expect(
        () => position.rotateTo(-1.0),
        throwsA(isA<AssertionError>()),
      );
      
      expect(
        () => position.rotateTo(360.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rotateBy adds to current rotation and normalizes', () {
      // Start with 45 degrees rotation
      final rotatedPosition = position.rotateTo(45.0);
      
      // Rotate by 90 degrees more
      final newPosition = rotatedPosition.rotateBy(90.0);
      
      expect(newPosition.rotation, equals(135.0));
      
      // Test normalization (360° should wrap to 0°)
      final fullRotation = rotatedPosition.rotateBy(315.0); // 45 + 315 = 360
      expect(fullRotation.rotation, equals(0.0));
    });

    test('getCenter returns correct center point', () {
      // This is a simple test - actual projection calculations would be more complex
      final center = position.getCenter();
      expect(center, isNotNull);
      
      // The center should be within the map bounds
      final projection = position.projection;
      expect(center.x, greaterThanOrEqualTo(0.0));
      expect(center.x, lessThanOrEqualTo(projection.mapsize));
      expect(center.y, greaterThanOrEqualTo(0.0));
      expect(center.y, lessThanOrEqualTo(projection.mapsize));
    });
  });
}
