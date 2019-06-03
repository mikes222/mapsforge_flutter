import 'fillrule.dart';

abstract class MapPath {
  void clear();

  void close();

  bool isEmpty();

  void lineTo(double x, double y);

  void moveTo(double x, double y);

  void setFillRule(FillRule fillRule);
}
