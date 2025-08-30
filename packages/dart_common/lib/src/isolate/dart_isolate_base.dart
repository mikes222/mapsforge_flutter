/// Base class for isolate operations
/// Provides common functionality for isolate-based calculations
abstract class IsolateBase {
  /// Check if isolate should be used based on data size
  static bool shouldUseIsolate(int dataSize, {int threshold = 1000}) {
    return dataSize >= threshold;
  }
  
  /// Get optimal number of isolates based on available processors
  static int getOptimalIsolateCount() {
    // Default to 4 isolates, can be adjusted based on platform capabilities
    return 4;
  }
}
