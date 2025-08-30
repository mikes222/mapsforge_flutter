import 'package:dart_common/src/isolate/dart_isolate.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/// In our main isolate we will set it to folse so everytime we are in an isolate we will have true here
bool isIsolate = true;

void main() {
  group('A group of tests', () {
    //final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
      isIsolate = false;
    });

    /// An isolate which is initialized during construction time. Use this if you need to handle large quantities of data to the isolate which are not
    /// changing during the lifetime of the isolate.
    test('Isolate with class with instanceparam', () async {
      {
        // measure the time needed for this method
        int time = DateTime.now().millisecondsSinceEpoch;
        // test class without isolate
        WorkingClass workingClass = WorkingClass("classParams");
        String reply = await workingClass.process(2);
        expect(DateTime.now().millisecondsSinceEpoch - time, greaterThan(2000));
        expect(reply, equals("Hello classParams tester, wait: 2 secs, is isolate: false"));
      }
      {
        int time = DateTime.now().millisecondsSinceEpoch;
        // test class with isolate
        IsolateWorkingClass workingClass = await IsolateWorkingClass.instantiate("isolateParams");
        String reply = await workingClass.process(2);
        expect(DateTime.now().millisecondsSinceEpoch - time, greaterThan(2000));
        expect(reply, equals("Hello isolateParams tester, wait: 2 secs, is isolate: true"));
      }
    });

    test('Isolate multiple calls to one isolate', () async {
      {
        int time = DateTime.now().millisecondsSinceEpoch;
        // test class with isolate
        IsolateWorkingClass workingClass = await IsolateWorkingClass.instantiate("isolateParams");
        Future<String> w1 = workingClass.process(3);
        Future<String> w2 = workingClass.process(1);
        Future<String> w3 = workingClass.process(2);
        expect(DateTime.now().millisecondsSinceEpoch - time, lessThan(500));
        String reply1 = await w1;
        expect(DateTime.now().millisecondsSinceEpoch - time, greaterThan(3000));
        String reply2 = await w2;
        String reply3 = await w3;
        expect(DateTime.now().millisecondsSinceEpoch - time, lessThan(4000));
        expect(reply1, equals("Hello isolateParams tester, wait: 3 secs, is isolate: true"));
        expect(reply2, equals("Hello isolateParams tester, wait: 1 secs, is isolate: true"));
        expect(reply3, equals("Hello isolateParams tester, wait: 2 secs, is isolate: true"));
      }
    });

    test('Isolate throws an exception', () async {
      {
        IsolateWorkingClass workingClass = await IsolateWorkingClass.instantiate("isolateExceptionParams");
        expect(() => workingClass.process(-1), throwsException);
      }
    });
  });
}

//////////////////////////////////////////////////////////////////////////////

@pragma('vm:entry-point')
Future<void> entryPoint(IsolateInitInstanceParams isolateInitInstanceParam) async {
  // init the isolate if there is an init parameter in isolateParam
  await FlutterIsolateInstance.isolateInit(isolateInitInstanceParam, requestCallback);
}

@pragma('vm:entry-point')
Future<String> requestCallback(int object) async {
  await Future.delayed(Duration(seconds: object));
  return "Hello Tester, wait: $object secs, is isolate: $isIsolate";
}

//////////////////////////////////////////////////////////////////////////////

/// A wrapper to use the [WorkingClass] in an isolate.
@pragma('vm:entry-point')
class IsolateWorkingClass {
  final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  static WorkingClass? _workingClass;

  IsolateWorkingClass._();

  static Future<IsolateWorkingClass> instantiate(String instanceparam) async {
    IsolateWorkingClass isolateWorkingClass = IsolateWorkingClass._();
    await isolateWorkingClass._isolateInstance.spawn(entryPoint, instanceparam);
    return isolateWorkingClass;
  }

  /// Note that the method is the same as the original class so it is easily interchangeable.
  Future<String> process(int key) async {
    return await _isolateInstance.compute(key);
  }

  @pragma('vm:entry-point')
  static Future<void> entryPoint(IsolateInitInstanceParams<String> key) async {
    _workingClass = WorkingClass(key.initObject!);
    await FlutterIsolateInstance.isolateInit(key, _entryPointStatic);
  }

  @pragma('vm:entry-point')
  static Future<String> _entryPointStatic(int key) async {
    return _workingClass!.process(key);
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A simple class without considering isolates
class WorkingClass {
  final String instanceparam;

  WorkingClass(this.instanceparam);

  Future<String> process(int key) async {
    if (key <= 0) throw Exception("Invalid key $key");
    await Future.delayed(Duration(seconds: key));
    return "Hello $instanceparam tester, wait: $key secs, is isolate: $isIsolate";
  }
}
