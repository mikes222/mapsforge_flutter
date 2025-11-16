import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/gesture.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

// todo implement lock for all handlers
class GenericGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// The maximum duration to wait for distinguishing between:
  /// short press: down-up - no further down event
  /// long press: down - no further up event
  /// double press: down - up - down, we do not wait for another up event
  final int longPressDuration;

  final List<DefaultHandler> handlers;

  const GenericGestureDetector({super.key, required this.mapModel, this.longPressDuration = 350, this.handlers = const []});

  @override
  State<GenericGestureDetector> createState() => _GenericGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _GenericGestureDetectorState extends State<GenericGestureDetector> {
  final List<DefaultHandler> _handlers = [];

  final Map<int, Offset> _pointers = {};

  @override
  void initState() {
    super.initState();
    if (widget.handlers.isNotEmpty) {
      _handlers.addAll(widget.handlers);
    } else {
      _handlers.addAll(getDefaultHandlers(widget.longPressDuration, widget.mapModel));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _setSize(constraints.biggest);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            MapPosition? position = widget.mapModel.lastPosition;
            if (position == null) return;
            _pointers[event.pointer] = event.localPosition;
            for (var handler in List.of(_handlers)) {
              handler.onPointerDown(position, event.pointer, event.localPosition, _pointers);
            }
          },
          onPointerMove: (PointerMoveEvent event) {
            _pointers[event.pointer] = event.localPosition;
            for (var handler in List.of(_handlers)) {
              handler.onPointerMove(event.pointer, event.localPosition, _pointers);
            }
          },
          onPointerCancel: (PointerCancelEvent event) {
            _pointers.remove(event.pointer);
            for (var handler in List.of(_handlers)) {
              handler.onPointerCancel(event.pointer, event.localPosition, _pointers);
            }
          },
          onPointerUp: (PointerUpEvent event) {
            _pointers.remove(event.pointer);
            for (var handler in List.of(_handlers)) {
              handler.onPointerUp(event.pointer, event.localPosition, _pointers);
            }
          },
        );
      },
    );
  }

  static List<DefaultHandler> getDefaultHandlers(int longPressDuration, MapModel mapModel) {
    return [
      SingleTapHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      LongTapHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      DoubleTapHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      DragNdropHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      MoveHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      RotationHandler(longPressDuration: longPressDuration, mapModel: mapModel),
      ScaleHandler(longPressDuration: longPressDuration, mapModel: mapModel),
    ];
  }

  void _setSize(Size size) {
    for (var handler in _handlers) {
      handler.setSize(size);
    }
  }
}
