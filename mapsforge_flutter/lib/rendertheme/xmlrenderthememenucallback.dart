import 'xmlrenderthemestylemenu.dart';

/**
 * Interface callbacks in Rendertheme V4+ to create a settings menu on the fly.
 */
abstract class XmlRenderThemeMenuCallback {
/*
     * Called when the stylemenu section of the xml file has been parsed
     */
  Set<String> getCategories(XmlRenderThemeStyleMenu style);
}
