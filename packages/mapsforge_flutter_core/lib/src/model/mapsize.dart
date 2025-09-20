/// An immutable size in map pixels.
class MapSize {
  final double width;

  final double height;

  /// Creates a new `MapSize`.
  const MapSize({required this.width, required this.height});

  /// Creates a new `MapSize` with zero width and height.
  const MapSize.empty() : width = 0, height = 0;
}
