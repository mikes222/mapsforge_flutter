import 'package:system_info2/system_info2.dart';

class MemoryMgr {
  static MemoryMgr? _instance;

  MemoryMgr._();

  factory MemoryMgr() {
    if (_instance != null) return _instance!;
    _instance = MemoryMgr._();
    return _instance!;
  }

  MemoryStatistics createReport() {
    MemoryStatistics memoryStatistics = MemoryStatistics();
    memoryStatistics.totalPhysicalMemory = SysInfo.getTotalPhysicalMemory();
    memoryStatistics.freePhysicalMemory = SysInfo.getFreePhysicalMemory();
    memoryStatistics.totalVirtualMemory = SysInfo.getTotalVirtualMemory();
    memoryStatistics.freeVirtualMemory = SysInfo.getFreeVirtualMemory();
    memoryStatistics.usedVirtualMemory = SysInfo.getVirtualMemorySize();

    if (memoryStatistics.totalPhysicalMemory > 0) {
      memoryStatistics.freePhysicalPercent = memoryStatistics.freePhysicalMemory / memoryStatistics.totalPhysicalMemory * 100;
    }
    if (memoryStatistics.totalVirtualMemory > 0) {
      memoryStatistics.freeVirtualPercent = memoryStatistics.freeVirtualMemory / memoryStatistics.totalVirtualMemory * 100;
    }
    if (memoryStatistics.totalVirtualMemory > 0) {
      memoryStatistics.usedVirtualMemoryPercent = memoryStatistics.usedVirtualMemory / memoryStatistics.totalVirtualMemory * 100;
    }

    return memoryStatistics;
  }
}

//////////////////////////////////////////////////////////////////////////////

class MemoryStatistics {
  int totalPhysicalMemory = 0;

  int freePhysicalMemory = 0;

  double freePhysicalPercent = 0;

  int totalVirtualMemory = 0;

  int freeVirtualMemory = 0;

  double freeVirtualPercent = 0;

  int usedVirtualMemory = 0;

  double usedVirtualMemoryPercent = 0;

  @override
  String toString() {
    return 'totalPhysicalMemory: $totalPhysicalMemory, freePhysicalMemory: $freePhysicalMemory (${freePhysicalPercent.toStringAsFixed(1)}%)\ntotalVirtualMemory: $totalVirtualMemory, freeVirtualMemory: $freeVirtualMemory (${freeVirtualPercent.toStringAsFixed(1)}%)\nusedVirtualMemory: $usedVirtualMemory (${usedVirtualMemoryPercent.toStringAsFixed(1)}%)';
  }
}
