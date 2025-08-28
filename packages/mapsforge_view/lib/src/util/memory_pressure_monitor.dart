import 'dart:async';
import 'dart:io';

/// Monitors system memory pressure. Currently only working for linux machines
class MemoryPressureMonitor {
  static const Duration _defaultMonitoringInterval = Duration(seconds: 5);
  static const double _criticalMemoryThreshold = 0.9; // 90% memory usage
  static const double _highMemoryThreshold = 0.75; // 75% memory usage
  static const double _normalMemoryThreshold = 0.5; // 50% memory usage

  final Duration _monitoringInterval;
  Timer? _monitoringTimer;

  final MemoryStatistics _memoryStatistics = MemoryStatistics();

  // Callbacks for memory pressure events
  final List<Function(MemoryPressureLevel)> _pressureCallbacks = [];

  MemoryPressureLevel _currentPressureLevel = MemoryPressureLevel.normal;

  MemoryPressureMonitor({Duration monitoringInterval = _defaultMonitoringInterval}) : _monitoringInterval = monitoringInterval;

  MemoryStatistics get memoryStatistics => _memoryStatistics;

  /// Starts monitoring memory pressure
  void startMonitoring() {
    if (_monitoringTimer != null) return;

    _updateMemoryStats();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _updateMemoryStats();
      _memoryStatistics._monitoringCycles++;
      _checkMemoryPressure();
    });
  }

  /// Stops monitoring memory pressure
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Adds a callback for memory pressure level changes
  void addPressureCallback(Function(MemoryPressureLevel) callback) {
    _pressureCallbacks.add(callback);
  }

  /// Removes a pressure callback
  void removePressureCallback(Function(MemoryPressureLevel) callback) {
    _pressureCallbacks.remove(callback);
  }

  /// Gets the current memory pressure level
  MemoryPressureLevel get currentPressureLevel => _currentPressureLevel;

  /// Gets the current memory pressure as a percentage (0.0 to 1.0)
  double get memoryPressure => _memoryStatistics._memoryPressure;

  /// Updates memory statistics
  void _updateMemoryStats() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _updateMobileMemoryStats();
      } else if (Platform.isLinux) {
        _updateLinuxMemoryStats();
      } else {
        // Fallback for Windows/macOS
        _updateFallbackMemoryStats();
      }
    } catch (e) {
      // Fallback to estimated values if platform-specific detection fails
      _updateFallbackMemoryStats();
    }
  }

  /// Updates memory stats for mobile platforms
  void _updateMobileMemoryStats() {
    // On mobile platforms, we need to use platform-specific methods
    // For now, we'll use estimated values based on typical mobile memory
    _memoryStatistics._totalSystemMemory = 4 * 1024 * 1024 * 1024; // 4GB typical
    _memoryStatistics._availableMemory = (_memoryStatistics._totalSystemMemory * 0.6).round(); // Estimate 60% available
    _memoryStatistics._usedMemory = _memoryStatistics._totalSystemMemory - _memoryStatistics._availableMemory;
    _memoryStatistics._memoryPressure = _memoryStatistics._usedMemory / _memoryStatistics._totalSystemMemory;
  }

  /// Updates memory stats on Linux by reading /proc/meminfo
  void _updateLinuxMemoryStats() {
    try {
      final File meminfo = File('/proc/meminfo');
      if (meminfo.existsSync()) {
        final String content = meminfo.readAsStringSync();
        final Map<String, int> memData = _parseMeminfo(content);

        _memoryStatistics._totalSystemMemory = (memData['MemTotal'] ?? 0) * 1024; // Convert KB to bytes
        _memoryStatistics._availableMemory = (memData['MemAvailable'] ?? 0) * 1024;
        _memoryStatistics._usedMemory = _memoryStatistics._totalSystemMemory - _memoryStatistics._availableMemory;
        _memoryStatistics._memoryPressure = _memoryStatistics._totalSystemMemory > 0
            ? _memoryStatistics._usedMemory / _memoryStatistics._totalSystemMemory
            : 0.0;
      } else {
        _updateFallbackMemoryStats();
      }
    } catch (e) {
      _updateFallbackMemoryStats();
    }
  }

  /// Fallback memory stats when platform-specific detection fails
  void _updateFallbackMemoryStats() {
    // Use conservative estimates
    _memoryStatistics._totalSystemMemory = 8 * 1024 * 1024 * 1024; // 8GB
    _memoryStatistics._availableMemory = (_memoryStatistics._totalSystemMemory * 0.7).round(); // 70% available
    _memoryStatistics._usedMemory = _memoryStatistics._totalSystemMemory - _memoryStatistics._availableMemory;
    _memoryStatistics._memoryPressure = 0.3; // Assume 30% memory pressure
  }

  /// Parses /proc/meminfo content
  Map<String, int> _parseMeminfo(String content) {
    final Map<String, int> result = {};
    final List<String> lines = content.split('\n');

    for (final String line in lines) {
      if (line.trim().isEmpty) continue;

      final List<String> parts = line.split(':');
      if (parts.length >= 2) {
        final String key = parts[0].trim();
        final String valueStr = parts[1].trim().split(' ')[0];
        final int? value = int.tryParse(valueStr);
        if (value != null) {
          result[key] = value;
        }
      }
    }

    return result;
  }

  /// Checks memory pressure and updates cache size recommendations
  void _checkMemoryPressure() {
    final MemoryPressureLevel newLevel = _calculatePressureLevel();

    if (newLevel != _currentPressureLevel) {
      _currentPressureLevel = newLevel;
      _notifyPressureCallbacks(newLevel);

      if (newLevel == MemoryPressureLevel.critical) {
        _memoryStatistics._lastCriticalPressure = DateTime.now();
      }
      print('Memory pressure level: $newLevel, ${_memoryStatistics.toString()}');
    }
  }

  /// Calculates the current memory pressure level
  MemoryPressureLevel _calculatePressureLevel() {
    if (_memoryStatistics._memoryPressure >= _criticalMemoryThreshold) {
      return MemoryPressureLevel.critical;
    } else if (_memoryStatistics._memoryPressure >= _highMemoryThreshold) {
      return MemoryPressureLevel.high;
    } else if (_memoryStatistics._memoryPressure >= _normalMemoryThreshold) {
      return MemoryPressureLevel.moderate;
    } else {
      return MemoryPressureLevel.normal;
    }
  }

  /// Notifies all registered callbacks about pressure level changes
  void _notifyPressureCallbacks(MemoryPressureLevel level) {
    for (final Function(MemoryPressureLevel) callback in _pressureCallbacks) {
      try {
        callback(level);
      } catch (e) {
        // Ignore callback errors to prevent monitoring disruption
      }
    }
  }

  /// Forces a memory pressure check
  void forceCheck() {
    _updateMemoryStats();
    _checkMemoryPressure();
  }

  /// Disposes the memory pressure monitor
  void dispose() {
    stopMonitoring();
    _pressureCallbacks.clear();
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Represents different levels of memory pressure
enum MemoryPressureLevel {
  normal, // < 50% memory usage
  moderate, // 50-75% memory usage
  high, // 75-90% memory usage
  critical, // > 90% memory usage
}

//////////////////////////////////////////////////////////////////////////////

class MemoryStatistics {
  // Memory statistics
  int _totalSystemMemory = 0;
  int _availableMemory = 0;
  int _usedMemory = 0;
  double _memoryPressure = 0.0;
  // Performance tracking
  int _monitoringCycles = 0;
  DateTime? _lastCriticalPressure;

  int get totalSystemMemory => _totalSystemMemory;

  int get availableMemory => _availableMemory;

  int get usedMemory => _usedMemory;

  double get memoryPressure => _memoryPressure;

  int get monitoringCycles => _monitoringCycles;

  DateTime? get lastCriticalPressure => _lastCriticalPressure;

  @override
  String toString() {
    return 'MemoryStatistics{_totalSystemMemory: $_totalSystemMemory, _availableMemory: $_availableMemory, _usedMemory: $_usedMemory, _memoryPressure: $_memoryPressure, _monitoringCycles: $_monitoringCycles, _lastCriticalPressure: $_lastCriticalPressure}';
  }
}
