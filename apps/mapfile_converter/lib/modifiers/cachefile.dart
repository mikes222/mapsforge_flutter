import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:mapfile_converter/waycacheproto/osm_waycache.pb.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class CacheFile {
  Uint8List toFile(Wayholder wayholder) {
    CacheWayholder cacheWayholder = CacheWayholder();
    cacheWayholder.mergedWithOtherWay = wayholder.mergedWithOtherWay;
    if (wayholder.labelPosition != null) {
      CacheLabel cacheLabel = CacheLabel();
      cacheLabel.lat = $fixnum.Int64(LatLongUtils.degreesToMicrodegrees(wayholder.labelPosition!.latitude));
      cacheLabel.lon = $fixnum.Int64(LatLongUtils.degreesToMicrodegrees(wayholder.labelPosition!.longitude));
      cacheWayholder.label = cacheLabel;
    }
    for (var tagholder in wayholder.tagholderCollection.tagholders) {
      cacheWayholder.tagkeys.add(tagholder.key);
      cacheWayholder.tagvals.add(tagholder.value);
      cacheWayholder.tagindexes.add(tagholder.index ?? -1);
    }

    for (var innerway in wayholder.innerRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in innerway.path) {
        cacheWay.lat.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.longitude)));
      }
      cacheWayholder.innerways.add(cacheWay);
    }
    for (var closedway in wayholder.closedOutersRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in closedway.path) {
        cacheWay.lat.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.longitude)));
      }
      cacheWayholder.closedways.add(cacheWay);
    }
    for (var openway in wayholder.openOutersRead) {
      CacheWay cacheWay = CacheWay();
      for (var point in openway.path) {
        cacheWay.lat.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.latitude)));
        cacheWay.lon.add($fixnum.Int64(LatLongUtils.degreesToMicrodegrees(point.longitude)));
      }
      cacheWayholder.openways.add(cacheWay);
    }
    return cacheWayholder.writeToBuffer();
  }

  Wayholder fromFile(Uint8List file) {
    CacheWayholder cacheWayholder = CacheWayholder.fromBuffer(file);
    final tagkeys = cacheWayholder.tagkeys;
    final tagvals = cacheWayholder.tagvals;
    final tagindexes = cacheWayholder.tagindexes;
    final tagholders = List<Tagholder>.generate(tagkeys.length, (idx) {
      final tagholder = Tagholder(tagkeys[idx], tagvals[idx]);
      final i = tagindexes[idx];
      tagholder.index = i == -1 ? null : i;
      return tagholder;
    }, growable: false);
    TagholderCollection tagholderCollection = TagholderCollection.fromCache(tagholders);
    Wayholder wayholder = Wayholder(tagholderCollection: tagholderCollection);
    //wayholder.tileBitmask = cacheWayholder.tileBitmask;
    wayholder.mergedWithOtherWay = cacheWayholder.mergedWithOtherWay;
    if (cacheWayholder.hasLabel()) {
      wayholder.labelPosition = MicroLatLong(cacheWayholder.label.lat.toInt(), cacheWayholder.label.lon.toInt());
    }
    for (var action in cacheWayholder.innerways) {
      final lat = action.lat;
      final lon = action.lon;
      final coords = List<ILatLong>.generate(lat.length, (i) => MicroLatLong(lat[i].toInt(), lon[i].toInt()), growable: false);
      Waypath waypath = Waypath(path: coords);
      wayholder.innerAdd(waypath);
    }
    for (var action in cacheWayholder.closedways) {
      final lat = action.lat;
      final lon = action.lon;
      final coords = List<ILatLong>.generate(lat.length, (i) => MicroLatLong(lat[i].toInt(), lon[i].toInt()), growable: false);
      Waypath waypath = Waypath(path: coords);
      wayholder.closedOutersAdd(waypath);
    }
    for (var action in cacheWayholder.openways) {
      final lat = action.lat;
      final lon = action.lon;
      final coords = List<ILatLong>.generate(lat.length, (i) => MicroLatLong(lat[i].toInt(), lon[i].toInt()), growable: false);
      Waypath waypath = Waypath(path: coords);
      wayholder.openOutersAdd(waypath);
    }
    return wayholder;
  }
}
