import 'dart:io';

import 'package:mapfile_converter/pbfreader/proto/fileformat.pb.dart';
import 'package:mapfile_converter/pbfreader/proto/osmformat.pb.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

/// Reads data from a PBF file.
class PbfReader {
  HeaderBlock? headerBlock;

  Future<BlobResult> readBlob(ReadbufferSource readbufferSource) async {
    // length of the blob header
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));
    // print("blobHeader: ${blobHeader.type}");
    // print("blobHeader.datasize: ${blobHeader.datasize}");
    // print("blobHeader.indexdata: ${blobHeader.indexdata}");
    // print("blobHeader.unknownFields: ${blobHeader.unknownFields}");

    final blobLength = blobHeader.datasize;
    readbuffer = await readbufferSource.readFromFile(blobLength);
    final blob = Blob.fromBuffer(readbuffer.getBuffer(0, blobLength));
    final blobOutput = ZLibDecoder().convert(blob.zlibData);
    assert(blobOutput.length == blob.rawSize);
    return BlobResult(blobHeader, blobOutput);
  }

  Future<void> skipBlob(ReadbufferSource readbufferSource) async {
    // length of the blob header
    Readbuffer readbuffer = await readbufferSource.readFromFile(4);
    final blobHeaderLength = readbuffer.readInt();
    readbuffer = await readbufferSource.readFromFile(blobHeaderLength);
    final blobHeader = BlobHeader.fromBuffer(readbuffer.getBuffer(0, blobHeaderLength));

    final blobLength = blobHeader.datasize;
    await readbufferSource.setPosition(readbufferSource.getPosition() + blobLength);
  }

  Future<void> open(ReadbufferSource readbufferSource) async {
    final blobResult = await readBlob(readbufferSource);
    if (blobResult.blobHeader.type != 'OSMHeader') {
      throw Exception("Invalid file format OSMHeader expected");
    }
    headerBlock = HeaderBlock.fromBuffer(blobResult.blobOutput);
    // print("headerBlock.bbox: ${headerBlock!.bbox}");
    // print("headerBlock.requiredFeatures: ${headerBlock!.requiredFeatures}");
    // print("headerBlock.optionalFeatures: ${headerBlock!.optionalFeatures}");
    // print("headerBlock.writingprogram: ${headerBlock!.writingprogram}");
    // print("headerBlock.source: ${headerBlock!.source}");
    // print(
    //     "headerBlock.osmosisReplicationTimestamp: ${headerBlock!.osmosisReplicationTimestamp}");
    // print(
    //     "headerBlock.osmosisReplicationSequenceNumber: ${headerBlock!.osmosisReplicationSequenceNumber}");
    // print(
    //     "headerBlock.osmosisReplicationBaseUrl: ${headerBlock!.osmosisReplicationBaseUrl}");
  }

  BoundingBox? calculateBounds() {
    if (headerBlock == null) return null;
    final bounds =
        (headerBlock!.bbox.bottom != 0 || headerBlock!.bbox.left != 0 || headerBlock!.bbox.top != 0 || headerBlock!.bbox.right != 0)
            ? BoundingBox(
              1e-9 * headerBlock!.bbox.bottom.toInt(),
              1e-9 * headerBlock!.bbox.left.toInt(),
              1e-9 * headerBlock!.bbox.top.toInt(),
              1e-9 * headerBlock!.bbox.right.toInt(),
            )
            : null;
    return bounds;
  }
}

//////////////////////////////////////////////////////////////////////////////

class BlobResult {
  final BlobHeader blobHeader;

  final List<int> blobOutput;

  BlobResult(this.blobHeader, this.blobOutput);
}
