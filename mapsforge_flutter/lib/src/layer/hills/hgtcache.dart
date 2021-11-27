import 'dart:io';
import 'dart:math';

import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/hillshadingbitmap.dart';
import 'package:mapsforge_flutter/src/layer/hills/shadingalgorithm.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';

/**
 * immutably configured, does the work for {@link MemoryCachingHgtReaderTileSource}
 */
class HgtCache {
  final File demFolder;
  final bool interpolatorOverlap;
  final ShadingAlgorithm algorithm;
  final int mainCacheSize;
  final int neighborCacheSize;

//
  final GraphicFactory graphicsFactory;

//
//  Lru secondaryLru;
//  Lru mainLru;
//
////  LazyFuture<Map<TileKey, HgtFileInfo>> hgtFiles;
//
//
//  List<String> problems =  [];
//
  HgtCache(this.demFolder, this.interpolatorOverlap, this.graphicsFactory,
      this.algorithm, this.mainCacheSize, this.neighborCacheSize) {
//    mainLru = new Lru(this.mainCacheSize);
//    secondaryLru = (interpolatorOverlap ? new Lru(neighborCacheSize) : null);
//
//    hgtFiles = new LazyFuture<Map<TileKey, HgtFileInfo>>() {
//      @override
//      Map <TileKey, HgtFileInfo> calculate() {
//        Map<TileKey, HgtFileInfo> map = new Map();
//        Matcher matcher = Pattern.compile(
//            "([ns])(\\d{1,2})([ew])(\\d{1,3})\\.hgt", Pattern.CASE_INSENSITIVE)
//            .matcher("");
//        crawl(HgtCache.this.demFolder, matcher, map, problems);
//        return map;
//      }
//
//      void crawl(File file, Matcher matcher, Map<TileKey, HgtFileInfo> map,
//          List<String> problems) {
//        if (file.exists()) {
//          if (file.isFile()) {
//            String name = file.getName();
//            if (matcher.reset(name).matches()) {
//              int northsouth = int.parse(matcher.group(2));
//              int eastwest = int.parse(matcher.group(4));
//
//              int north = "n".equals(matcher.group(1).toLowerCase())
//                  ? northsouth
//                  : -northsouth;
//              int east = "e".equals(matcher.group(3).toLowerCase())
//                  ? eastwest
//                  : -eastwest;
//
//              int length = file.length();
//              int heights = (length / 2).floor();
//              int sqrt = sqrt(heights);
//              if (sqrt * sqrt != heights) {
//                if (problems != null)
//                  problems.add(file + " length in shorts (" + heights +
//                      ") is not a square number");
//              } else {
//                TileKey tileKey = new TileKey(north, east);
//                HgtFileInfo existing = map.get(tileKey);
//                if (existing == null || existing.size < length) {
////                                hgtFiles.put(tileKey, new HgtFileInfo(file, east, north, east+1, north-1));
//                  map.put(tileKey,
//                      new HgtFileInfo(file, north - 1, east, north, east + 1));
//                }
//              }
//            }
//          } else if (file.isDirectory()) {
//            List<File> files = file.listFiles();
//            if (files != null) {
//              for (File sub in files) {
//                crawl(sub, matcher, map, problems);
//              }
//            }
//          }
//        }
//      }
//    };
  }

  void indexOnThread() {
//    hgtFiles.withRunningThread();
  }

  HillshadingBitmap? getHillshadingBitmap(
      int northInt, int eastInt, double pxPerLat, double pxPerLng) {
//    HgtFileInfo hgtFileInfo = hgtFiles.get().get(
//        new TileKey(northInt, eastInt));
//
//    if (hgtFileInfo == null)
//      return
//        null;
//    Future<HillshadingBitmap> future = hgtFileInfo.getBitmapFuture(
//        pxPerLat, pxPerLng);
//    return future.get();
//  }
//
//  static void mergeSameSized
//      (HillshadingBitmap center, HillshadingBitmap
//  neighbor,
//
//      HillshadingBitmap.Border border, int
//  padding,
//
//      Canvas copyCanvas) {
//    HillshadingBitmap sink;
//    HillshadingBitmap source;
//
//    if (border == Border.EAST) {
//      sink = center;
//      source = neighbor;
//      copyCanvas.setBitmap(sink);
//      copyCanvas.setClip(sink.getWidth() - padding, padding, padding,
//          sink.getHeight() - 2 * padding);
//      copyCanvas.drawBitmap(source, (source.getWidth() - 2 * padding), 0);
//    } else if (border == Border.WEST) {
//      sink = center;
//      source = neighbor;
//      copyCanvas.setBitmap(sink);
//      copyCanvas.setClip(0, padding, padding, sink.getHeight() - 2 * padding);
//      copyCanvas.drawBitmap(source, 2 * padding - (source.getWidth()), 0);
//    } else if (border == Border.NORTH) {
//      sink = center;
//      source = neighbor;
//      copyCanvas.setBitmap(sink);
//      copyCanvas.setClip(padding, 0, sink.getWidth() - 2 * padding, padding);
//      copyCanvas.drawBitmap(source, 0, 2 * padding - (source.getHeight()));
//    } else if (border == Border.SOUTH) {
//      sink = center;
//      source = neighbor;
//      copyCanvas.setBitmap(sink);
//      copyCanvas.setClip(
//          padding, sink.getHeight() - padding, sink.getWidth() - 2 * padding,
//          padding);
//      copyCanvas.drawBitmap(source, 0, (source.getHeight() - 2 * padding));
//    }
    return null;
  }
}

/////////////////////////////////////////////////////////////////////////////

class TileKey {
  final int north;
  final int east;

  bool equals(Object o) {
    if (this == o) return true;
    if (o is! TileKey) return false;

    TileKey tileKey = o;

    return north == tileKey.north && east == tileKey.east;
  }

  TileKey(this.north, this.east);
}

/////////////////////////////////////////////////////////////////////////////

class Lru {
  int size;

//  final LinkedHashSet<Future<HillshadingBitmap>> lru;

  Lru(this.size) {
//    lru = size > 0 ? new LinkedHashSet<Future<HillshadingBitmap>>() : null;
  }

  int getSize() {
    return size;
  }

  void setSize(int size) {
    this.size = max(0, size);

//    if (size < lru.size())
//      synchronized(lru) {
//        Iterator<Future<HillshadingBitmap>> iterator = lru.iterator();
//        while (lru.size() > size) {
//          Future<HillshadingBitmap> evicted = iterator.next();
//          iterator.remove();
//        }
//      }
  }

/**
 * @param freshlyUsed the entry that should be marked as freshly used
 * @return the evicted entry, which is freshlyUsed if size is 0
 */
//  Future<HillshadingBitmap> markUsed(Future<HillshadingBitmap> freshlyUsed) {
//    if (size > 0 && freshlyUsed != null) {
//      synchronized(lru) {
//        lru.remove(freshlyUsed);
//        lru.add(freshlyUsed);
//        if (lru.size() > size) {
//          Iterator<Future<HillshadingBitmap>> iterator = lru.iterator();
//          Future<HillshadingBitmap> evicted = iterator.next();
//          iterator.remove();
//          return evicted;
//        }
//        return null;
//      }
//    }
//    return freshlyUsed;
//  }

//  void evict(Future<HillshadingBitmap> loadingFuture) {
//    if (size > 0) {
//      synchronized(lru) {
//        lru.add(loadingFuture);
//      }
//    }
//  }
}

/////////////////////////////////////////////////////////////////////////////

//class LoadUnmergedFuture extends LazyFuture<HillshadingBitmap> {
//  final HgtFileInfo hgtFileInfo;
//
//  LoadUnmergedFuture(HgtFileInfo hgtFileInfo) {
//    this.hgtFileInfo = hgtFileInfo;
//  }
//
//  HillshadingBitmap calculate() {
//    ShadingAlgorithm.RawShadingResult raw = algorithm.transformToByteBuffer(
//        hgtFileInfo, HgtCache.this.interpolatorOverlap ? 1 : 0);
//
//    // is this really necessary? Maybe, if some downscaling is filtered and rounding is not as expected
//    raw.fillPadding();
//
//    return graphicsFactory.createMonoBitmap(
//        raw.width, raw.height, raw.bytes, raw.padding, hgtFileInfo);
//  }
//}

/////////////////////////////////////////////////////////////////////////////

/* */
//class MergeOverlapFuture extends LazyFuture<HillshadingBitmap> {
//  final LoadUnmergedFuture loadFuture;
//  HgtFileInfo hgtFileInfo;
//
//  MergeOverlapFuture(HgtFileInfo hgtFileInfo, LoadUnmergedFuture loadFuture) {
//    this.hgtFileInfo = hgtFileInfo;
//    this.loadFuture = loadFuture;
//  }
//
//  MergeOverlapFuture(HgtFileInfo hgtFileInfo) {
//    this(hgtFileInfo, new LoadUnmergedFuture(hgtFileInfo));
//  }
//
//  HillshadingBitmap
//
//  calculate() {
//    HillshadingBitmap monoBitmap = loadFuture.get();
//    for (HillshadingBitmap.Border border in HillshadingBitmap.Border.values()) {
//      HgtFileInfo neighbor = hgtFileInfo.getNeighbor(border);
//      mergePaddingOnBitmap(monoBitmap, neighbor, border);
//    }
//    return
//      monoBitmap
//    ;
//  }
//
//  void mergePaddingOnBitmap(HillshadingBitmap fresh, HgtFileInfo neighbor,
//      HillshadingBitmap.Border border) {
//    int padding = fresh.getPadding();
//
//    if (padding < 1) return;
//    if (neighbor != null) {
//      Future<HillshadingBitmap> neighborUnmergedFuture = neighbor
//          .getUnmergedAsMergePartner();
//      if (neighborUnmergedFuture != null) {
//        HillshadingBitmap other = neighborUnmergedFuture.get();
//        Canvas copyCanvas = graphicsFactory.createCanvas();
//
//        mergeSameSized(fresh, other, border, padding, copyCanvas);
//      }
//    }
//  }
//}

/////////////////////////////////////////////////////////////////////////////

class HgtFileInfo extends BoundingBox {
  // , , ShadingAlgorithm.RawHillTileSource {
  final File file;

//  WeakReference<Future<HillshadingBitmap>> weakRef = null;
//
//  final long size;
//
  HgtFileInfo(this.file, double minLatitude, double minLongitude,
      double maxLatitude, double maxLongitude)
      : super(minLatitude, minLongitude, maxLatitude, maxLongitude);
//    this.file = file;
//    size = file.length();

//  Future<HillshadingBitmap> getBitmapFuture(double pxPerLat, double pxPerLng) {
//    if (HgtCache.this.interpolatorOverlap) {
//      int axisLen = algorithm.getAxisLenght(this);
//      if (pxPerLat > axisLen || pxPerLng > axisLen) {
//        return getForHires();
//      } else {
//        return getForLores();
//      }
//    } else {
//      return getForLores();
//    }
//  }
//
//
//  /**
//   * for zoomed in view (if padding): merged or unmerged padding for padding merge of a neighbor
//   *
//   * @return MergeOverlapFuture or LoadUnmergedFuture as available
//   */
//  MergeOverlapFuture getForHires() {
//    final WeakReference<Future<HillshadingBitmap>> weak = this.weakRef;
//    Future<HillshadingBitmap> candidate = weak == null ? null : weak.get();
//
//    final MergeOverlapFuture ret;
//    if (candidate instanceof MergeOverlapFuture) {
//      ret = ((MergeOverlapFuture) candidate);
//    } else if (candidate instanceof LoadUnmergedFuture) {
//      LoadUnmergedFuture loadFuture = (LoadUnmergedFuture) candidate;
//      ret = new MergeOverlapFuture(this, loadFuture);
//      this.weakRef = new WeakReference<Future<HillshadingBitmap>>(ret);
//      secondaryLru.evict(
//          loadFuture); // candidate will henceforth be referenced via created (until created is gone)
//    } else {
//      ret = new MergeOverlapFuture(this);
////logLru("new merged", mainLru, ret);
//      weakRef = new WeakReference<Future<HillshadingBitmap>>(ret);
//    }
//    mainLru.markUsed(ret);
//
////logLru("merged", mainLru, ret);
//    return ret;
//  }
//
//  /**
//   * for zoomed in view (if padding): merged or unmerged padding for padding merge of a neighbor
//   *
//   * @return MergeOverlapFuture or LoadUnmergedFuture as available
//   */
//  LoadUnmergedFuture getUnmergedAsMergePartner() {
//    final WeakReference<Future<HillshadingBitmap>> weak = this.weakRef;
//    Future<HillshadingBitmap> candidate = weak == null ? null : weak.get();
//
//
//    final LoadUnmergedFuture ret;
//    if (candidate instanceof LoadUnmergedFuture) {
//      secondaryLru.markUsed(candidate);
//      ret = (LoadUnmergedFuture) candidate;
//    } else if (candidate instanceof MergeOverlapFuture) {
//      mainLru.markUsed(candidate);
//      ret = ((MergeOverlapFuture) candidate).loadFuture;
//    } else {
//      final LoadUnmergedFuture created = new LoadUnmergedFuture(this);
//      this.weakRef = new WeakReference<Future<HillshadingBitmap>>(created);
//      secondaryLru.markUsed(created);
//      ret = created;
//    }
//    return ret;
//  }
//
//  /**
//   * for zoomed out view (or all resolutions, if no padding): merged or unmerged padding, primary LRU spilling over to secondary (if available)
//   *
//   * @return MergeOverlapFuture or LoadUnmergedFuture as available
//   */
//  Future<HillshadingBitmap> getForLores() {
//    final WeakReference<Future<HillshadingBitmap>> weak = this.weakRef;
//    Future<HillshadingBitmap> candidate = weak == null ? null : weak.get();
//
//    if (candidate == null) {
//      candidate = new LoadUnmergedFuture(this);
//      this.weakRef = new WeakReference<>(candidate);
//    }
//    Future<HillshadingBitmap> evicted = mainLru.markUsed(candidate);
//    if (secondaryLru != null) secondaryLru.markUsed(evicted);
//    return candidate;
//  }
//
//  @Override
//  public HillshadingBitmap
//
//  getFinishedConverted() {
//    WeakReference<Future<HillshadingBitmap>> weak = this.weakRef;
//    if (weak != null) {
//      Future<HillshadingBitmap> hillshadingBitmapFuture = weak.get();
//      if (hillshadingBitmapFuture != null && hillshadingBitmapFuture.isDone()) {
//        try {
//          return hillshadingBitmapFuture.get();
//        }
//    catch
//    (
//    InterruptedException
//    | ExecutionException e) {
//    e.printStackTrace();
//    }
//  }
//  }
//    return
//    null;
//  }
//
//  @Override
//  public long
//
//  getSize() {
//    return size;
//  }
//
//  @Override
//  public File
//
//  getFile() {
//    return file;
//  }
//
//  @Override
//  public double
//
//  northLat() {
//    return maxLatitude;
//  }
//
//  @Override
//  public double
//
//  southLat() {
//    return minLatitude;
//  }
//
//  @Override
//  public double
//
//  westLng() {
//    return minLongitude;
//  }
//
//  @Override
//  public double
//
//  eastLng() {
//    return maxLongitude;
//  }
//
//  HgtFileInfo getNeighbor(HillshadingBitmap.Border border)
//
//  throws ExecutionException, InterruptedException
//
//  {
//
//  Map<TileKey, HgtFileInfo> map = hgtFiles.get();
//
//  switch
//
//  (
//
//  border
//
//  ) {
//  case NORTH:
//  return map.get(new TileKey((int) maxLatitude + 1, (int) minLongitude));
//  case SOUTH:
//  return map.get(new TileKey((int) maxLatitude - 1, (int) minLongitude));
//  case EAST:
//  return map.get(new TileKey((int) maxLatitude, (int) minLongitude + 1));
//  case WEST:
//  return map.get(new TileKey((int) maxLatitude, (int) minLongitude - 1));
//  }
//  return
//
//  null;
//}
//
//@Override
//public String
//
//toString() {
//  Future<HillshadingBitmap> future = weakRef == null ? null : weakRef.get();
//  return "[lt:" + minLatitude + "-" + maxLatitude + " ln:" + minLongitude +
//      "-" + maxLongitude +
//      (future == null ? "" : future.isDone() ? "done" : "wip") + "]";
//}
}

/////////////////////////////////////////////////////////////////////////////
