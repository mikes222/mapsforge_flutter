import '../../core.dart';
import 'fillrule.dart';

abstract class MapPath {
  void clear();

  void close();

  bool isEmpty();

  void lineTo(double x, double y);

  void moveTo(double x, double y);

  void lineToMappoint(Mappoint point);

  void moveToMappoint(Mappoint point);

  void setFillRule(FillRule fillRule);
}
