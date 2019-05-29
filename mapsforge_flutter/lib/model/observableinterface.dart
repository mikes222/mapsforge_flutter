import 'observer.dart';

abstract class ObservableInterface {
  void addObserver(Observer observer);

  void removeObserver(Observer observer);
}
