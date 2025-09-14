/// The size in map pixels
class MapSize {
  final double width;

  final double height;

  const MapSize({required this.width, required this.height});

  const MapSize.empty() : width = 0, height = 0;
}
