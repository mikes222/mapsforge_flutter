import '../model/dimension.dart';

import 'bitmap.dart';
import 'graphiccontext.dart';

abstract class Canvas extends GraphicContext {
  void destroy();

  Dimension getDimension();

  int getHeight();

  int getWidth();

  void setBitmap(Bitmap bitmap);
}
