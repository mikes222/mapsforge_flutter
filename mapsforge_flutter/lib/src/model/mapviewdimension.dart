import 'dimension.dart';
import 'observable.dart';

class MapViewDimension extends Observable {
  Dimension _dimension;

  /**
   * @return the current dimension of the {@code MapView} (may be null).
   */
  Dimension getDimension() {
    return this._dimension;
  }

  bool setDimension(double width, double height) {
    assert(width != null && width >= 0);
    assert(height != null && height >= 0);
    if (_dimension != null && _dimension.width == width && _dimension.height == height) return false;
    _dimension = Dimension(width, height);
    notifyObservers();
    return true;
  }
}
