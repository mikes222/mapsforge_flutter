import 'optionalfields.dart';
import '../model/boundingbox.dart';
import '../model/tag.dart';

import 'mapfileinfo.dart';

class MapFileInfoBuilder {
  BoundingBox? boundingBox;
  int? fileSize;
  int? fileVersion;
  int? mapDate;
  int? numberOfSubFiles;
  late OptionalFields optionalFields;
  List<Tag>? poiTags;
  String? projectionName;
  int? tilePixelSize;
  List<Tag>? wayTags;
  int? zoomLevelMin;
  int? zoomLevelMax;

  MapFileInfo build() {
    return new MapFileInfo(
        boundingBox!,
        optionalFields.comment,
        optionalFields.createdBy,
        optionalFields.isDebugFile,
        fileSize,
        fileVersion,
        optionalFields.languagesPreference,
        mapDate,
        numberOfSubFiles,
        poiTags!,
        projectionName,
        optionalFields.startPosition,
        optionalFields.startZoomLevel,
        tilePixelSize,
        wayTags!,
        zoomLevelMin,
        zoomLevelMax);
  }
}
