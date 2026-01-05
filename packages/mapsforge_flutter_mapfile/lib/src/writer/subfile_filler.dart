import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/filter.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

abstract class ISubfileFiller {
  /// Prepares a list of ways by filtering and simplifying them.
  Future<List<Wayholder>> prepareWays(IWayholderCollection wayholderCollection);
}

/// An isolate-based wrapper for [SubfileFiller] to perform way preparation
/// in the background.
@pragma("vm:entry-point")
class IsolateSubfileFiller implements ISubfileFiller {
  final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateSubfileFiller._();

  static Future<IsolateSubfileFiller> create({
    required ZoomlevelRange subfileZoomlevelRange,
    required BoundingBox boundingBox,
    required double maxDeviation,
  }) async {
    SubfileFillerInstanceRequest request = SubfileFillerInstanceRequest(
      subfileZoomlevelRange: subfileZoomlevelRange,
      boundingBox: boundingBox,
      maxDeviation: maxDeviation,
    );
    IsolateSubfileFiller instance = IsolateSubfileFiller._();
    await instance._isolateInstance.spawn(createInstance, request);
    return instance;
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static SubfileFiller? _pbfReader;

  @pragma('vm:entry-point')
  static Future<void> createInstance(IsolateInitInstanceParams<SubfileFillerInstanceRequest> object) async {
    _pbfReader ??= SubfileFiller(object.initObject!.subfileZoomlevelRange, object.initObject!.maxDeviation, object.initObject!.boundingBox);
    await FlutterIsolateInstance.isolateInit(object, readBlobDataStatic);
  }

  @pragma('vm:entry-point')
  static Future<Object?> readBlobDataStatic(IWayholderCollection wayholderCollection) async {
    var result = _pbfReader!.prepareWays(wayholderCollection);
    // free the filehandler in the isolate to being able to delete the file later on.
    await wayholderCollection.freeRessources();
    return result;
  }

  @override
  Future<List<Wayholder>> prepareWays(IWayholderCollection wayholderCollection) async {
    await wayholderCollection.freeRessources();
    List<Wayholder> result = await _isolateInstance.compute(wayholderCollection);
    return result;
    // return await Isolate.run(() {
    //   SubfileFiller subfileFiller = SubfileFiller(subfileZoomlevelRange, maxDeviation, boundingBox);
    //   return subfileFiller.prepareWays(wayholders);
    // });
  }
}

//////////////////////////////////////////////////////////////////////////////

class SubfileFillerInstanceRequest {
  final ZoomlevelRange subfileZoomlevelRange;

  final BoundingBox boundingBox;

  final double maxDeviation;

  SubfileFillerInstanceRequest({required this.subfileZoomlevelRange, required this.boundingBox, required this.maxDeviation});
}

//////////////////////////////////////////////////////////////////////////////

/// A class that prepares way data before it is added to a sub-file.
///
/// This involves two main steps:
/// 1. Filtering: Removing ways that are too small to be visually significant at
///    the target zoom level.
/// 2. Simplification: Reducing the number of vertices in the remaining ways to
///    optimize storage and rendering performance.
class SubfileFiller implements ISubfileFiller {
  late WaySizeFilter sizeFilter;

  late WaySimplifyFilter simplifyFilter;

  late WayCropper wayCropper;

  final ZoomlevelRange subfileZoomlevelRange;

  final BoundingBox boundingBox;

  final double maxDeviation;

  SubfileFiller(this.subfileZoomlevelRange, this.maxDeviation, this.boundingBox) {
    sizeFilter = WaySizeFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    simplifyFilter = WaySimplifyFilter(subfileZoomlevelRange.zoomlevelMax, maxDeviation);
    wayCropper = const WayCropper(maxDeviationPixel: 5);
  }

  /// Prepares a list of ways by filtering and simplifying them.
  @override
  Future<List<Wayholder>> prepareWays(IWayholderCollection wayholderCollection) async {
    // if (maxDeviation <= 0) {
    //   // we do not want to filter anything, return the original
    //   return (await wayholderCollection.getAll()).toList();
    // }
    List<Wayholder> result = [];
    await wayholderCollection.forEach((wayholder) {
      Wayholder? res = sizeFilter.filter(wayholder);
      if (res == null) return;
      // size is big enough, now simplify the way
      res = simplifyFilter.reduce(res);
      // if the object was so tiny that we can simplify it away, do not store it
      if (res.closedOutersRead.isEmpty && res.innerRead.isEmpty && res.openOutersRead.isEmpty) return;
      // crop everything outside of the mapfile's bounding box
      res = wayCropper.cropOutsideWay(res, boundingBox);
      if (res == null) return;

      result.add(res);
    });
    return result;
  }
}
