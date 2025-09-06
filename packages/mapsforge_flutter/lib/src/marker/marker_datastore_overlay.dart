import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore.dart';
import 'package:mapsforge_flutter/src/marker/marker_datastore_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter/src/util/tile_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// A Flutter widget overlay that renders markers from a [MarkerDatastore] on a map.
///
/// This overlay provides an efficient way to display large numbers of markers by:
/// - Automatically managing marker visibility based on zoom level and viewport
/// - Caching marker queries to minimize datastore requests
/// - Using intelligent bounding box extension to reduce query frequency
/// - Integrating with the map's transformation system for smooth rendering
///
/// The overlay works by:
/// 1. Listening to map position changes via [MapModel.positionStream]
/// 2. Calculating the visible screen area as a [BoundingBox]
/// 3. Extending the bounding box by [extendMargin] to create a buffer zone
/// 4. Requesting markers from the datastore only when needed
/// 5. Rendering markers using [MarkerDatastorePainter] with proper transformations
///
/// ## Performance Optimizations
///
/// - **Zoom Level Caching**: Avoids redundant datastore queries at the same zoom level
/// - **Bounding Box Extension**: Uses [extendMargin] to create a buffer, reducing queries during small map movements
/// - **Conditional Updates**: Only updates markers when the view moves outside the cached bounding box
/// - **Transform Integration**: Leverages [TransformWidget] for efficient coordinate transformations
///
/// ## Usage Example
///
/// ```dart
/// // Create a marker datastore
/// final markerDatastore = DefaultMarkerDatastore();
/// markerDatastore.addMarker(PoiMarker(
///   position: LatLong(52.5200, 13.4050), // Berlin
///   displayName: 'Berlin',
/// ));
///
/// // Add overlay to map
/// Stack(
///   children: [
///     MapsforgeView(mapModel: mapModel),
///     MarkerDatastoreOverlay(
///       mapModel: mapModel,
///       datastore: markerDatastore,
///       zoomlevelRange: ZoomlevelRange(5, 18),
///       extendMargin: 1.5, // 50% buffer around visible area
///     ),
///   ],
/// )
/// ```
///
/// ## Best Practices
///
/// - Use [extendMargin] values between 1.2-2.0 for optimal performance
/// - Implement efficient marker filtering in your datastore based on zoom level
/// - Consider marker clustering for high-density datasets
/// - Use appropriate [ZoomlevelRange] to control marker visibility
///
/// See also:
/// - [MarkerDatastore] for implementing custom marker data sources
/// - [DefaultMarkerDatastore] for a ready-to-use marker container
/// - [SingleMarkerOverlay] for displaying individual markers
class MarkerDatastoreOverlay extends StatefulWidget {
  /// The map model providing position updates and coordinate transformations.
  ///
  /// This model's [MapModel.positionStream] is used to listen for map position
  /// changes and trigger marker updates accordingly.
  final MapModel mapModel;

  /// The marker datastore containing the markers to be displayed.
  ///
  /// The overlay will query this datastore for markers within the visible
  /// area and render them on the map. The datastore should implement
  /// efficient filtering based on zoom level and bounding box.
  final MarkerDatastore datastore;

  /// The zoom level range in which markers should be visible.
  ///
  /// Markers will only be requested and rendered when the current map
  /// zoom level falls within this range. This helps optimize performance
  /// by avoiding marker processing at inappropriate zoom levels.
  final ZoomlevelRange zoomlevelRange;

  /// Margin factor to extend the visible bounding box for marker queries.
  ///
  /// This creates a buffer zone around the visible screen area to reduce
  /// the frequency of datastore queries during map navigation. The value
  /// represents a multiplication factor:
  ///
  /// - `1.0`: No extension (query exact visible area)
  /// - `1.2`: Extend by 20% in all directions (recommended minimum)
  /// - `1.5`: Extend by 50% in all directions (good balance)
  /// - `2.0`: Double the query area (maximum recommended)
  ///
  /// **Performance Impact:**
  /// - Lower values: More frequent queries, less memory usage
  /// - Higher values: Fewer queries, more memory usage
  ///
  /// **Constraints:** Must be >= 1.0
  final double extendMargin;

  /// Creates a marker datastore overlay.
  ///
  /// [mapModel] provides map position updates and transformations
  /// [datastore] contains the markers to display
  /// [zoomlevelRange] defines the zoom levels where markers are visible
  /// [extendMargin] controls the buffer zone size (default: 1.2 = 20% extension)
  ///
  /// Throws [AssertionError] if [extendMargin] < 1.0
  const MarkerDatastoreOverlay({super.key, required this.mapModel, required this.datastore, required this.zoomlevelRange, this.extendMargin = 1.5})
    : assert(extendMargin >= 1.0, 'extendMargin must be >= 1.0');

  @override
  State<MarkerDatastoreOverlay> createState() => _MarkerDatastoreOverlayState();
}

//////////////////////////////////////////////////////////////////////////////

/// Internal state for [MarkerDatastoreOverlay].
///
/// Manages caching of bounding boxes and zoom levels to optimize
/// datastore query frequency and improve rendering performance.
class _MarkerDatastoreOverlayState extends State<MarkerDatastoreOverlay> {
  /// The last bounding box used for marker queries.
  ///
  /// Used to determine if the visible area has moved enough to warrant
  /// a new marker query. Null indicates no previous query has been made.
  BoundingBox? _cachedBoundingBox;

  /// The last zoom level for which markers were requested.
  ///
  /// When the zoom level changes, all markers need to be re-queried
  /// as different markers may be appropriate for different zoom levels.
  /// A value of -1 indicates no previous zoom level has been cached.
  int _cachedZoomlevel = -1;

  @override
  void initState() {
    super.initState();
    widget.mapModel.registerMarkerDatastore(widget.datastore);
  }

  @override
  void dispose() {
    widget.mapModel.unregisterMarkerDatastore(widget.datastore);
    super.dispose();
  }

  /// Called when the widget configuration changes.
  ///
  /// Invalidates cached zoom level if the datastore or zoom level range
  /// has changed, forcing a complete marker refresh on the next build.
  @override
  void didUpdateWidget(covariant MarkerDatastoreOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datastore != widget.datastore || oldWidget.zoomlevelRange != widget.zoomlevelRange) {
      _cachedZoomlevel = -1;
    }
  }

  /// Builds the marker overlay widget.
  ///
  /// Uses [LayoutBuilder] to get screen dimensions and [StreamBuilder] to
  /// listen for map position changes. Implements intelligent caching to
  /// minimize datastore queries while ensuring markers stay current.
  ///
  /// The build process:
  /// 1. Get screen size from layout constraints
  /// 2. Listen to map position stream
  /// 3. Calculate visible bounding box
  /// 4. Check if new marker query is needed
  /// 5. Request markers from datastore if necessary
  /// 6. Render markers using custom painter
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size screensize = constraints.biggest;
        return StreamBuilder(
          stream: widget.mapModel.positionStream,
          builder: (BuildContext context, AsyncSnapshot<MapPosition> snapshot) {
            // Handle stream errors gracefully
            if (snapshot.error != null) {
              return ErrorhelperWidget(error: snapshot.error!, stackTrace: snapshot.stackTrace);
            }
            // Wait for initial position data
            if (snapshot.data == null) {
              return const SizedBox();
            }
            MapPosition position = snapshot.data!;

            // Handle position changes at the same zoom level
            if (_cachedZoomlevel == position.zoomlevel) {
              BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);

              // Check if we've moved outside the cached bounding box
              if (_cachedBoundingBox == null || !_cachedBoundingBox!.containsBoundingBox(boundingBox)) {
                // Extend the bounding box to create a buffer zone
                boundingBox = boundingBox.extendMargin(widget.extendMargin);

                // Request markers for the new area
                widget.datastore.askChangeBoundingBox(_cachedZoomlevel, boundingBox);
                _cachedBoundingBox = boundingBox;
              }
            }
            // Handle zoom level changes
            if (_cachedZoomlevel != position.zoomlevel) {
              if (widget.zoomlevelRange.isWithin(position.zoomlevel)) {
                BoundingBox boundingBox = TileHelper.calculateBoundingBoxOfScreen(mapPosition: position, screensize: screensize);
                boundingBox = boundingBox.extendMargin(widget.extendMargin);

                // Notify datastore of zoom level change - this may trigger
                // marker filtering, clustering, or style changes
                widget.datastore.askChangeZoomlevel(position.zoomlevel, boundingBox, position.projection);

                // Update cache
                _cachedZoomlevel = position.zoomlevel;
                _cachedBoundingBox = boundingBox;
              } else {
                // todo maybe the datastore should be informed that it is not needed for that zoomlevel
                return const SizedBox();
              }
            }
            // Render markers with proper coordinate transformation
            return TransformWidget(
              mapCenter: position.getCenter(),
              mapPosition: position,
              screensize: screensize,
              child: CustomPaint(foregroundPainter: MarkerDatastorePainter(position, widget.datastore), child: const SizedBox.expand()),
            );
          },
        );
      },
    );
  }
}
