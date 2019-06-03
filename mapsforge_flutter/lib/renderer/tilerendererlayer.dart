import 'package:mapsforge_flutter/cache/tilecache.dart';
import 'package:mapsforge_flutter/datastore/mapdatastore.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/labels/labelstore.dart';
import 'package:mapsforge_flutter/labels/tilebasedlabelstore.dart';
import 'package:mapsforge_flutter/layer/hills/hillsrenderconfig.dart';
import 'package:mapsforge_flutter/layer/job/job.dart';
import 'package:mapsforge_flutter/layer/tilelayer.dart';
import 'package:mapsforge_flutter/model/mapviewposition.dart';
import 'package:mapsforge_flutter/model/observer.dart';
import 'package:mapsforge_flutter/model/tile.dart';
import 'package:meta/meta.dart';

class TileRendererLayer extends TileLayer implements Observer {
  final GraphicFactory graphicFactory;
  final MapDataStore mapDataStore;

//  MapWorkerPool mapWorkerPool;
//  RenderTheme renderTheme;
  double textScale;
  TileBasedLabelStore tileBasedLabelStore;

  /**
   * Creates a TileRendererLayer (without hillshading).<br/>
   * - Tiles will not have alpha/transparency<br/>
   * - Labels will be rendered onto tiles<br/>
   * - Labels will not be cached in a LabelStore
   *
   * @param tileCache       cache where tiles are stored
   * @param mapDataStore    the mapsforge map file
   * @param mapViewPosition the mapViewPosition to know which tiles to render
   * @param graphicFactory  the graphicFactory to carry out platform specific operations
   */
//  TileRendererLayer(TileCache tileCache, MapDataStore mapDataStore, IMapViewPosition mapViewPosition,
//      GraphicFactory graphicFactory) {
//    this(tileCache, mapDataStore, mapViewPosition, false, true, false, graphicFactory);
//  }

  /**
   * Creates a TileRendererLayer (without hillshading).
   *
   * @param tileCache       cache where tiles are stored
   * @param mapDataStore    the mapsforge map file
   * @param mapViewPosition the mapViewPosition to know which tiles to render
   * @param isTransparent   true if the tile should have an alpha/transparency
   * @param renderLabels    true if labels should be rendered onto tiles
   * @param cacheLabels     true if labels should be cached in a LabelStore
   * @param graphicFactory  the graphicFactory to carry out platform specific operations
   */
//  TileRendererLayer(TileCache tileCache, MapDataStore mapDataStore, IMapViewPosition mapViewPosition,
//      boolean isTransparent, boolean renderLabels, boolean cacheLabels,
//      GraphicFactory graphicFactory) {
//    this(tileCache, mapDataStore, mapViewPosition, isTransparent, renderLabels, cacheLabels, graphicFactory, null);
//  }

  /**
   * Creates a TileRendererLayer.
   *
   * @param tileCache         cache where tiles are stored
   * @param mapDataStore      the mapsforge map file
   * @param mapViewPosition   the mapViewPosition to know which tiles to render
   * @param isTransparent     true if the tile should have an alpha/transparency
   * @param renderLabels      true if labels should be rendered onto tiles
   * @param cacheLabels       true if labels should be cached in a LabelStore
   * @param graphicFactory    the graphicFactory to carry out platform specific operations
   * @param hillsRenderConfig the hillshading setup to be used (can be null)
   */
  TileRendererLayer(
      {@required TileCache tileCache,
      @required this.mapDataStore,
      MapViewPosition mapViewPosition,
      bool isTransparent = false,
      bool renderLabels = false,
      bool cacheLabels = false,
      @required this.graphicFactory,
      HillsRenderConfig hillsRenderConfig,
      @required displayModel,
      @required jobRenderer})
      : assert(graphicFactory != null),
        assert(tileCache != null),
        assert(displayModel != null),
        assert(mapDataStore != null),
        assert(jobRenderer != null),
        super(
            tileCache: tileCache,
            matrix: graphicFactory.createMatrix(),
            isTransparent: isTransparent,
            displayModel: displayModel,
            jobRenderer: jobRenderer) {
    if (cacheLabels) {
      this.tileBasedLabelStore = new TileBasedLabelStore(tileCache.getCapacityFirstLevel());
    } else {
      this.tileBasedLabelStore = null;
    }
    this.textScale = 1;
  }

  /**
   * Labels can be stored in a LabelStore for rendering on a separate Layer.
   *
   * @return the LabelStore used for storing labels, null otherwise.
   */
  LabelStore getLabelStore() {
    return tileBasedLabelStore;
  }

  MapDataStore getMapDataStore() {
    return mapDataStore;
  }

  double getTextScale() {
    return this.textScale;
  }

  @override
  void onDestroy() {
//    if (this.renderThemeFuture != null) {
//      this.renderThemeFuture.decrementRefCount();
//    }
    this.mapDataStore.close();
    super.onDestroy();
  }

  void setTextScale(double textScale) {
    this.textScale = textScale;
  }

  void compileRenderTheme() {
//    this.renderThemeFuture = new RenderThemeFuture(
//        this.graphicFactory, this.xmlRenderTheme, this.displayModel);
//    new Thread(this.renderThemeFuture).start();
  }

  /**
   * Whether the tile is stale and should be refreshed.
   * <p/>
   * This method is called from {@link #draw(org.mapsforge.core.model.BoundingBox, byte, org.mapsforge.core.graphics.Canvas, org.mapsforge.core.model.Point)} to determine whether the tile needs to
   * be refreshed.
   * <p/>
   * A tile is considered stale if the timestamp of the layer's {@link #mapDataStore} is more recent than the
   * {@code bitmap}'s {@link org.mapsforge.core.graphics.TileBitmap#getTimestamp()}.
   * <p/>
   * When a tile has become stale, the layer will first display the tile referenced by {@code bitmap} and attempt to
   * obtain a fresh copy in the background. When a fresh copy becomes available, the layer will replace is and update
   * the cache. If a fresh copy cannot be obtained for whatever reason, the stale tile will continue to be used until
   * another {@code #draw(BoundingBox, byte, Canvas, Point)} operation requests it again.
   *
   * @param tile   A tile.
   * @param bitmap The bitmap for {@code tile} currently held in the layer's cache.
   */
  @override
  bool isTileStale(Tile tile, TileBitmap bitmap) {
    return this.mapDataStore.getDataTimestamp(tile) > bitmap.getTimestamp();
  }

  @override
  void onAdd() {
    //this.mapWorkerPool.start();
    if (tileCache != null) {
      tileCache.addObserver(this);
    }

    super.onAdd();
  }

  @override
  void onRemove() {
//    this.mapWorkerPool.stop();
    if (tileCache != null) {
      tileCache.removeObserver(this);
    }
    super.onRemove();
  }

  @override
  void retrieveLabelsOnly(Job job) {
    if ( //this.hasJobQueue &&
        this.tileBasedLabelStore != null && this.tileBasedLabelStore.requiresTile(job.tile)) {
      //job.setRetrieveLabelsOnly();
      this.jobQueue.add(job);
    }
  }

  @override
  void onChange() {
    //this.requestRedraw();
  }
}
