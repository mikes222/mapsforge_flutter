import 'package:flutter/cupertino.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/label_view.dart';

class MapsforgeView extends StatelessWidget {
  final MapModel mapModel;

  const MapsforgeView({super.key, required this.mapModel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TileView(mapModel: mapModel),
        LabelView(mapModel: mapModel),
      ],
    );
  }
}
