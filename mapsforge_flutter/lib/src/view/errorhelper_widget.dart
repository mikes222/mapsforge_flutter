import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ErrorhelperWidget extends StatelessWidget {
  static final _log = new Logger('ErrorhelperWidget');

  /// The latest error object received by the asynchronous computation.
  ///
  /// If this is non-null, [hasError] will be true.
  ///
  /// If [data] is not null, this will be null.
  final Object error;

  /// The latest stack trace object received by the asynchronous computation.
  ///
  /// This will not be null iff [error] is not null. Consequently, [stackTrace]
  /// will be non-null when [hasError] is true.
  ///
  /// However, even when not null, [stackTrace] might be empty. The stack trace
  /// is empty when there is an error but no stack trace has been provided.
  final StackTrace? stackTrace;

  ErrorhelperWidget({required this.error, this.stackTrace}) {
    _log.warning(error.toString());
    if (stackTrace != null)
    _log.warning(stackTrace.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Text(error.toString(), style: const TextStyle(color: Colors.red));
  }
}
