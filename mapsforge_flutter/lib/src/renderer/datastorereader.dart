import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/renderinstruction/renderinstruction.dart';
import '../rendertheme/wayproperties.dart';

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread.
class DatastoreReader {
  DatastoreReader();

  Future<DatastoreReadResult?> read(
      Datastore datastore,
      Tile tile,
      PixelProjection projection,
      RenderContext renderContext,
      RenderTheme renderTheme) async {
    // read the mapdata directly in this thread
    await datastore.lateOpen();
    if (!datastore.supportsTile(tile, projection)) {
      return null;
    }
    DatastoreReadResult? mapReadResult =
        await datastore.readMapDataSingle(tile);
    if (mapReadResult != null)
      processMapReadResult(renderContext, renderTheme, mapReadResult);
    return mapReadResult;
  }

  /// Creates rendering instructions based on the given ways and nodes and the defined rendertheme
  void processMapReadResult(final RenderContext renderContext,
      RenderTheme renderTheme, DatastoreReadResult mapReadResult) {
    for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
      NodeProperties nodeProperties = NodeProperties(pointOfInterest);
      List<RenderInstruction> renderInstructions =
          _retrieveRenderInstructionsForPoi(
              renderContext, renderTheme, nodeProperties);
      for (RenderInstruction renderInstruction in renderInstructions) {
        renderInstruction.renderNode(renderContext, nodeProperties);
      }
    }

    // never ever call an async method 44000 times. It takes 2 seconds to do so!
//    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
    for (Way way in mapReadResult.ways) {
      WayProperties wayProperties = WayProperties(way);
      List<RenderInstruction> renderInstructions =
          _retrieveRenderInstructionsForWay(
              renderContext, renderTheme, wayProperties);
      for (RenderInstruction renderInstruction in renderInstructions) {
        renderInstruction.renderWay(renderContext, wayProperties);
      }
    }
    if (mapReadResult.isWater) {
      _renderWaterBackground(renderContext);
    }
  }

  List<RenderInstruction> _retrieveRenderInstructionsForPoi(
      final RenderContext renderContext,
      RenderTheme renderTheme,
      NodeProperties nodeProperties) {
    renderContext.setDrawingLayers(nodeProperties.layer);
    List<RenderInstruction> renderInstructions =
        renderTheme.matchNode(renderContext.upperLeft, nodeProperties);
    return renderInstructions;
  }

  List<RenderInstruction> _retrieveRenderInstructionsForWay(
      final RenderContext renderContext,
      RenderTheme renderTheme,
      WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return [];
    renderContext.setDrawingLayers(wayProperties.getLayer());
    if (wayProperties.isClosedWay) {
      List<RenderInstruction> renderInstructions = renderTheme.matchClosedWay(
          renderContext.upperLeft, wayProperties.way);
      return renderInstructions;
    } else {
      List<RenderInstruction> renderInstructions = renderTheme.matchLinearWay(
          renderContext.upperLeft, wayProperties.way);
      return renderInstructions;
    }
  }

  void _renderWaterBackground(final RenderContext renderContext) {
    // renderContext.setDrawingLayers(0);
    // List<Mappoint> coordinates =
    //     getTilePixelCoordinates(renderContext.job.tileSize);
    // Mappoint tileOrigin =
    //     renderContext.projection.getLeftUpper(renderContext.job.tile);
    // for (int i = 0; i < coordinates.length; i++) {
    //   coordinates[i] = coordinates[i].offset(tileOrigin.x, tileOrigin.y);
    // }
    // Watercontainer way = Watercontainer(
    //     coordinates, renderContext.job.tile, [TAG_NATURAL_WATER]);
    //renderContext.renderTheme.matchClosedWay(databaseRenderer, renderContext, way);
  }
}
