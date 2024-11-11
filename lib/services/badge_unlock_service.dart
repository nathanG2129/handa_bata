import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'dart:collection';
import 'dart:async';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/services/badge_service.dart';

class QuestBadgeRange {
  final int stageStart;     // First badge ID for normal stages
  final int completeStart;  // Badge ID for completion
  final int fullClearStart; // Badge ID for full clear
  
  const QuestBadgeRange(this.stageStart, this.completeStart, this.fullClearStart);
}

class UnlockCache {
  final Map<String, List<int>> unlockedBadges;
  final DateTime timestamp;
  final String questName;
  
  UnlockCache({
    required this.unlockedBadges,
    required this.timestamp,
    required this.questName,
  });
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

enum UnlockPriority {
  ACHIEVEMENT,     // Important achievements (100% completion)
  QUEST_COMPLETE,  // Quest completion badges
  MILESTONE,       // Progress milestones
  REGULAR         // Regular gameplay unlocks
}

class UnlockRequest {
  final int badgeId;
  final UnlockPriority priority;
  final String questName;
  final DateTime timestamp;
  
  UnlockRequest({
    required this.badgeId,
    required this.priority,
    required this.questName,
    required this.timestamp,
  });
}

class NotificationBatch {
  final List<int> badgeIds;
  final UnlockPriority priority;
  final String questContext;
  final DateTime timestamp;
  
  NotificationBatch({
    required this.badgeIds,
    required this.priority,
    required this.questContext,
    required this.timestamp,
  });
}

class NotificationQueue {
  static const Duration BATCH_WINDOW = Duration(milliseconds: 500);
  static const int MAX_BATCH_SIZE = 3;
  
  final Queue<NotificationBatch> _queue = Queue<NotificationBatch>();
  Timer? _batchTimer;
  Map<String, List<int>> _pendingBatches = {};

  void addNotification(int badgeId, UnlockPriority priority, String questContext) {
    // Cancel existing timer
    _batchTimer?.cancel();

    // Add to pending batch
    _pendingBatches.putIfAbsent(questContext, () => []).add(badgeId);

    // Create new batch after window or when max size reached
    if (_shouldCreateBatch(questContext)) {
      _createBatch(questContext, priority);
    } else {
      // Set timer for remaining badges
      _batchTimer = Timer(BATCH_WINDOW, () {
        if (_pendingBatches.isNotEmpty) {
          _createBatch(questContext, priority);
        }
      });
    }
  }

  bool _shouldCreateBatch(String questContext) {
    return _pendingBatches[questContext]?.length == MAX_BATCH_SIZE;
  }

  void _createBatch(String questContext, UnlockPriority priority) {
    if (_pendingBatches[questContext]?.isNotEmpty ?? false) {
      _queue.add(NotificationBatch(
        badgeIds: List.from(_pendingBatches[questContext]!),
        priority: priority,
        questContext: questContext,
        timestamp: DateTime.now(),
      ));
      _pendingBatches[questContext]?.clear();
    }
  }

  NotificationBatch? getNextBatch() {
    return _queue.isNotEmpty ? _queue.removeFirst() : null;
  }

  bool get hasPendingNotifications => 
    _queue.isNotEmpty || _pendingBatches.values.any((batch) => batch.isNotEmpty);
}

// Add CacheCoordinator class
class CacheCoordinator {
  final BadgeService _badgeService;
  final Map<String, UnlockCache> _unlockCache;
  
  CacheCoordinator(this._badgeService, this._unlockCache);

  void invalidateSharedCaches(String questName) {
    // Clear unlock cache for quest
    _unlockCache.remove(questName);
    
    // Trigger badge service sync
    _badgeService.triggerBackgroundSync();
  }

  Future<void> syncCacheVersions() async {
    try {
      // Get badge service version
      
      // Compare and sync if needed
      for (var entry in _unlockCache.entries) {
        if (!entry.value.isValid) {
          _unlockCache.remove(entry.key);
          continue;
        }
        
        // Check if quest badges need update
        final questBadges = entry.value.unlockedBadges[entry.key] ?? [];
        for (var badgeId in questBadges) {
          final badge = await _badgeService.getBadgeDetails(badgeId);
          if (badge == null) {
            // Badge no longer exists, remove from cache
            _unlockCache.remove(entry.key);
            break;
          }
        }
      }
    } catch (e) {
      print('Error syncing cache versions: $e');
    }
  }

  void handleOfflineChanges() {
    // Process any pending offline unlocks
    for (var entry in _unlockCache.entries) {
      final questName = entry.key;
      final unlockedBadges = entry.value.unlockedBadges[questName] ?? [];
      
      // Queue for processing when back online
      for (var badgeId in unlockedBadges) {
        _badgeService.queueBadgeLoad(badgeId, BadgePriority.HIGH);
      }
    }
  }
}

class BadgeUnlockService {
  static final NotificationQueue _notificationQueue = NotificationQueue();
  static bool _isShowingNotification = false;

  static final BadgeUnlockService _instance = BadgeUnlockService._internal();
  factory BadgeUnlockService() => _instance;

  static final Map<String, UnlockCache> _unlockCache = {};
  static const int MAX_CACHE_SIZE = 50;

  static final Map<UnlockPriority, Queue<UnlockRequest>> _unlockQueues = {
    UnlockPriority.ACHIEVEMENT: Queue<UnlockRequest>(),
    UnlockPriority.QUEST_COMPLETE: Queue<UnlockRequest>(),
    UnlockPriority.MILESTONE: Queue<UnlockRequest>(),
    UnlockPriority.REGULAR: Queue<UnlockRequest>(),
  };

  final AuthService _authService;
  static const Map<String, QuestBadgeRange> questBadgeRanges = {
    'Quake Quest': QuestBadgeRange(0, 14, 16),
    'Storm Quest': QuestBadgeRange(18, 32, 34),
    'Volcano Quest': QuestBadgeRange(40, 54, 56),
    'Drought Quest': QuestBadgeRange(58, 72, 74),
    'Tsunami Quest': QuestBadgeRange(76, 90, 92),
    'Flood Quest': QuestBadgeRange(94, 108, 110),
  };

  final ConnectionManager _connectionManager = ConnectionManager();
  final BadgeService _badgeService = BadgeService();

  // Add CacheCoordinator
  late final CacheCoordinator _cacheCoordinator;

  BadgeUnlockService._internal() : _authService = AuthService() {
    _cacheCoordinator = CacheCoordinator(_badgeService, _unlockCache);
    _startCacheManagement();
  }

  void _startCacheManagement() {
    Timer.periodic(const Duration(minutes: 30), (_) {
      _manageCacheSize();
      _cacheCoordinator.syncCacheVersions();
    });
  }

  void _manageCacheSize() {
    if (_unlockCache.length > MAX_CACHE_SIZE) {
      var entriesByAge = _unlockCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      // Remove invalid entries first
      entriesByAge.removeWhere((entry) => !entry.value.isValid);
      
      // Then remove oldest entries until we're under the limit
      while (_unlockCache.length > MAX_CACHE_SIZE) {
        var oldest = entriesByAge.removeAt(0);
        _unlockCache.remove(oldest.key);
      }
    }
  }

  void _addToCache(String questName, List<int> badges) {
    _unlockCache[questName] = UnlockCache(
      unlockedBadges: {questName: badges},
      timestamp: DateTime.now(),
      questName: questName,
    );
    _manageCacheSize();
  }

  List<int>? _getFromCache(String questName) {
    final cached = _unlockCache[questName];
    if (cached != null && cached.isValid) {
      return cached.unlockedBadges[questName];
    }
    return null;
  }

  Future<void> _unlockBadges(List<int> badgeIds, {
    required UnlockPriority priority,
    required String questName,
  }) async {
    if (badgeIds.isEmpty) return;
    print('🏅 Attempting to unlock badges: $badgeIds with priority: $priority');

    // Queue unlock requests
    for (var badgeId in badgeIds) {
      _unlockQueues[priority]!.add(UnlockRequest(
        badgeId: badgeId,
        priority: priority,
        questName: questName,
        timestamp: DateTime.now(),
      ));
    }

    // Process queues based on priority
    await _processUnlockQueues();
  }

  Future<void> _processUnlockQueues() async {
    try {
      // Process ACHIEVEMENT first
      await _processQueue(UnlockPriority.ACHIEVEMENT);
      // Then QUEST_COMPLETE
      await _processQueue(UnlockPriority.QUEST_COMPLETE);
      // Then MILESTONE
      await _processQueue(UnlockPriority.MILESTONE);
      // Finally REGULAR
      await _processQueue(UnlockPriority.REGULAR);
    } catch (e) {
      print('❌ Error processing unlock queues: $e');
    }
  }

  Future<void> _processQueue(UnlockPriority priority) async {
    final quality = await _connectionManager.checkConnectionQuality();
    final queue = _unlockQueues[priority]!;
    
    if (quality == ConnectionQuality.OFFLINE) {
      print('📡 Offline - Queuing unlock requests for later');
      return; // Keep requests in queue for later
    }

    while (queue.isNotEmpty) {
      final request = queue.removeFirst();
      try {
        // Get user profile with connection awareness
        UserProfile? profile;
        if (quality == ConnectionQuality.POOR) {
          // Try local first in poor connection
          profile = await _authService.getLocalUserProfile();
        }
        profile ??= await _authService.getUserProfile();
        if (profile == null) continue;

        // Check if badge is already unlocked
        if (profile.unlockedBadge.contains(request.badgeId)) {
          print('🏅 Badge ${request.badgeId} already unlocked');
          continue;
        }

        // Update unlocked badges
        List<int> updatedUnlockedBadges = List<int>.from(profile.unlockedBadge);
        updatedUnlockedBadges.add(request.badgeId);

        // Update profile
        await _authService.updateUserProfile('unlockedBadge', updatedUnlockedBadges);

        // Add to cache
        _addToCache(request.questName, [request.badgeId]);

        // Coordinate cache with BadgeService
        _badgeService.triggerBackgroundSync();
        
        // Add notification with connection awareness
        if (quality != ConnectionQuality.POOR) {
          _notificationQueue.addNotification(
            request.badgeId,
            request.priority,
            request.questName
          );
        }

        print('🎉 Successfully unlocked badge ${request.badgeId}');
      } catch (e) {
        print('❌ Error processing unlock request: $e');
        if (quality != ConnectionQuality.EXCELLENT) {
          // Re-queue on poor connection
          queue.addFirst(request);
          break;
        }
      }
    }
  }

  // Check Adventure Mode badges
  Future<void> checkAdventureBadges({
    required String questName,
    required String stageName,
    required String difficulty,
    required int stars,
    required List<int> allStageStars,
  }) async {
    try {
      print('🎮 Checking adventure badges for $questName, $stageName');
      
      // Get stage number and update stars array
      int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
      List<int> updatedStageStars = List<int>.from(allStageStars);
      if (stageNumber < updatedStageStars.length) {
        updatedStageStars[stageNumber] = stars;
      }

      UserProfile? profile = await _authService.getUserProfile();
      if (profile == null) return;

      final questRange = questBadgeRanges[questName];
      if (questRange == null) return;

      // Group badges by priority
      Map<UnlockPriority, List<int>> prioritizedBadges = {
        UnlockPriority.ACHIEVEMENT: [],
        UnlockPriority.QUEST_COMPLETE: [],
        UnlockPriority.MILESTONE: [],
        UnlockPriority.REGULAR: [],
      };
      
      // 1. Stage badge (REGULAR priority)
      int stageBadgeId = questRange.stageStart + (stageNumber * 2) + (difficulty == 'hard' ? 1 : 0);
      if (stars > 0) {
        prioritizedBadges[UnlockPriority.REGULAR]!.add(stageBadgeId);
      }
      
      // 2. Complete badge (QUEST_COMPLETE priority)
      if (_hasAllStagesCleared(updatedStageStars)) {
        int completeBadgeId = difficulty == 'hard' 
            ? questRange.completeStart + 1
            : questRange.completeStart;
        prioritizedBadges[UnlockPriority.QUEST_COMPLETE]!.add(completeBadgeId);
      }
      
      // 3. Full clear badge (ACHIEVEMENT priority)
      if (_hasAllStagesFullyCleared(updatedStageStars)) {
        int fullClearBadgeId = difficulty == 'hard'
            ? questRange.fullClearStart + 1
            : questRange.fullClearStart;
        prioritizedBadges[UnlockPriority.ACHIEVEMENT]!.add(fullClearBadgeId);
      }

      // Unlock badges by priority
      for (var priority in UnlockPriority.values) {
        if (prioritizedBadges[priority]!.isNotEmpty) {
          await _unlockBadges(
            prioritizedBadges[priority]!,
            priority: priority,
            questName: questName
          );
        }
      }
    } catch (e) {
      print('❌ Error checking adventure badges: $e');
    }
  }

  // Check Arcade Mode badges
  Future<void> checkArcadeBadges({
    required int totalTime,
    required double accuracy,
    required int streak,
    required double averageTimePerQuestion,
  }) async {
    try {
      Map<UnlockPriority, List<int>> prioritizedBadges = {
        UnlockPriority.ACHIEVEMENT: [],
        UnlockPriority.MILESTONE: [],
        UnlockPriority.REGULAR: [],
      };

      // Perfect Accuracy - ACHIEVEMENT priority
      if (accuracy >= 100) {
        prioritizedBadges[UnlockPriority.ACHIEVEMENT]!.add(37);
      }
      
      // Speed Demon and Quick Thinker - MILESTONE priority
      if (totalTime <= 120) {
        prioritizedBadges[UnlockPriority.MILESTONE]!.add(36);
      }
      if (averageTimePerQuestion <= 15) {
        prioritizedBadges[UnlockPriority.MILESTONE]!.add(39);
      }
      
      // Streak Master - REGULAR priority
      if (streak >= 15) {
        prioritizedBadges[UnlockPriority.REGULAR]!.add(38);
      }

      // Unlock badges by priority
      for (var priority in UnlockPriority.values) {
        if (prioritizedBadges[priority]!.isNotEmpty) {
          await _unlockBadges(
            prioritizedBadges[priority]!,
            priority: priority,
            questName: 'Arcade Quest'
          );
        }
      }
    } catch (e) {
      print('Error checking arcade badges: $e');
    }
  }

  bool _hasAllStagesCleared(List<int> stageStars) {
    // Check if all stages have at least 1 star (excluding last arcade stage)
    print('🌟 Checking all stages cleared');
    print('Stage stars: $stageStars');
    // Get all stages except the last one
    List<int> normalStages = stageStars.sublist(0, stageStars.length - 1);
    print('Checking normal stages (excluding arcade): $normalStages');
    bool allCleared = !normalStages.contains(0);
    print('All stages cleared: $allCleared');
    return allCleared;
  }

  bool _hasAllStagesFullyCleared(List<int> stageStars) {
    // Check if all stages have 3 stars (excluding last arcade stage)
    print('⭐ Checking all stages fully cleared');
    print('Stage stars: $stageStars');
    // Get all stages except the last one
    List<int> normalStages = stageStars.sublist(0, stageStars.length - 1);
    print('Checking normal stages (excluding arcade): $normalStages');
    bool allFullyCleared = normalStages.every((stars) => stars == 3);
    print('All stages fully cleared: $allFullyCleared');
    return allFullyCleared;
  }

  // Getters and setters for notification handling
  static NotificationBatch? getNextNotificationBatch() {
    return _notificationQueue.getNextBatch();
  }
  
  static bool get hasNotifications => 
    _notificationQueue.hasPendingNotifications;
  
  static bool get isShowingNotification => _isShowingNotification;
  
  static set isShowingNotification(bool value) {
    _isShowingNotification = value;
  }

  static Queue<int> get pendingNotifications {
    final currentBatch = _notificationQueue.getNextBatch();
    if (currentBatch != null) {
      return Queue<int>.from(currentBatch.badgeIds);
    }
    return Queue<int>();
  }

  // Update cache invalidation to use coordinator
  void _invalidateCache(String questName) {
    _cacheCoordinator.invalidateSharedCaches(questName);
  }

  // Add to existing fields
  static const String OFFLINE_QUEUE_KEY = 'offline_unlock_queue';
  static const int MAX_RETRY_ATTEMPTS = 5;
  static final Map<String, OfflineUnlockQueue> _offlineQueues = {};

  // Add new method for offline queue management
  Future<void> _processOfflineQueues() async {
    final quality = await _connectionManager.checkConnectionQuality();
    if (quality == ConnectionQuality.OFFLINE) return;

    for (var queue in _offlineQueues.values) {
      if (queue.retryCount >= MAX_RETRY_ATTEMPTS) {
        // Log failed attempts and remove from queue
        print('❌ Max retries reached for quest ${queue.questName}');
        continue;
      }

      try {
        for (var request in queue.pendingUnlocks) {
          await _unlockBadges(
            [request.badgeId],
            priority: request.priority,
            questName: request.questName,
          );
        }
        // Remove successful queue
        _offlineQueues.remove(queue.questName);
      } catch (e) {
        print('❌ Error processing offline queue: $e');
        // Increment retry count
        _offlineQueues[queue.questName] = OfflineUnlockQueue(
          questName: queue.questName,
          pendingUnlocks: queue.pendingUnlocks,
          queuedAt: queue.queuedAt,
          retryCount: queue.retryCount + 1,
        );
      }
    }
  }
}

// Add new class for offline persistence
class OfflineUnlockQueue {
  final String questName;
  final List<UnlockRequest> pendingUnlocks;
  final DateTime queuedAt;
  final int retryCount;
  
  OfflineUnlockQueue({
    required this.questName,
    required this.pendingUnlocks,
    required this.queuedAt,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() => {
    'questName': questName,
    'pendingUnlocks': pendingUnlocks.map((r) => {
      'badgeId': r.badgeId,
      'priority': r.priority.toString(),
      'timestamp': r.timestamp.toIso8601String(),
    }).toList(),
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  static OfflineUnlockQueue fromJson(Map<String, dynamic> json) {
    return OfflineUnlockQueue(
      questName: json['questName'],
      pendingUnlocks: (json['pendingUnlocks'] as List).map((u) => UnlockRequest(
        badgeId: u['badgeId'],
        priority: UnlockPriority.values.firstWhere(
          (p) => p.toString() == u['priority']
        ),
        questName: json['questName'],
        timestamp: DateTime.parse(u['timestamp']),
      )).toList(),
      queuedAt: DateTime.parse(json['queuedAt']),
      retryCount: json['retryCount'],
    );
  }
} 