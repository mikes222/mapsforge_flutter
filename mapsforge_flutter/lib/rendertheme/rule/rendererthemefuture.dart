import '../../graphics/graphicfactory.dart';
import '../../model/displaymodel.dart';
import '../../rendertheme/rule/renderthemehandler.dart';

import '../xmlrendertheme.dart';
import 'rendertheme.dart';

/**
 * A RenderThemeFuture implements a asynchronous parsing of an XmlRenderTheme in order to
 * move the delay caused by parsing the XML file off the user interface thread in mapsforge
 * application.
 * The RenderThemeFuture is reference counted to make it shareable between threads. Each thread
 * that uses the RenderThemeFuture to retrieve a rendertheme should first call incrementRefCount to
 * ensure that the RenderTheme does not get destroyed while the thread is waiting for execution.
 */
/// flutter supports background operations easily by the "async" keyword. No need for complicated classes imho
class DeprecatedRenderThemeFuture extends RenderTheme {
  final int refCount = 1;

  DeprecatedRenderThemeFuture(GraphicFactory graphicFactory,
      XmlRenderTheme xmlRenderTheme, DisplayModel displayModel)
      : super(null);
//        new RenderThemeCallable(graphicFactory, xmlRenderTheme, displayModel));

//  void decrementRefCount() {
//    int c = this.refCount.decrementAndGet();
//    if (c <= 0) {
//      try {
//        if (this.isDone()) {
//          get().destroy();
//        } else {
//          cancel(true);
//        }
//      }
//    catch
//    (
//    Exception
//    e) {
//    // just cleaning up
//    }
//  }
//  }
//
//  void incrementRefCount() {
//    this.refCount.incrementAndGet();
//  }
}

/////////////////////////////////////////////////////////////////////////////

/**
 * Callable that performs the actual parsing of the render theme (via the RenderThemeHandler
 * as before).
 */
//class RenderThemeCallable implements Callable<RenderTheme> {
//  final GraphicFactory graphicFactory;
//  final XmlRenderTheme xmlRenderTheme;
//  final DisplayModel displayModel;
//
//  RenderThemeCallable(this. graphicFactory,
//      this. xmlRenderTheme, this. displayModel);
//
//  @override
//  RenderTheme call() {
//    if (xmlRenderTheme == null || this.displayModel == null) {
//      return null;
//    }
//    return RenderThemeHandler.getRenderTheme(
//        this.graphicFactory, displayModel, this.xmlRenderTheme);
//  }
//}
