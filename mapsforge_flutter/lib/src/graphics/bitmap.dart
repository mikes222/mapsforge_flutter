abstract class Bitmap {
//void compress(OutputStream outputStream) ;
  Bitmap();

  /**
   * @return the height of this bitmap in pixels.
   */
  int getHeight();

  /**
   * @return the width of this bitmap in pixels.
   */
  int getWidth();

  void dispose();
}
