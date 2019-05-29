abstract class Observer {
  /**
   * Called whenever the observed object has been changed.
   * <p/>
   * Time-consuming operations should be performed in a separate thread.
   */
  void onChange();
}
