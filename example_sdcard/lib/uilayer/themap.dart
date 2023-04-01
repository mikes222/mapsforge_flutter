import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/storage.dart';

/// Show a Mapsforge map using the uri of the map.
class TheMap extends StatefulWidget {
  final String uriString;

  const TheMap({Key? key, required this.uriString}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TheMapState();
}

class _TheMapState extends State<TheMap> {
  MapModel? _mapModel;
  ViewModel? _viewModel;

  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeMap(),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_mapModel != null && _viewModel != null) {
            return FlutterMapView(
              mapModel: _mapModel!,
              viewModel: _viewModel!,
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (errorMessage.isNotEmpty) ...[
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8)
                    ],
                    const Text('No map available'),
                  ],
                ),
              ),
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }),
    );
  }

  @override
  void dispose() {
    _mapModel?.dispose();
    _viewModel?.dispose();

    super.dispose();
  }

  /// Prepare Map for display.
  Future<void> _initializeMap() async {
    final storageHandler = MapsforgeStorage(mapUriString: widget.uriString);

    MapFile mapFile;

    try {
      mapFile = await MapFile.fromsd(storageHandler);
      errorMessage = '';
    } on PlatformException catch (err) {
      errorMessage = err.message ?? '${err.code}: Unexpected error occurred';

      return;
    }

    SymbolCache symbolCache = FileSymbolCache();

    DisplayModel displayModel = DisplayModel();

    RenderTheme renderTheme = await RenderThemeBuilder.create(
      displayModel,
      'lib/assets/render_themes/defaultrender.xml',
    );

    MapDataStoreRenderer jobRenderer =
        MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

    _mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      symbolCache: symbolCache,
    );

    _viewModel = ViewModel(displayModel: displayModel);
    _viewModel!.addOverlay(ZoomOverlay(_viewModel!));
    _viewModel!.addOverlay(DistanceOverlay(_viewModel!));

    final LatLong? startPosition;

    if (mapFile.startPosition == null) {
      final boundingBox = mapFile.boundingBox;
      startPosition = boundingBox.getCenterPoint();
    } else {
      startPosition = LatLong(
          mapFile.startPosition!.latitude, mapFile.startPosition!.longitude);
    }

    _viewModel!
        .setMapViewPosition(startPosition.latitude, startPosition.longitude);

    _viewModel!.setZoomLevel(16);
  }
}
