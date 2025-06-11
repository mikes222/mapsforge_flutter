import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_simplify_filter.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_size_filter.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

@pragma("vm:entry-point")
class IsolateSubfileFiller {
  Future<List<Wayholder>> prepareWays(ZoomlevelRange subfileZoomlevelRange, ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders, int tilePixelSize,
      [double maxDeviation = 10]) async {
    return await FlutterIsolateInstance.isolateCompute(
        prepareWaysStatic,
        _SubfileFillerRequest(
            subfileZoomlevelRange: subfileZoomlevelRange,
            zoomlevelRange: zoomlevelRange,
            wayholders: wayholders,
            tilePixelSize: tilePixelSize,
            maxDeviation: maxDeviation));
  }

  @pragma('vm:entry-point')
  static Future<List<Wayholder>> prepareWaysStatic(_SubfileFillerRequest request) async {
    DisplayModel(tilesize: request.tilePixelSize);
    SubfileFiller subfileFiller = SubfileFiller(request.subfileZoomlevelRange, request.maxDeviation);
    return subfileFiller.prepareWays(request.zoomlevelRange, request.wayholders);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SubfileFillerRequest {
  final ZoomlevelRange subfileZoomlevelRange;

  final ZoomlevelRange zoomlevelRange;

  final List<Wayholder> wayholders;

  final int tilePixelSize;

  final double maxDeviation;

  _SubfileFillerRequest(
      {required this.subfileZoomlevelRange, required this.zoomlevelRange, required this.wayholders, required this.tilePixelSize, required this.maxDeviation});
}

//////////////////////////////////////////////////////////////////////////////

class SubfileFiller {
  late WaySizeFilter sizeFilter;

  late WaySimplifyFilter simplifyFilter;

  final ZoomlevelRange subfileZoomlevelRange;

  final double maxDeviation;

  SubfileFiller(this.subfileZoomlevelRange, this.maxDeviation) {
    sizeFilter = WaySizeFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    simplifyFilter = WaySimplifyFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
  }

  List<Wayholder> prepareWays(
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholders,
  ) {
    if (subfileZoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return [];
    if (subfileZoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return [];
    if (maxDeviation <= 0) {
      // we do not want to filter anything, return the original
      return wayholders;
    }
    List<Wayholder> result = [];
    for (Wayholder wayholder in wayholders) {
      Wayholder? res = sizeFilter.filter(wayholder);
      if (res != null) {
        // size is big enough, now simplify the way
        res = simplifyFilter.reduce(res);
        // if the object was so tiny that we can simplify it away, do not store it
        if (res.closedOutersRead.isNotEmpty || res.openOutersRead.isNotEmpty) result.add(res);
      }
    }
    return result;
  }
}
