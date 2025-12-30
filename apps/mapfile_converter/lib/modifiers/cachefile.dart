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
    for (var tag in wayholder.tagholderCollection.tagholders) {
      cacheWayholder.tagkeys.add(tag.key);
      cacheWayholder.tagvals.add(tag.value);
    }
    for (var entry in wayholder.tagholderCollection.normalized.entries) {
      cacheWayholder.normalizedkeys.add(entry.key);
      cacheWayholder.normalizedvals.add(entry.value);
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
    Map<String, String> tags = {};
    cacheWayholder.tagkeys.forEach((key) {
      tags[key] = cacheWayholder.tagvals[cacheWayholder.tagkeys.indexOf(key)];
    });
    Map<String, String> normalized = {};
    cacheWayholder.normalizedkeys.forEach((key) {
      normalized[key] = cacheWayholder.normalizedvals[cacheWayholder.normalizedkeys.indexOf(key)];
    });
    TagholderCollection tagholderCollection = TagholderCollection.fromCache(tags, normalized);
    Wayholder wayholder = Wayholder(tagholderCollection: tagholderCollection);
    //wayholder.tileBitmask = cacheWayholder.tileBitmask;
    wayholder.mergedWithOtherWay = cacheWayholder.mergedWithOtherWay;
    if (cacheWayholder.hasLabel()) {
      wayholder.labelPosition = LatLong(
        LatLongUtils.microdegreesToDegrees(cacheWayholder.label.lat.toInt()),
        LatLongUtils.microdegreesToDegrees(cacheWayholder.label.lon.toInt()),
      );
    }
    for (var action in cacheWayholder.innerways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(LatLongUtils.microdegreesToDegrees(action.lat[i].toInt()), LatLongUtils.microdegreesToDegrees(action.lon[i].toInt())));
        }
        wayholder.innerAdd(waypath);
      }
    }
    for (var action in cacheWayholder.closedways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(LatLongUtils.microdegreesToDegrees(action.lat[i].toInt()), LatLongUtils.microdegreesToDegrees(action.lon[i].toInt())));
        }
        wayholder.closedOutersAdd(waypath);
      }
    }
    for (var action in cacheWayholder.openways) {
      if (action.lat.isNotEmpty) {
        Waypath waypath = Waypath.empty();
        for (int i = 0; i < action.lat.length; i++) {
          waypath.add(LatLong(LatLongUtils.microdegreesToDegrees(action.lat[i].toInt()), LatLongUtils.microdegreesToDegrees(action.lon[i].toInt())));
        }
        wayholder.openOutersAdd(waypath);
      }
    }
    return wayholder;
  }
}
