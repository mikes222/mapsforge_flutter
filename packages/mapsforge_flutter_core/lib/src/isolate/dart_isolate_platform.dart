/// Platform-specific isolate implementation.
///
/// This file conditionally exports the appropriate isolate implementation
/// based on the target platform:
/// - For IO platforms (mobile, desktop): Uses the full implementation with dart:isolate
/// - For web platform: Uses a stub implementation that throws UnsupportedError
export 'dart_isolate_web.dart' if (dart.library.io) 'dart_isolate_io.dart';
