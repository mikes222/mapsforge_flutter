
# Markers

Markers are an easy way to draw shapes or labels on top of the map. 

## Polyline Markers

Polyline markers draw lines and OPEN paths between coordinates. It also supports adding/removing nodes from the path

    marker = PolylineMarker(
      path: [
        LatLong(latitude, longitude),
        LatLong(latitude + 0.001, longitude + 0.001),
      ],
    );


```dart
final polylineMarker = PolylineMarker<String>(
  key: "route_1",
  path: [
    LatLong(52.5200, 13.4050),
    LatLong(52.5250, 13.4100),
    LatLong(52.5300, 13.4150),
  ],
  strokeColor: 0xFF0000FF, // Blue line
  strokeWidth: 4.0,
  strokeDasharray: [10.0, 5.0], // Dashed line pattern
  zoomlevelRange: ZoomlevelRange(10, 18),
);
```


## PolylineTextMarker

Draws a text along the given path. Supports open and closed paths. 

    marker = PolylineTextMarker(
      path: [
        LatLong(latitude, longitude),
        LatLong(latitude + 0.001, longitude + 0.001),
        LatLong(latitude, longitude + 0.001),
      ],
      caption: "PolylineTextMarker",
      fontSize: 20,
    );


## Area Markers

Area markers render CLOSED polygon shapes defined by coordinate paths.

    marker = AreaMarker(
      key: "area",
      path: [
        LatLong(latitude, longitude),
        LatLong(latitude + 0.001, longitude + 0.001),
        LatLong(latitude, longitude + 0.001),
        LatLong(latitude, longitude),
      ],
    );

```dart
final areaMarker = AreaMarker<String>(
  key: "park_area",
  path: [
    LatLong(52.5200, 13.4050),
    LatLong(52.5210, 13.4060),
    LatLong(52.5190, 13.4070),
    LatLong(52.5180, 13.4040),
  ],
  fillColor: 0x8000FF00, // Semi-transparent green
  strokeColor: 0xFF008000, // Dark green border
  strokeWidth: 2.0,
  zoomlevelRange: ZoomlevelRange(8, 15),
);
```

## RectMarker

Rectangle defined by two lat/lon coordinates.
Optionally supports captions in the center of the rectangle.

    marker = RectMarker(
      minLatLon: LatLong(latitude, longitude),
      maxLatLon: LatLong(latitude + 0.001, longitude + 0.001),
    )..addCaption(caption: "RectCaption");

## Caption Markers

Caption markers display text labels at specific locations.

    marker = CaptionMarker(
      latLong: LatLong(latitude, longitude),
      caption: 'PoiCaption',
    );


```dart
final captionMarker = CaptionMarker<String>(
  key: "label_1",
  latLong: LatLong(52.5200, 13.4050),
  text: "Berlin",
  fontSize: 16.0,
  fontColor: 0xFF000000,
  strokeColor: 0xFFFFFFFF, // White outline
  strokeWidth: 1.0,
  positioning: MapPositioning.CENTER,
  zoomlevelRange: ZoomlevelRange(8, 16),
);
```


## Circle Markers

Circle markers create circular shapes with customizable fill and stroke at a specified lat/lon coordinate.
Optionally supports captions around the icon.

    marker = CircleMarker(
      latLong: LatLong(latitude, longitude),
      fillColor: Colors.white.withAlpha(200).toARGB32(),
    )..addCaption(caption: "IconMarker");


```dart
final circleMarker = CircleMarker<String>(
  key: "location_1",
  latLong: LatLong(52.5200, 13.4050),
  radius: 50, // radius in pixels
  fillColor: 0x80FF0000, // Semi-transparent red
  strokeColor: 0xFF000000, // Black border
  strokeWidth: 2.0,
  position: MapPositioning.CENTER,
  zoomlevelRange: ZoomlevelRange(10, 16),
);
```


## IconMarker

Shows a flutter icon from IconData at a specified lat/lon coordinate.
Optionally supports captions around the icon.

    marker = IconMarker(
      latLong: LatLong(latitude, longitude),
      iconData: Icons.accessibility,
    )..addCaption(caption: "IconMarker");

## Point of Interest (POI) Markers

POI markers display icons or symbols (svg or png format) at specific geographic locations.
Shows an icon from a  file at a specified lat/lon coordinate.
Optionally supports captions around the icon.

    marker = PoiMarker(
      src: "packages/mapsforge_flutter_rendertheme/assets/symbols/viewpoint.svg",
      latLong: LatLong(latitude, longitude),
      rotateWithMap: true,
    )..addCaption(caption: "PoiMarker");

    markerDatastore.addMarker(marker);


```dart
// Create a POI marker with custom icon
final poiMarker = PoiMarker<String>(
  key: "restaurant_1",
  latLong: LatLong(52.5200, 13.4050),
  src: "assets/icons/restaurant.png",
  width: 32,
  height: 32,
  positioning: MapPositioning.CENTER,
  rotateWithMap: false,
  rotation: 0, // degrees clockwise
  zoomlevelRange: ZoomlevelRange(12, 18),
);
```

# Marker Management

## Display Markers

```dart
// Add to marker datastore
final markerDatastore = DefaultMarkerDatastore();
markerDatastore.addMarker(poiMarker);

// Add to your map stack
Stack(
  children: [
    MapsforgeView(mapModel: mapModel),
    MarkerDatastoreOverlay(markerDatastore: markerDatastore),
  ],
)
```

## Query markers which are tapped

MapModel.getTappedMarkers()

## Working with markers

Markers can be removed/added/changed while they are displayed. The changes will trigger a rebuild of the map automatically. 

```dart
// Create marker datastore
final markerDatastore = DefaultMarkerDatastore();

// Add multiple markers
markerDatastore.addMarker(poiMarker);
markerDatastore.addMarker(circleMarker);
markerDatastore.addMarker(areaMarker);

// Remove markers
markerDatastore.removeMarker(poiMarker);

// Clear all markers
markerDatastore.clearMarkers();
```

Datastores also supports querying data from external sources like databases or webcalls. 

Create your own datastore by implementing the MarkerDatastore interface. Listen to the ``askChangeZoomlevel`` and ``askChangeBoundingBox`` methods. 
Request the new data and call ``requestRepaint()`` afterwards to trigger a repaint as soon as the new markers are available.

## Finding tapped markers

Listen to one of the tap-events of mapModel:

```dart
mapModel.tapStream.listen(...);
```

Doing this in the datastore may be an efficient way to deal only with markers bound to this datastore. In the ``listen()`` method just find the tapped markers with

```dart
List<Marker<T>> getTappedMarkers(TapEvent event);
```

which is a method of ``DefaultMarkerDatastore``

You could also find all tapped markers via MapModel:

```dart
mapModel.getTappedMarkers(TapEvent event);
```

Note: The builder for the context menu also receives a TapEvent so in the context menu you can find all tapped events with this method. 

