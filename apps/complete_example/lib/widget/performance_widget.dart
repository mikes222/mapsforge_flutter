import 'dart:async';

import 'package:complete_example/services/memory_mgr.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';

class PerformanceWidget extends StatefulWidget {
  const PerformanceWidget({super.key});

  @override
  State<PerformanceWidget> createState() => _PerformanceWidgetState();
}

class _PerformanceWidgetState extends State<PerformanceWidget> {
  String _performanceInfo = '';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
    _updatePerformanceInfo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    // Update performance info every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePerformanceInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Performance Metrics',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      PerformanceProfiler().clear();
                      StorageMgr().clear();
                      TaskQueueMgr().clear();
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onLongPress: () async {
                  await Clipboard.setData(ClipboardData(text: _performanceInfo));
                },
                child: Text(
                  _performanceInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
              Text("Note that metrics inside isolates are not accessible", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePerformanceInfo() {
    final MemoryStatistics memoryStatistics = MemoryMgr().createReport();
    final PerformanceReport performanceStats = PerformanceProfiler().generateReport(false);
    final StorageReport storageReport = StorageMgr().createReport();
    String storageString = storageReport.toString();
    storageString = storageString.replaceAll("StatisticsStorage", "");
    storageString = storageString.replaceAll("StorageMetric", "");
    final TaskQueueReport taskQueueReport = TaskQueueMgr().createReport();

    setState(() {
      _performanceInfo =
          '''
$memoryStatistics

$performanceStats
Cache $storageString
$taskQueueReport
          ''';
    });
  }
}
