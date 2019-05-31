import 'package:mapsforge_flutter/model/displaymodel.dart';
import 'package:mapsforge_flutter/model/mapviewposition.dart';

import 'job.dart';

class JobQueue<T extends Job> {
  static final int QUEUE_CAPACITY = 128;

  final List<T> assignedJobs = new List();
  final DisplayModel displayModel;
  bool isInterrupted;
  final MapViewPosition mapViewPosition;
  bool scheduleNeeded;

  JobQueue(this.mapViewPosition, this.displayModel);

  void add(T job) {
    if (!this.assignedJobs.contains(job)) {
      assignedJobs.add(job);
      this.notifyWorkers();
    }
  }

  /**
   * Returns the most important entry from this queue. The method blocks while this queue is empty.
   */
  T get() {
    while (this.assignedJobs.isEmpty) {
      //this.wait(200);
      if (this.isInterrupted) {
        this.isInterrupted = false;
        return null;
      }
    }

    if (this.scheduleNeeded) {
      this.scheduleNeeded = false;
//      schedule(displayModel.getTileSize());
    }

//    T job = this.assignedJobs.remove(0);
//    this.assignedJobs.add(job);
//    return job;
  }

  void interrupt() {
    this.isInterrupted = true;
    notifyWorkers();
  }

  void notifyWorkers() {
//    this.notifyAll();
  }

  void remove(T job) {
    this.assignedJobs.remove(job);
    this.notifyWorkers();
  }

//  void schedule(int tileSize) {
//    QueueItemScheduler.schedule(
//        this.queueItems, this.mapViewPosition.getMapPosition(), tileSize);
//    Collections.sort(this.queueItems, QueueItemComparator.INSTANCE);
//    trimToSize();
//  }

  /**
   * @return the current number of entries in this queue.
   */
  int size() {
//    return this.queueItems.size();
  }

  void trimToSize() {
//    int queueSize = this.queueItems.size();
//
//    while (queueSize > QUEUE_CAPACITY) {
//      this.queueItems.remove(--queueSize);
//    }
  }
}
