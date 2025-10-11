import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/tile/tile_job_queue.dart';
import 'package:mapsforge_flutter/src/tile/tile_set.dart';

class TileEngine extends ChangeNotifier {
  final TileJobQueue _jobQueue;
  TileSet? _tiles;
  late final StreamSubscription<TileSet> _sub;

  TileEngine._(this._jobQueue) {
    _sub = _jobQueue.tileStream.listen((ts) {
      _tiles = ts;
      notifyListeners();
    });
  }

  factory TileEngine.forModel(MapModel model) {
    return TileEngine._(TileJobQueue(mapModel: model));
  }

  TileSet? get tiles => _tiles;

  void setViewport(Size size, double deviceScale) {
    _jobQueue.setSize(size.width * deviceScale, size.height * deviceScale);
  }

  @override
  void dispose() {
    _sub.cancel();
    _jobQueue.dispose();
    super.dispose();
  }
}
