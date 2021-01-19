abstract class Bitmap {
//void compress(OutputStream outputStream) ;
  Bitmap();

  ///
  /// Decreements the referral count. If the referral count is zero, the bitmap will be evicted from memory
  ///
  void decrementRefCount();

  /**
   * @return the height of this bitmap in pixels.
   */
  int getHeight();

  /**
   * @return the width of this bitmap in pixels.
   */
  int getWidth();

  ///
  /// increments the referral count. Each time the bitmap is stored somewhere this should be incremented.
  ///
  void incrementRefCount();

  bool isDestroyed();

  // void scaleTo(int width, int height);
  //
  // void setBackgroundColor(int color);
}
