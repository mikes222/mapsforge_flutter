abstract class Bitmap {
//void compress(OutputStream outputStream) ;

  void decrementRefCount();

  /**
   * @return the height of this bitmap in pixels.
   */
  int getHeight();

  /**
   * @return the width of this bitmap in pixels.
   */
  int getWidth();

  void incrementRefCount();

  bool isDestroyed();

  void scaleTo(int width, int height);

  void setBackgroundColor(int color);
}
