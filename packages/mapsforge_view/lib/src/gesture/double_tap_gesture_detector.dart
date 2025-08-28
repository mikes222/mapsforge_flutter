import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

/// Recognizes double tap gesture and informs [MapModel]
class DoubleTapGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  const DoubleTapGestureDetector({super.key, required this.mapModel});

  @override
  State<DoubleTapGestureDetector> createState() => _DoubleTapGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _DoubleTapGestureDetectorState extends State<DoubleTapGestureDetector> {
  static final _log = Logger('_DoubleTapGestureDetectorState');

  final bool doLog = true;

  late Offset _doubleTapLocalPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTapDown: (TapDownDetails details) {
            if (doLog) {
              _log.info("onDoubleTapDown $details with localPosition ${details.localPosition}");
            }
            _doubleTapLocalPosition = details.localPosition;
          },
          onDoubleTap: () {
            if (doLog) _log.info("onDoubleTap");
            MapPosition? lastPosition = widget.mapModel.lastPosition;
            if (lastPosition == null) return;
            PositionInfo positionInfo = RotateHelper.normalize(lastPosition, constraints.biggest, _doubleTapLocalPosition.dx, _doubleTapLocalPosition.dy);
            // interpolate the new center between the old center and where we
            // pressed now. The new center is half-way between our double-pressed point and the old-center
            TapEvent tapEvent = TapEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              projection: lastPosition.projection,
              mappoint: positionInfo.mappoint,
            );
            widget.mapModel.doubleTap(tapEvent);
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
