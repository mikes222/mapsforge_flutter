import 'dart:async';

import 'package:test/test.dart';

/// Simple performance test demonstrating the optimization
void main() {
  group('Painter Creation Performance', () {
    test('Future-based memoization vs TaskQueue approach', () async {
      const concurrentCalls = 50;
      
      // Simulate the old TaskQueue approach
      final oldApproachResults = await _testTaskQueueApproach(concurrentCalls);
      
      // Simulate the new Future-based approach  
      final newApproachResults = await _testFutureBasedApproach(concurrentCalls);
      
      print('Performance Comparison ($concurrentCalls concurrent calls):');
      print('TaskQueue approach: ${oldApproachResults.duration}ms, ${oldApproachResults.creationCount} creations');
      print('Future-based approach: ${newApproachResults.duration}ms, ${newApproachResults.creationCount} creations');
      print('Improvement: ${((oldApproachResults.duration - newApproachResults.duration) / oldApproachResults.duration * 100).toStringAsFixed(1)}%');
      
      // Both should create exactly once
      expect(oldApproachResults.creationCount, equals(1));
      expect(newApproachResults.creationCount, equals(1));
      
      // New approach should be faster
      expect(newApproachResults.duration, lessThan(oldApproachResults.duration));
    });
  });
}

class TestResult {
  final int duration;
  final int creationCount;
  TestResult(this.duration, this.creationCount);
}

/// Simulates the old TaskQueue-based approach
Future<TestResult> _testTaskQueueApproach(int concurrentCalls) async {
  final taskQueueSimulator = TaskQueueSimulator();
  int creationCount = 0;
  
  final stopwatch = Stopwatch()..start();
  
  final futures = List.generate(concurrentCalls, (index) {
    return taskQueueSimulator.add(() async {
      creationCount++;
      await Future.delayed(Duration(milliseconds: 5));
      return 'painter_$index';
    });
  });
  
  await Future.wait(futures);
  stopwatch.stop();
  
  return TestResult(stopwatch.elapsedMilliseconds, creationCount);
}

/// Simulates the new Future-based approach
Future<TestResult> _testFutureBasedApproach(int concurrentCalls) async {
  final futureBasedSimulator = FutureBasedSimulator();
  int creationCount = 0;
  
  final stopwatch = Stopwatch()..start();
  
  final futures = List.generate(concurrentCalls, (index) {
    return futureBasedSimulator.createOnce(() async {
      creationCount++;
      await Future.delayed(Duration(milliseconds: 5));
      return 'painter_$index';
    });
  });
  
  await Future.wait(futures);
  stopwatch.stop();
  
  return TestResult(stopwatch.elapsedMilliseconds, creationCount);
}

/// Simulates TaskQueue behavior (sequential processing)
class TaskQueueSimulator {
  final List<Future Function()> _queue = [];
  bool _isProcessing = false;
  
  Future<T> add<T>(Future<T> Function() task) async {
    final completer = Completer<T>();
    
    _queue.add(() async {
      try {
        final result = await task();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    
    _processQueue();
    return completer.future;
  }
  
  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    
    _isProcessing = true;
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      await task();
    }
    _isProcessing = false;
  }
}

/// Simulates the new Future-based approach
class FutureBasedSimulator {
  String? _result;
  Future<String>? _creationFuture;
  
  Future<String> createOnce(Future<String> Function() factory) async {
    // Fast path: already created
    if (_result != null) return _result!;
    
    // If creation in progress, return existing future
    if (_creationFuture != null) return _creationFuture!;
    
    // Start creation
    _creationFuture = _createOnce(factory);
    return _creationFuture!;
  }
  
  Future<String> _createOnce(Future<String> Function() factory) async {
    try {
      if (_result != null) return _result!;
      
      _result = await factory();
      return _result!;
    } finally {
      _creationFuture = null;
    }
  }
}
