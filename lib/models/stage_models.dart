/// Priority enum for stage loading
enum StagePriority {
  CRITICAL,  // Currently playing stage
  HIGH,      // Next stage in sequence
  MEDIUM,    // Stages close to current
  LOW        // Background loading
}

/// Cache structure for stages and categories
class CachedStage {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final StagePriority priority;
  
  const CachedStage({
    required this.data,
    required this.timestamp,
    this.priority = StagePriority.LOW,
  });
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

/// Structure for managing load requests
class StageLoadRequest {
  final String categoryId;
  final String stageName;
  final StagePriority priority;
  final DateTime timestamp;
  
  const StageLoadRequest({
    required this.categoryId,
    required this.stageName,
    required this.priority,
    required this.timestamp,
  });
} 