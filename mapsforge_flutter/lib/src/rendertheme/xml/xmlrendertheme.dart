import 'package:mapsforge_flutter/src/inputstream.dart';
import 'xmlrenderthememenucallback.dart';

/**
 * Interface for a render theme which is defined in XML.
 */
abstract class XmlRenderTheme {
  /**
   * @return the interface callback to create a settings menu on the fly.
   */
  XmlRenderThemeMenuCallback getMenuCallback();

  /**
   * @return the prefix for all relative resource paths.
   */
  String getRelativePathPrefix();

  /**
   * @return an InputStream to read the render theme data from.
   * @throws FileNotFoundException if the render theme file cannot be found.
   */
  InputStream getRenderThemeAsStream();

  /**
   * @param menuCallback the interface callback to create a settings menu on the fly.
   */
  void setMenuCallback(XmlRenderThemeMenuCallback menuCallback);
}
