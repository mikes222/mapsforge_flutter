import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:test/test.dart';

void main() {
  test('LineSegment', () async {
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(10, 5));
      expect(lineSegment.getTheta(), equals(0));
      expect(lineSegment.getAngle(), equals(0));
      expect(lineSegment.length(), 5);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(8, 5)));
    }
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(10, 10));
      expect(lineSegment.getTheta(), equals(pi / 4));
      expect(lineSegment.getAngle(), equals(45));
      expect(lineSegment.length(), 7.0710678118654755);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(7.121320343559642, 7.121320343559642)));
    }
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(5, 10));
      expect(lineSegment.getTheta(), equals(pi / 2));
      expect(lineSegment.getAngle(), equals(90));
      expect(lineSegment.length(), 5);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(5, 8)));
    }
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(0, 10));
      expect(lineSegment.getTheta(), equals(-pi / 4));
      expect(lineSegment.getAngle(), equals(135));
      expect(lineSegment.length(), 7.0710678118654755);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(2.8786796564403576, 7.121320343559642)));
    }
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(0, 5));
      expect(lineSegment.getTheta(), equals(0));
      expect(lineSegment.getAngle(), equals(180));
      expect(lineSegment.length(), 5);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(2, 5)));
    }
    {
      LineSegment lineSegment = LineSegment(const Mappoint(5, 5), const Mappoint(5, 0));
      expect(lineSegment.getTheta(), equals(-pi / 2));
      expect(lineSegment.getAngle(), equals(270));
      expect(lineSegment.length(), 5);
      expect(lineSegment.pointAlongLineSegment(3), equals(const Mappoint(5, 2)));
    }
  });
}
