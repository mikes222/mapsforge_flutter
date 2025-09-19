import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// A widget that displays an error message.
class ErrorhelperWidget extends StatelessWidget {
  static final _log = Logger('ErrorhelperWidget');

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
    if (stackTrace != null) _log.warning(stackTrace.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error.toString(), style: TextStyle(color: Colors.red.shade700)),
        ],
      ),
    );
  }
}
