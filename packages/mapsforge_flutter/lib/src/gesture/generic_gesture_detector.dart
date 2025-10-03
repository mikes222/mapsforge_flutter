import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';
import 'package:mapsforge_flutter/src/gesture/double_tap_handler.dart';
import 'package:mapsforge_flutter/src/gesture/drag_n_drop_handler.dart';
import 'package:mapsforge_flutter/src/gesture/long_tap_handler.dart';
import 'package:mapsforge_flutter/src/gesture/move_handler.dart';
import 'package:mapsforge_flutter/src/gesture/rotation_handler.dart';
import 'package:mapsforge_flutter/src/gesture/scale_handler.dart';
import 'package:mapsforge_flutter/src/gesture/single_tap_handler.dart';

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
      _createDefaultHandler();
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

  void _createDefaultHandler() {
    _handlers.add(SingleTapHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(LongTapHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(DoubleTapHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(DragNdropHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(MoveHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(RotationHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
    _handlers.add(ScaleHandler(longPressDuration: widget.longPressDuration, mapModel: widget.mapModel));
  }

  void _setSize(Size size) {
    for (var handler in _handlers) {
      handler.setSize(size);
    }
  }
}
