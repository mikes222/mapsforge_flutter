import '../rendertheme/renderinstruction/renderinstruction.dart';

/**
 * Callback methods for render theme.
 */
abstract class ThemeCallback {
/**
 * @return the color-int
 */
  int getColor(RenderInstruction origin, int color);
}
