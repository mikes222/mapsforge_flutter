import 'observableinterface.dart';
import 'observer.dart';

class Observable implements ObservableInterface {
  static final String OBSERVER_MUST_NOT_BE_NULL = "observer must not be null";
  final List<Observer> observers = new List<Observer>();

  @override
  void addObserver(Observer observer) {
    if (observer == null) {
      throw new Exception(OBSERVER_MUST_NOT_BE_NULL);
    } else if (this.observers.contains(observer)) {
      throw new Exception(
          "observer is already registered: " + observer.toString());
    }
    this.observers.add(observer);
  }

  @override
  void removeObserver(Observer observer) {
    if (observer == null) {
      throw new Exception(OBSERVER_MUST_NOT_BE_NULL);
    } else if (!this.observers.contains(observer)) {
      throw new Exception("observer is not registered: " + observer.toString());
    }
    this.observers.remove(observer);
  }

  void notifyObservers() {
    for (Observer observer in this.observers) {
      observer.onChange();
    }
  }
}
