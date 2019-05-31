class MapViewPosition {
  final double latitude;

  final double longitude;

  final int zoomLevel;

  MapViewPosition(this.latitude, this.longitude, this.zoomLevel);

  MapViewPosition.zoomIn(MapViewPosition old)
      : latitude = old.latitude,
        longitude = old.longitude,
        zoomLevel = old.zoomLevel + 1;
}
