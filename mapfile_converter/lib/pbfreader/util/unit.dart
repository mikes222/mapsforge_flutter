import 'dart:math';

final double earthRadius = 6371008.8;

enum Unit {
  Centimeters,
  Degrees,
  Feet,
  Inches,
  Kilometers,
  Meters,
  Miles,
  Millimeters,
  Nauticalmiles,
  Radians,
  Yards
}

final Map<Unit, double> factors = {
  Unit.Centimeters: earthRadius * 100,
  Unit.Degrees: earthRadius / 111325,
  Unit.Feet: earthRadius * 3.28084,
  Unit.Inches: earthRadius * 39.37,
  Unit.Kilometers: earthRadius / 1000,
  Unit.Meters: earthRadius,
  Unit.Miles: earthRadius / 1609.344,
  Unit.Millimeters: earthRadius * 1000,
  Unit.Nauticalmiles: earthRadius / 1852,
  Unit.Radians: 1,
  Unit.Yards: earthRadius / 1.0936,
};

double convertUnit({
  required double value,
  Unit originalUnit = Unit.Degrees,
  Unit finalUnit = Unit.Meters,
}) {
  if (value < 0) {
    return 0;
  }

  return radianToLength(
      radian: lengthToRadian(distance: value, unit: originalUnit),
      unit: finalUnit);
}

/// Converts an angle in degrees to radians
///
/// @param degree: angle between 0 and 360 degrees
/// @return angle in radians
double degreeToRadian({required double degree}) {
  double radian = degree % 360;
  return (radian * pi) / 180;
}

/// Convert a distance measurement (assuming a spherical Earth) from radians to a more friendly unit.
///
/// @param radian: in radians across the sphere
/// @param unit: output unit
///
/// @return distance
double radianToLength({required double radian, Unit unit = Unit.Meters}) {
  return factors[unit]! * radian;
}

/// Convert a distance measurement (assuming a spherical Earth) from a real-world unit into radians
///
/// @param distance in real-world unit
/// @param units real-world unit
/// @returns {number} radians
double lengthToRadian({
  required double distance,
  Unit unit = Unit.Meters,
}) {
  return distance / factors[unit]!;
}
