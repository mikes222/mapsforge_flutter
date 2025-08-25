import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;

/// Monitors system memory pressure and provides adaptive cache sizing recommendations
class MemoryPressureMonitor {
  static const Duration _defaultMonitoringInterval = Duration(seconds: 5);
  static const double _criticalMemoryThreshold = 0.9; // 90% memory usage
  static const double _highMemoryThreshold = 0.75; // 75% memory usage
  static const double _normalMemoryThreshold = 0.5; // 50% memory usage

  final Duration _monitoringInterval;
  Timer? _monitoringTimer;
  
  // Memory statistics
  int _totalSystemMemory = 0;
  int _availableMemory = 0;
  int _usedMemory = 0;
  double _memoryPressure = 0.0;
  
  // Cache size recommendations
  int _recommendedCacheSize = 1000;
  int _maxCacheSize = 2000;
  int _minCacheSize = 100;
  
  // Callbacks for memory pressure events
  final List<Function(MemoryPressureLevel)> _pressureCallbacks = [];
  MemoryPressureLevel _currentPressureLevel = MemoryPressureLevel.normal;
  
  // Performance tracking
  int _monitoringCycles = 0;
  DateTime? _lastCriticalPressure;
  
  MemoryPressureMonitor({
    Duration monitoringInterval = _defaultMonitoringInterval,
  }) : _monitoringInterval = monitoringInterval;

  /// Starts monitoring memory pressure
  void startMonitoring() {
    if (_monitoringTimer != null) return;
    
    _updateMemoryStats();
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _updateMemoryStats();
      _checkMemoryPressure();
      _monitoringCycles++;
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
  
  /// Gets the current recommended cache size based on memory pressure
  int get recommendedCacheSize => _recommendedCacheSize;
  
  /// Gets the current memory pressure level
  MemoryPressureLevel get currentPressureLevel => _currentPressureLevel;
  
  /// Gets the current memory pressure as a percentage (0.0 to 1.0)
  double get memoryPressure => _memoryPressure;
  
  /// Gets memory statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'totalSystemMemory': _totalSystemMemory,
      'availableMemory': _availableMemory,
      'usedMemory': _usedMemory,
      'memoryPressure': _memoryPressure,
      'pressureLevel': _currentPressureLevel.toString(),
      'recommendedCacheSize': _recommendedCacheSize,
      'monitoringCycles': _monitoringCycles,
      'lastCriticalPressure': _lastCriticalPressure?.toIso8601String(),
    };
  }
  
  /// Updates memory statistics
  void _updateMemoryStats() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _updateMobileMemoryStats();
      } else {
        _updateDesktopMemoryStats();
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
    _totalSystemMemory = 4 * 1024 * 1024 * 1024; // 4GB typical
    _availableMemory = (_totalSystemMemory * 0.6).round(); // Estimate 60% available
    _usedMemory = _totalSystemMemory - _availableMemory;
    _memoryPressure = _usedMemory / _totalSystemMemory;
  }
  
  /// Updates memory stats for desktop platforms
  void _updateDesktopMemoryStats() {
    // On desktop, we can try to read from /proc/meminfo on Linux
    // or use system APIs on Windows/macOS
    if (Platform.isLinux) {
      _updateLinuxMemoryStats();
    } else {
      // Fallback for Windows/macOS
      _updateFallbackMemoryStats();
    }
  }
  
  /// Updates memory stats on Linux by reading /proc/meminfo
  void _updateLinuxMemoryStats() {
    try {
      final File meminfo = File('/proc/meminfo');
      if (meminfo.existsSync()) {
        final String content = meminfo.readAsStringSync();
        final Map<String, int> memData = _parseMeminfo(content);
        
        _totalSystemMemory = (memData['MemTotal'] ?? 0) * 1024; // Convert KB to bytes
        _availableMemory = (memData['MemAvailable'] ?? 0) * 1024;
        _usedMemory = _totalSystemMemory - _availableMemory;
        _memoryPressure = _totalSystemMemory > 0 ? _usedMemory / _totalSystemMemory : 0.0;
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
    _totalSystemMemory = 8 * 1024 * 1024 * 1024; // 8GB
    _availableMemory = (_totalSystemMemory * 0.7).round(); // 70% available
    _usedMemory = _totalSystemMemory - _availableMemory;
    _memoryPressure = 0.3; // Assume 30% memory pressure
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
      _updateCacheSizeRecommendation();
      _notifyPressureCallbacks(newLevel);
      
      if (newLevel == MemoryPressureLevel.critical) {
        _lastCriticalPressure = DateTime.now();
      }
    }
  }
  
  /// Calculates the current memory pressure level
  MemoryPressureLevel _calculatePressureLevel() {
    if (_memoryPressure >= _criticalMemoryThreshold) {
      return MemoryPressureLevel.critical;
    } else if (_memoryPressure >= _highMemoryThreshold) {
      return MemoryPressureLevel.high;
    } else if (_memoryPressure >= _normalMemoryThreshold) {
      return MemoryPressureLevel.moderate;
    } else {
      return MemoryPressureLevel.normal;
    }
  }
  
  /// Updates cache size recommendation based on memory pressure
  void _updateCacheSizeRecommendation() {
    switch (_currentPressureLevel) {
      case MemoryPressureLevel.critical:
        _recommendedCacheSize = _minCacheSize;
        break;
      case MemoryPressureLevel.high:
        _recommendedCacheSize = (_minCacheSize + (_maxCacheSize - _minCacheSize) * 0.25).round();
        break;
      case MemoryPressureLevel.moderate:
        _recommendedCacheSize = (_minCacheSize + (_maxCacheSize - _minCacheSize) * 0.6).round();
        break;
      case MemoryPressureLevel.normal:
        _recommendedCacheSize = _maxCacheSize;
        break;
    }
    
    // Ensure recommendation stays within bounds
    _recommendedCacheSize = Math.max(_minCacheSize, 
        Math.min(_maxCacheSize, _recommendedCacheSize));
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
  
  /// Sets custom cache size limits
  void setCacheSizeLimits({
    required int minSize,
    required int maxSize,
  }) {
    _minCacheSize = Math.max(10, minSize);
    _maxCacheSize = Math.max(_minCacheSize, maxSize);
    _updateCacheSizeRecommendation();
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

/// Represents different levels of memory pressure
enum MemoryPressureLevel {
  normal,    // < 50% memory usage
  moderate,  // 50-75% memory usage  
  high,      // 75-90% memory usage
  critical,  // > 90% memory usage
}

/// Extension methods for MemoryPressureLevel
extension MemoryPressureLevelExtension on MemoryPressureLevel {
  /// Gets a human-readable description of the pressure level
  String get description {
    switch (this) {
      case MemoryPressureLevel.normal:
        return 'Normal memory usage';
      case MemoryPressureLevel.moderate:
        return 'Moderate memory pressure';
      case MemoryPressureLevel.high:
        return 'High memory pressure';
      case MemoryPressureLevel.critical:
        return 'Critical memory pressure';
    }
  }
  
  /// Gets the recommended action for this pressure level
  String get recommendedAction {
    switch (this) {
      case MemoryPressureLevel.normal:
        return 'No action needed';
      case MemoryPressureLevel.moderate:
        return 'Consider reducing cache sizes';
      case MemoryPressureLevel.high:
        return 'Reduce cache sizes and clear unused data';
      case MemoryPressureLevel.critical:
        return 'Immediately clear caches and free memory';
    }
  }
}
