import '../datastore/mapdatastore.dart';
import '../datastore/mapreadresult.dart';
import '../datastore/pointofinterest.dart';
import '../datastore/way.dart';
import '../graphics/bitmap.dart';
import '../graphics/display.dart';
import '../graphics/graphicfactory.dart';
import '../graphics/position.dart';
import '../layer/hills/hillsrenderconfig.dart';
import '../mapelements/symbolcontainer.dart';
import '../model/latlong.dart';
import '../renderer/polylinecontainer.dart';
import '../renderer/shapepaintcontainer.dart';
import '../renderer/waydecorator.dart';
import '../rendertheme/rendercallback.dart';
import '../rendertheme/rendercontext.dart';
import '../utils/mercatorprojection.dart';

import '../graphics/paint.dart';
import '../model/mappoint.dart';
import '../model/tag.dart';
import 'circlecontainer.dart';

/**
 * The DatabaseRenderer renders map tiles by reading from a {@link MapDataStore}.
 */
class StandardRenderer implements RenderCallback {
  static final int DEFAULT_START_ZOOM_LEVEL = 12;
  static final Tag TAG_NATURAL_WATER = new Tag("natural", "water");
  static final int ZOOM_MAX = 22;

  final GraphicFactory graphicFactory;
  final HillsRenderConfig hillsRenderConfig;
  final MapDataStore mapDataStore;
  final bool renderLabels;

  /**
   * Constructs a new StandardRenderer (without hillshading).
   *
   * @param mapDataStore the MapDataStore from which the map data will be read.
   */
//  StandardRenderer(MapDataStore mapDataStore,
//      GraphicFactory graphicFactory,
//      bool renderLabels) {
//    this(mapDataStore, graphicFactory, renderLabels, null);
//  }

  /**
   * Constructs a new StandardRenderer.
   *
   * @param mapDataStore      the MapDataStore from which the map data will be read.
   * @param hillsRenderConfig optional relief shading support.
   */
  StandardRenderer(this.mapDataStore, this.graphicFactory, this.renderLabels,
      this.hillsRenderConfig);

  /**
   * @return the start point (may be null).
   */
  LatLong getStartPosition() {
    if (this.mapDataStore != null) {
      return this.mapDataStore.startPosition();
    }
    return null;
  }

  /**
   * @return the start zoom level (may be null).
   */
  int getStartZoomLevel() {
    if (this.mapDataStore != null &&
        null != this.mapDataStore.startZoomLevel()) {
      return this.mapDataStore.startZoomLevel();
    }
    return DEFAULT_START_ZOOM_LEVEL;
  }

  /**
   * @return the maximum zoom level.
   */
  int getZoomLevelMax() {
    return ZOOM_MAX;
  }

  @override
  void renderArea(final RenderContext renderContext, Paint fill, Paint stroke,
      int level, PolylineContainer way) async {
    renderContext.addToCurrentDrawingLayer(
        level, new ShapePaintContainer(way, stroke, 0));
    renderContext.addToCurrentDrawingLayer(
        level, new ShapePaintContainer(way, fill, 0));
  }

  @override
  void renderAreaCaption(
      final RenderContext renderContext,
      Display display,
      int priority,
      String caption,
      double horizontalOffset,
      double verticalOffset,
      Paint fill,
      Paint stroke,
      Position position,
      int maxTextWidth,
      PolylineContainer way) async {
    if (renderLabels) {
      Mappoint centerMappoint =
          way.getCenterAbsolute().offset(horizontalOffset, verticalOffset);
      renderContext.labels.add(this.graphicFactory.createPointTextContainer(
          centerMappoint,
          display,
          priority,
          caption,
          fill,
          stroke,
          null,
          position,
          maxTextWidth));
    }
  }

  @override
  void renderAreaSymbol(final RenderContext renderContext, Display display,
      int priority, Bitmap symbol, PolylineContainer way) {
    if (renderLabels) {
      Mappoint centerPosition = way.getCenterAbsolute();
      renderContext.labels
          .add(new SymbolContainer(centerPosition, display, priority, symbol));
    }
  }

  @override
  void renderPointOfInterestCaption(
      final RenderContext renderContext,
      Display display,
      int priority,
      String caption,
      double horizontalOffset,
      double verticalOffset,
      Paint fill,
      Paint stroke,
      Position position,
      int maxTextWidth,
      PointOfInterest poi) {
    if (renderLabels) {
      Mappoint poiPosition = MercatorProjection.getPixelAbsolute(
          poi.position, renderContext.rendererJob.tile.mapSize);

      renderContext.labels.add(this.graphicFactory.createPointTextContainer(
          poiPosition.offset(horizontalOffset, verticalOffset),
          display,
          priority,
          caption,
          fill,
          stroke,
          null,
          position,
          maxTextWidth));
    }
  }

  @override
  void renderPointOfInterestCircle(
      final RenderContext renderContext,
      double radius,
      Paint fill,
      Paint stroke,
      int level,
      PointOfInterest poi) async {
    Mappoint poiPosition = MercatorProjection.getPixelRelativeToTile(
        poi.position, renderContext.rendererJob.tile);
    renderContext.addToCurrentDrawingLayer(
        level,
        new ShapePaintContainer(
            new CircleContainer(poiPosition, radius), stroke, 0));
    renderContext.addToCurrentDrawingLayer(
        level,
        new ShapePaintContainer(
            new CircleContainer(poiPosition, radius), fill, 0));
  }

  @override
  void renderPointOfInterestSymbol(final RenderContext renderContext,
      Display display, int priority, Bitmap symbol, PointOfInterest poi) {
    if (renderLabels) {
      Mappoint poiPosition = MercatorProjection.getPixelAbsolute(
          poi.position, renderContext.rendererJob.tile.mapSize);
      renderContext.labels
          .add(new SymbolContainer(poiPosition, display, priority, symbol));
    }
  }

  @override
  void renderWay(final RenderContext renderContext, Paint stroke, double dy,
      int level, PolylineContainer way) {
    renderContext.addToCurrentDrawingLayer(
        level, new ShapePaintContainer(way, stroke, dy));
  }

  @override
  void renderWaySymbol(
      final RenderContext renderContext,
      Display display,
      int priority,
      Bitmap symbol,
      double dy,
      bool alignCenter,
      bool repeat,
      double repeatGap,
      double repeatStart,
      bool rotate,
      PolylineContainer way) {
    if (renderLabels) {
      WayDecorator.renderSymbol(
          symbol,
          display,
          priority,
          dy,
          alignCenter,
          repeat,
          repeatGap.toInt(),
          repeatStart.toInt(),
          rotate,
          way.getCoordinatesAbsolute(),
          renderContext.labels);
    }
  }

  @override
  void renderWayText(
      final RenderContext renderContext,
      Display display,
      int priority,
      String textKey,
      double dy,
      Paint fill,
      Paint stroke,
      bool repeat,
      double repeatGap,
      double repeatStart,
      bool rotate,
      PolylineContainer way) {
    if (renderLabels) {
      WayDecorator.renderText(
          graphicFactory,
          way.getUpperLeft(),
          way.getLowerRight(),
          textKey,
          display,
          priority,
          dy,
          fill,
          stroke,
          repeat,
          repeatGap,
          repeatStart,
          rotate,
          way.getCoordinatesAbsolute(),
          renderContext.labels);
    }
  }

  bool renderBitmap(RenderContext renderContext) {
    return !renderContext.renderTheme.hasMapBackgroundOutside() ||
        this.mapDataStore.supportsTile(renderContext.rendererJob.tile);
  }

  void renderMappointOfInterest(
      final RenderContext renderContext, PointOfInterest pointOfInterest) {
    renderContext.setDrawingLayers(pointOfInterest.layer);
    renderContext.renderTheme.matchNode(this, renderContext, pointOfInterest);
  }

  void renderWaterBackground(final RenderContext renderContext) {
    renderContext.setDrawingLayers(0);
    List<Mappoint> coordinates =
        getTilePixelCoordinates(renderContext.rendererJob.tile.tileSize);
    Mappoint tileOrigin = renderContext.rendererJob.tile.getOrigin();
    for (int i = 0; i < coordinates.length; i++) {
      coordinates[i] = coordinates[i].offset(tileOrigin.x, tileOrigin.y);
    }
    PolylineContainer way = new PolylineContainer.fromList(
        coordinates,
        renderContext.rendererJob.tile,
        renderContext.rendererJob.tile,
        [TAG_NATURAL_WATER]);
    renderContext.renderTheme.matchClosedWay(this, renderContext, way);
  }

  void renderWay1(RenderContext renderContext, PolylineContainer way) {
    renderContext.setDrawingLayers(way.getLayer());

    if (way.isClosedWay) {
      renderContext.renderTheme.matchClosedWay(this, renderContext, way);
    } else {
      renderContext.renderTheme.matchLinearWay(this, renderContext, way);
    }
  }

  void processReadMapData(
      final RenderContext renderContext, MapReadResult mapReadResult) {
    if (mapReadResult == null) {
      return;
    }

    for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
      renderMappointOfInterest(renderContext, pointOfInterest);
    }

    for (Way way in mapReadResult.ways) {
      renderWay(
          renderContext,
          null,
          null,
          null,
          new PolylineContainer(way, renderContext.rendererJob.tile,
              renderContext.rendererJob.tile));
    }

    if (mapReadResult.isWater) {
      renderWaterBackground(renderContext);
    }
  }

  static List<Mappoint> getTilePixelCoordinates(int tileSize) {
    List<Mappoint> result = List<Mappoint>();
    result.add(Mappoint(0, 0));
    result.add(Mappoint(tileSize.toDouble(), 0));
    result.add(Mappoint(tileSize.toDouble(), tileSize.toDouble()));
    result.add(Mappoint(0, tileSize.toDouble()));
    result.add(result[0]);
    return result;
  }
}
