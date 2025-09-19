/// Platform-specific writebuffer implementation.
///
/// This file conditionally exports the appropriate writebuffer implementation
/// based on the target platform:
/// - For IO platforms (mobile, desktop): Uses the full implementation with dart:io
/// - For web platform: Uses a stub implementation that throws UnsupportedError for file operations
///
/// This allows the package to be compatible with web while maintaining full
/// functionality on platforms that support file system operations.

// Conditional exports based on platform
export 'writebuffer_web.dart' if (dart.library.io) 'writebuffer.dart';
