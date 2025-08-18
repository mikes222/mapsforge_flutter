# task_queue

A Dart package that provides a task queue mechanism to manage and execute asynchronous tasks.

# Features

 - **Sequential Task Execution**: Ensures tasks are executed one after another, maintaining order and preventing race conditions.
 - **Parallel Task Execution**: Ensures a limited number of tasks are executed concurrently, enhancing efficiency.

# Getting Started

**Add Dependency:**

Add the following to your pubspec.yaml file:

```yaml
dependencies:
  task_queue: ^1.0.0
```

**Import the Package:**

In your Dart code, import the package:

```dart
import 'package:task_queue/task_queue.dart';
```

# Getting Started with Task execution

## Sequential task execution

Here's a basic example of how to use isolate_task_queue:

```dart
void main() async {
    final queue = SimpleTaskQueue();
    
    queue.add(() async {
        print("Task 1 start");
        await Future.delayed(Duration(seconds: 2));
        print("Task 1 end");
    });
    
    queue.add(() async {
        print("Task 2 start");
        await Future.delayed(Duration(seconds: 1));
        print("Task 2 end");
    });
    
    queue.add(() async {
        print("Task 3 start");
        await Future.delayed(Duration(milliseconds: 500));
        print("Task 3 end");
    });
    
    print("All tasks added to the queue and will execute sequentially.");
}
```

In this example, each task is added to the queue and will execute sequentially, ensuring that each task completes before the next begins.

## Parallel task execution

Instantiate the queue like this:

```dart
final queue = ParallelTaskQueue(2);
```

The handling is the same as the sequential execution explained above.

---

# Additional Information

 - License: This project is licensed under the MIT License. See the LICENSE file for details.
 - Contributions: Contributions are welcome! Please open issues or submit pull requests for any enhancements or bug fixes.
 - Author: mikes222

