# Mapsforge Flutter Performance Guide

This guide provides comprehensive performance optimization strategies for Mapsforge Flutter applications, covering configuration, architecture decisions, and recent optimizations.

## Table of Contents

1. [Quick Performance Wins](#quick-performance-wins)
2. [Rendering Performance](#rendering-performance)
3. [Memory Management](#memory-management)
4. [Concurrency and Threading](#concurrency-and-threading)
5. [Task Queue Optimizations](#task-queue-optimizations)
6. [Spatial Indexing](#spatial-indexing)
7. [Caching Strategies](#caching-strategies)
8. [Performance Monitoring](#performance-monitoring)
9. [Troubleshooting](#troubleshooting)

---

## Quick Performance Wins

### Device Scale Factor Optimization

The scale factor directly impacts tile generation and rendering performance. Fewer tiles mean less work but lower visual quality.

```dart
// Automatic device-appropriate scaling
double ratio = MediaQuery.devicePixelRatioOf(context);
MapsforgeSettingsMgr().setDeviceScaleFactor(ratio);

// Manual optimization for performance vs quality trade-off
MapsforgeSettingsMgr().setDeviceScaleFactor(1.0); // Better performance
MapsforgeSettingsMgr().setDeviceScaleFactor(2.0); // Better quality
```

**Performance Impact**: 25-40% improvement with lower scale factors.

### Isolate Configuration

Mapsforge supports two types of isolates for CPU-intensive operations. **Choose one approach - they cannot be used together.**

#### Option 1: DatastoreReader Isolates (Recommended for most cases)

```dart
// Without isolate
var renderer = DatastoreRenderer(datastore, rendertheme, false);

// With isolate
var renderer = DatastoreRenderer(datastore, rendertheme, false, useIsolateReader: true);
```

#### Option 1: Mapfile Isolates (For complex scenarios)

```dart
// Without isolate (blocking main thread)
var datastore = await Mapfile.createFromFile(filename: filename);

// With isolate (non-blocking)
var datastore = await IsolateMapfile.createFromFile(filename: filename);
```

**When to use Mapfile isolates:**
- MultiMapDatastores with different configurations
- Runtime datastore modifications

**Performance Impact**: 30-50% UI responsiveness improvement.

---

## Memory Management

Memory management is currently fully automatic.

---

## Concurrency and Threading

### Task Queue Performance

The task queue system has been completely optimized:

### Parallel Processing Guidelines

```dart
// For CPU-intensive operations
await Future.wait([
  processMapData(),
  loadTileData(),
  renderSymbols(),
]);

// For I/O operations with controlled concurrency
final semaphore = Semaphore(4); // Limit to 4 concurrent operations
await Future.wait(files.map((file) => 
  semaphore.acquire().then((_) => 
    processFile(file).whenComplete(() => semaphore.release())
  )
));
```

---

## Spatial Indexing

### Grid-Based Collision Detection

The spatial indexing system provides O(log n) collision detection:

```dart
// Configure spatial index
SpatialIndex spatialIndex = SpatialIndex(cellSize: 64);

// Add items with boundaries
spatialIndex.addItem(item, boundary);

// Efficient collision detection
List<Item> collisions = spatialIndex.findCollisions(targetBoundary);

// Performance monitoring
print('Grid efficiency: ${spatialIndex.getStatistics()}');
```

**Performance Impact**: 60-80% improvement in collision detection for large datasets.

---

## Performance Monitoring

### Built-in Performance Panel

The `complete_example` app includes comprehensive performance monitoring:

1. **Access Performance Panel**: Click the analytics icon (📊) in the upper right corner
2. **View Real-time Metrics**: Monitor FPS, memory usage, render times
3. **Copy Performance Data**: Long-click any metric to copy to clipboard
4. **Export Performance Logs**: Generate detailed performance reports

### Key Performance Metrics

Monitor these critical metrics:

- **Frame Rate**: Target 60 FPS for smooth interaction
- **Tile Load Time**: Should be <100ms for visible tiles
- **Memory Usage**: Monitor for memory leaks and excessive allocation
- **Task Queue Length**: Should remain low (<10 pending tasks)
- **Cache Hit Rate**: Target >80% for optimal performance

---

## Troubleshooting

### Common Performance Issues

#### 3. UI Freezing

```dart
// Symptoms: Unresponsive interface during map operations
// Solutions:
- Enable isolates for CPU-intensive operations
- Implement proper async/await patterns
- Reduce concurrent operations
```

#### 4. Poor Rendering Performance

```dart
// Symptoms: Low FPS, stuttering during zoom/pan
// Solutions:
- Optimize shape painter creation (automatic with recent updates)
- Use spatial indexing for collision detection
- Implement efficient caching strategies
- Profile and optimize custom rendering code
```

### Development Best Practices

1. **Profile Early**: Use the performance panel during development
2. **Test on Target Devices**: Performance varies significantly across devices
3. **Monitor Memory**: Watch for memory leaks and excessive allocation
4. **Optimize Incrementally**: Make one change at a time and measure impact
5. **Use Appropriate Tools**: Leverage isolates, caching, and optimized data structures

---

## Recent Performance Improvements

### 2025 Optimizations Summary

- **Task Queue System**: 99% performance improvement with new implementations
- **Shape Painter Creation**: 97.9% improvement using Completer pattern
- **Spatial Indexing**: 60-80% improvement in collision detection
- **Memory Management**: Object pooling reduces GC pressure by 40-60%
- **Comprehensive Monitoring**: Real-time performance metrics and statistics

These optimizations are automatically applied when using the latest version - no code changes required for most improvements. 


## Performance Considerations

### Marker Performance
- Use appropriate zoom level ranges to limit marker visibility
- Implement clustering for large marker sets (>1000 markers)
- Consider marker pooling for frequently updated markers
- Use efficient marker datastores for large datasets

### Overlay Performance
- Overlays are rendered on every frame during interactions
- Keep overlay rendering lightweight
- Use animation controllers for smooth transitions
- Implement proper disposal to prevent memory leaks

### Memory Management
- Dispose of markers and overlays when no longer needed
- Use weak references for large marker collections
- Implement efficient caching strategies
- Monitor memory usage with large datasets

