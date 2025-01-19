abstract class Bitmap {
//void compress(OutputStream outputStream) ;
  const Bitmap();

  /**
   * @return the height of this bitmap in pixels.
   */
  int getHeight();

  /**
   * @return the width of this bitmap in pixels.
   */
  int getWidth();

  /// disposes the bitmap. Bitmaps MUST be disposed.
  /// To create a shareable reference to the underlying image, call clone. The method or object that receives the new instance will then be responsible for disposing it, and the underlying image itself will be disposed when all outstanding handles are disposed.
  void dispose();

  Bitmap clone();

  void debugGetOpenHandleStackTraces();

  bool debugDisposed();
}
