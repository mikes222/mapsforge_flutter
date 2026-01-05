import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';

typedef EventBuilder<T> = Widget Function(BuildContext context, T event);

/// In default StreamBuilder whenever the build-method is recalled we receive the same instance of the old event again. This make sense in many cases
/// but not in all.
class MapsforgeStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;

  final EventBuilder<T> builder;

  const MapsforgeStreamBuilder({super.key, required this.stream, required this.builder});

  @override
  State<MapsforgeStreamBuilder> createState() => _MapsforgeStreamBuilderState<T>();
}

//////////////////////////////////////////////////////////////////////////////

class _MapsforgeStreamBuilderState<T> extends State<MapsforgeStreamBuilder<T>> {
  late final StreamSubscription? _subscription;

  T? _event;

  Object? _error;

  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(
      (event) {
        setState(() {
          _event = event;
          _error = null;
          _stackTrace = null;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
          _event = null;
        });
      },
      onDone: () {
        _event = null;
        _error = null;
        _stackTrace = null;
        // done not used in mapsforge
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapsforgeStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      throw Exception("Stream changed, recreate all overlays if you want to use a different mapModel.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      Widget result = ErrorhelperWidget(error: _error!, stackTrace: _stackTrace);
      _event = null;
      return result;
    }
    T? event = _event;
    if (event == null) return const SizedBox();
    Widget result = widget.builder(context, event);
    _event = null;
    return result;
  }
}
