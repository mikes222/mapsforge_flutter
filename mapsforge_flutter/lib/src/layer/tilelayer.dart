import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/latlong.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'job/jobset.dart';

///
/// this class presents the whole map by requesting the tiles and drawing them when available
abstract class TileLayer {
  final DisplayModel displayModel;
  bool _visible = true;
  bool needsRepaint = false;

  TileLayer(this.displayModel);

  /// Draws this {@code Layer} on the given canvas.
  ///
  /// @param boundingBox  the geographical area which should be drawn.
  /// @param zoomLevel    the zoom level at which this {@code Layer} should draw itself.
  /// @param canvas       the canvas on which this {@code Layer} should draw itself.
  /// @param topLeftPoint the top-left pixel position of the canvas relative to the top-left map position.
  void draw(ViewModel viewModel, MapViewPosition mapViewPosition,
      MapCanvas canvas, JobSet jobSet);

  /**
   * Gets the geographic position of this layer element, if it exists.
   * <p/>
   * The default implementation of this method returns null.
   *
   * @return the geographic position of this layer element, null otherwise
   */
  LatLong? getPosition() {
    return null;
  }

  /**
   * @return true if this {@code Layer} is currently visible, false otherwise. The default value is true.
   */
  bool isVisible() {
    return this._visible;
  }

  void onDestroy() {
    // do nothing
  }

  /**
   * Handles a long press event. A long press event is only triggered if the map was not moved. A return value of true
   * indicates that the long press event has been handled by this overlay and stops its propagation to other overlays.
   * <p/>
   * The default implementation of this method does nothing and returns false.
   *
   * @param tapLatLong the geographic position of the long press.
   * @param layerXY    the xy position of the layer element (if available)
   * @param tapXY      the xy position of the tap
   * @return true if the long press event was handled, false otherwise.
   */
  bool onLongPress(LatLong tapLatLong, Mappoint layerXY, Mappoint tapXY) {
    return false;
  }

  /**
   * Handles a tap event. A return value of true indicates that the tap event has been handled by this overlay and
   * stops its propagation to other overlays.
   * <p/>
   * The default implementation of this method does nothing and returns false.
   *
   * @param tapLatLong the the geographic position of the tap.
   * @param layerXY    the xy position of the layer element (if available)
   * @param tapXY      the xy position of the tap
   * @return true if the tap event was handled, false otherwise.
   */

  bool onTap(LatLong tapLatLong, Mappoint layerXY, Mappoint tapXY) {
    return false;
  }

  /**
   * Requests an asynchronous redrawing of all layers.
   */
//   final synchronized void requestRedraw() {
//    if (this.assignedRedrawer != null) {
//      this.assignedRedrawer.redrawLayers();
//    }
//  }

  /**
   * Getter for DisplayModel.
   *
   * @return the display model.
   */
  DisplayModel getDisplayModel() {
    return this.displayModel;
  }

  /**
   * Sets the visibility flag of this {@code Layer} to the given value.
   * <p/>
   * Note: By default a redraw will take place afterwards.
   */
  void setVisible(bool visible) {
    this._visible = visible;
  }

  /**
   * Sets the visibility flag of this {@code Layer} to the given value.
   */
//   void setVisible(boolean visible, boolean redraw) {
//    this.visible = visible;
//
//    if (redraw) {
//      requestRedraw();
//    }
//  }

  /**
   * Called each time this {@code Layer} is added to a {@link Layers} list.
   */
  void onAdd() {
    // do nothing
  }

  /**
   * Called each time this {@code Layer} is removed from a {@link Layers} list.
   */
  void onRemove() {
    // do nothing
  }

//   void assign(Redrawer redrawer) {
//    if (this.assignedRedrawer != null) {
//      throw new IllegalStateException("layer already assigned");
//    }
//
//    this.assignedRedrawer = redrawer;
//    onAdd();
//  }
//
//   void unassign() {
//    if (this.assignedRedrawer == null) {
//      throw new IllegalStateException("layer is not assigned");
//    }
//
//    this.assignedRedrawer = null;
//    onRemove();
//  }

  void dispose();
}
