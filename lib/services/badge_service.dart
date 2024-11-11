import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:collection';
import 'package:handabatamae/shared/connection_quality.dart';

// Move these classes before BadgeService class
class BadgeVersion {
  final int revision;
  final String hash;
  final DateTime timestamp;
  
  BadgeVersion({
    required this.revision,
    required this.hash,
    required this.timestamp,
  });
}

class BadgeChange {
  final int badgeId;
  final String changeType;  // 'add', 'update', 'delete'
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  
  BadgeChange({
    required this.badgeId,
    required this.changeType,
    this.oldData,
    this.newData,
  });
}

class CachedBadge {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedBadge(this.data, this.timestamp);
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

// Add Priority enum
enum BadgePriority {
  CURRENT_QUEST,    // Current quest badges
  SHOWCASE,         // User's showcased badges
  NEXT_QUEST,       // Next quest's badges
  BACKGROUND,       // Other badges
  HIGH,             // High priority badges
  MEDIUM,           // Medium priority badges
  LOW,              // Low priority badges
}

// Add Quest Cache structure
class QuestBadgeCache {
  final String questName;
  final List<int> badgeIds;
  final DateTime timestamp;
  
  QuestBadgeCache({
    required this.questName,
    required this.badgeIds,
    required this.timestamp,
  });
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

// Add after existing enums and classes
class BatchSyncOperation {
  final String operation;  // 'add', 'update', 'delete'
  final List<int> badgeIds;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  BatchSyncOperation({
    required this.operation,
    required this.badgeIds,
    required this.timestamp,
    required this.data,
  });
}

class BatchQueue {
  static const int maxBatchSize = 10;
  static const Duration batchWindow = Duration(milliseconds: 500);
  
  final Queue<BatchSyncOperation> operations = Queue<BatchSyncOperation>();
  final BadgeService _badgeService;  // Add reference to BadgeService
  
  BatchQueue(this._badgeService);  // Add constructor

  Future<void> _processOperationGroup(String operation, List<BatchSyncOperation> ops) async {
    try {
      switch (operation) {
        case 'add':
          await _processBatchAdd(ops);
          break;
        case 'update':
          await _processBatchUpdate(ops);
          break;
        case 'delete':
          await _processBatchDelete(ops);
          break;
      }
    } catch (e) {
      print('Error processing batch operation group: $e');
    }
  }

  Future<void> _processBatchAdd(List<BatchSyncOperation> ops) async {
    try {
      // Group all badges to add
      final allBadges = ops.expand((op) => op.data['badges'] as List).toList();
      
      // Add in single operation
      DocumentSnapshot doc = await _badgeService._badgeDoc.get();
      List<Map<String, dynamic>> existingBadges = [];
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        existingBadges = data['badges'] != null ? 
            List<Map<String, dynamic>>.from(data['badges']) : [];
      }

      existingBadges.addAll(allBadges.cast<Map<String, dynamic>>());

      await _badgeService._badgeDoc.set({
        'badges': existingBadges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Update cache for all added badges
      for (var badge in allBadges) {
        _badgeService._addToCache(badge['id'], badge as Map<String, dynamic>);
      }

      _badgeService._badgeUpdateController.add(existingBadges);
    } catch (e) {
      print('Error in batch add: $e');
    }
  }

  Future<void> _processBatchUpdate(List<BatchSyncOperation> ops) async {
    try {
      DocumentSnapshot doc = await _badgeService._badgeDoc.get();
      if (!doc.exists) return;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> badges = 
          List<Map<String, dynamic>>.from(data['badges'] ?? []);

      // Update all badges in single operation
      for (var op in ops) {
        for (var id in op.badgeIds) {
          int index = badges.indexWhere((b) => b['id'] == id);
          if (index != -1) {
            badges[index] = op.data;
            _badgeService._addToCache(id, op.data);
          }
        }
      }

      await _badgeService._badgeDoc.update({
        'badges': badges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      _badgeService._badgeUpdateController.add(badges);
    } catch (e) {
      print('Error in batch update: $e');
    }
  }

  Future<void> _processBatchDelete(List<BatchSyncOperation> ops) async {
    try {
      DocumentSnapshot doc = await _badgeService._badgeDoc.get();
      if (!doc.exists) return;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> badges = 
          List<Map<String, dynamic>>.from(data['badges'] ?? []);

      // Get all IDs to delete
      final idsToDelete = ops.expand((op) => op.badgeIds).toSet();

      // Remove badges in single operation
      badges.removeWhere((b) => idsToDelete.contains(b['id']));

      await _badgeService._badgeDoc.update({
        'badges': badges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Update cache - Fix: Access static members through class
      for (var id in idsToDelete) {
        BadgeService._badgeCache.remove(id);
      }
      BadgeService._batchCache.clear();

      _badgeService._badgeUpdateController.add(badges);
    } catch (e) {
      print('Error in batch delete: $e');
    }
  }
}

// Move ViewportInfo and ProgressiveLoadManager to top level
class ViewportInfo {
  final int startIndex;
  final int endIndex;
  final double viewportHeight;
  
  ViewportInfo({
    required this.startIndex,
    required this.endIndex,
    required this.viewportHeight,
  });
}

class ProgressiveLoadManager {
  static const int BATCH_SIZE = 10;
  static const Duration LOAD_DELAY = Duration(milliseconds: 100);
  
  final BadgeService _badgeService;
  final Map<String, List<int>> _loadedBatches = {};
  Timer? _loadTimer;
  
  ProgressiveLoadManager(this._badgeService);

  Future<void> handleViewportChange(
    ViewportInfo viewport,
    String questName,
  ) async {
    _loadTimer?.cancel();
    _loadTimer = Timer(LOAD_DELAY, () {
      _loadBadgesInViewport(viewport, questName);
    });
  }

  Future<void> _loadBadgesInViewport(
    ViewportInfo viewport,
    String questName,
  ) async {
    try {
      final requiredIds = List.generate(
        viewport.endIndex - viewport.startIndex + 1,
        (i) => viewport.startIndex + i,
      ).toSet();

      if (_loadedBatches[questName]?.toSet().intersection(requiredIds).length == requiredIds.length) {
        return;
      }

      // Load visible badges with HIGH priority
      final visibleBadges = await _badgeService.fetchBadgesWithPriority(
        questName,
        [],
        priority: BadgePriority.HIGH,
      );

      // Queue adjacent badges with MEDIUM priority
      final adjacentStart = (viewport.startIndex - BATCH_SIZE).clamp(0, visibleBadges.length);
      final adjacentEnd = (viewport.endIndex + BATCH_SIZE).clamp(0, visibleBadges.length);
      
      for (var i = adjacentStart; i < adjacentEnd; i++) {
        if (i < viewport.startIndex || i > viewport.endIndex) {
          _badgeService.queueBadgeLoad(
            visibleBadges[i]['id'],
            BadgePriority.MEDIUM,
          );
        }
      }

      // Track loaded badges
      _loadedBatches[questName] ??= [];
      _loadedBatches[questName]!.addAll(
        visibleBadges.map((b) => b['id'] as int),
      );

    } catch (e) {
      print('Error in progressive loading: $e');
    }
  }

  void clearLoadedBatches(String questName) {
    _loadedBatches.remove(questName);
  }
}

class BadgeService {
  // Singleton pattern
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;

  final DocumentReference _badgeDoc = FirebaseFirestore.instance.collection('Game').doc('Badge');
  
  // Cache constants
  static const String BADGES_CACHE_KEY = 'badges_cache';
  static const String BADGE_VERSION_KEY = 'badge_version';
  static const String BADGE_REVISION_KEY = 'badge_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;
  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  static const Duration CACHE_DURATION = Duration(hours: 1);

  // Shared memory cache
  static final Map<int, CachedBadge> _badgeCache = {};
  static final Map<String, CachedBadge> _batchCache = {};

  // Sync management
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  // Stream controllers
  final _badgeUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get badgeUpdates => _badgeUpdateController.stream;

  // Add to existing cache structures
  static final Map<String, QuestBadgeCache> _questCache = {};
  
  // Add priority queue
  final Map<BadgePriority, Queue<int>> _loadQueues = {
    BadgePriority.CURRENT_QUEST: Queue<int>(),
    BadgePriority.SHOWCASE: Queue<int>(),
    BadgePriority.NEXT_QUEST: Queue<int>(),
    BadgePriority.BACKGROUND: Queue<int>(),
    BadgePriority.HIGH: Queue<int>(),
    BadgePriority.MEDIUM: Queue<int>(),
    BadgePriority.LOW: Queue<int>(),
  };

  final ProgressiveLoadManager _progressiveLoader;

  final ConnectionManager _connectionManager = ConnectionManager();

  BadgeService._internal() 
      : _progressiveLoader = ProgressiveLoadManager(_instance) {
    _startQueueProcessing();
  }

  // Cache management methods
  void _addToCache(int id, Map<String, dynamic> data) {
    _badgeCache[id] = CachedBadge(data, DateTime.now());
    _manageCacheSize();
  }

  void _manageCacheSize() {
    if (_badgeCache.length > MAX_CACHE_SIZE) {
      var entriesByAge = _badgeCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      for (var entry in entriesByAge) {
        if (_badgeCache.length <= MAX_CACHE_SIZE) break;
        if (!entry.value.isValid) {
          _badgeCache.remove(entry.key);
        }
      }
      
      while (_badgeCache.length > MAX_CACHE_SIZE) {
        var oldest = entriesByAge.removeAt(0);
        _badgeCache.remove(oldest.key);
      }
    }
    
    // Also manage version cache
    if (_versionCache.length > MAX_CACHE_SIZE) {
      var oldVersions = _versionCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      while (_versionCache.length > MAX_CACHE_SIZE) {
        var oldest = oldVersions.removeAt(0);
        _versionCache.remove(oldest.key);
      }
    }
  }

  // Update getBadgeDetails to use cache
  Future<Map<String, dynamic>?> getBadgeDetails(int id) async {
    try {
      // Check memory cache first
      if (_badgeCache.containsKey(id) && _badgeCache[id]!.isValid) {
        return _badgeCache[id]!.data;
      }

      final quality = await _connectionManager.checkConnectionQuality();
      
      // Check local storage if offline or poor connection
      if (quality == ConnectionQuality.OFFLINE || quality == ConnectionQuality.POOR) {
        List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
        var badge = localBadges.firstWhere(
          (b) => b['id'] == id,
          orElse: () => {},
        );

        if (badge.isNotEmpty) {
          _addToCache(id, badge);
          return badge;
        }
      }

      // Only fetch from server if connection is good
      if (quality != ConnectionQuality.OFFLINE) {
        DocumentSnapshot doc = await _badgeDoc.get()
            .timeout(SYNC_TIMEOUT);
            
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> badges = 
              List<Map<String, dynamic>>.from(data['badges'] ?? []);
              
          var serverBadge = badges.firstWhere(
            (b) => b['id'] == id,
            orElse: () => {},
          );
          
          if (serverBadge.isNotEmpty) {
            _addToCache(id, serverBadge);
            return serverBadge;
          }
        }
      }

      return _badgeCache[id]?.data; // Return cached data even if expired
    } catch (e) {
      print('Error in getBadgeDetails: $e');
      return _badgeCache[id]?.data; // Return cached data on error
    }
  }

  // Add fetchBadges method
  Future<List<Map<String, dynamic>>> fetchBadges({bool isAdmin = false}) async {
    try {
      final cacheKey = 'all_badges${isAdmin ? '_admin' : ''}';
      
      // Check batch cache first
      if (_batchCache.containsKey(cacheKey) && _batchCache[cacheKey]!.isValid) {
        return List<Map<String, dynamic>>.from(_batchCache[cacheKey]!.data['badges']);
      }

      // Get from local storage first
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      
      // If local storage is empty, try fetching from server
      if (localBadges.isEmpty) {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot snapshot = await _badgeDoc.get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            localBadges = data['badges'] != null ? 
                List<Map<String, dynamic>>.from(data['badges']) : [];
            
            // Update caches and local storage
            _batchCache[cacheKey] = CachedBadge({'badges': localBadges}, DateTime.now());
            for (var badge in localBadges) {
              _addToCache(badge['id'], badge);
            }
            await _storeBadgesLocally(localBadges);
          }
        }
      }
      
      return localBadges;
    } catch (e) {
      print('Error in fetchBadges: $e');
      return [];
    }
  }

  // Add getBadgeById method
  Future<bool> getBadgeById(int id) async {
    final badge = await getBadgeDetails(id);
    return badge != null;
  }

  // Add getLocalBadges method
  Future<List<Map<String, dynamic>>> getLocalBadges() async {
    return _getBadgesFromLocal();
  }

  // Add _getBadgesFromLocal method
  Future<List<Map<String, dynamic>>> _getBadgesFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? badgesJson = prefs.getString(BADGES_CACHE_KEY);
      if (badgesJson != null) {
        List<dynamic> decoded = jsonDecode(badgesJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting badges from local: $e');
      return [];
    }
  }

  // Add _storeBadgesLocally method
  Future<void> _storeBadgesLocally(List<Map<String, dynamic>> badges) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? existingData = prefs.getString(BADGES_CACHE_KEY);
      if (existingData != null) {
        await prefs.setString('${BADGES_CACHE_KEY}_backup', existingData);
      }
      await prefs.setString(BADGES_CACHE_KEY, jsonEncode(badges));
    } catch (e) {
      print('Error storing badges locally: $e');
    }
  }

  // Add _startQueueProcessing method
  Future<void> _startQueueProcessing() async {
    while (true) {
      try {
        // Process queues based on priority
        await _processQueue(BadgePriority.CURRENT_QUEST);
        await _processQueue(BadgePriority.SHOWCASE);
        await _processQueue(BadgePriority.NEXT_QUEST);
        await _processQueue(BadgePriority.BACKGROUND);
        
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Error processing queue: $e');
      }
    }
  }

  Future<void> _processQueue(BadgePriority priority) async {
    final queue = _loadQueues[priority]!;
    while (queue.isNotEmpty) {
      final badgeId = queue.removeFirst();
      try {
        // Load badge based on priority
        switch (priority) {
          case BadgePriority.CURRENT_QUEST:
            await getBadgeDetails(badgeId);
            break;
          case BadgePriority.HIGH:
            await getBadgeDetails(badgeId);
            break;
          case BadgePriority.MEDIUM:
            if (_badgeCache.containsKey(badgeId)) continue;
            await getBadgeDetails(badgeId);
            break;
          case BadgePriority.LOW:
            if (_badgeCache.containsKey(badgeId)) continue;
            await getBadgeDetails(badgeId);
            break;
          case BadgePriority.SHOWCASE:
          case BadgePriority.NEXT_QUEST:
          case BadgePriority.BACKGROUND:
            if (_badgeCache.containsKey(badgeId)) continue;
            await getBadgeDetails(badgeId);
            break;
        }
      } catch (e) {
        print('Error processing badge $badgeId: $e');
      }
    }
  }

  // Add method to queue badge loading
  void queueBadgeLoad(int badgeId, BadgePriority priority) {
    if (!_loadQueues[priority]!.contains(badgeId)) {
      _loadQueues[priority]!.add(badgeId);
    }
  }

  // Add helper method
  void _setSyncState(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(syncing);
  }

  // Add these CRUD methods back to BadgeService class

  // Add badge
  Future<void> addBadge(Map<String, dynamic> badge) async {
    try {
      DocumentSnapshot doc = await _badgeDoc.get();
      List<Map<String, dynamic>> badges = [];
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        badges = data['badges'] != null ? 
            List<Map<String, dynamic>>.from(data['badges']) : [];
      }

      int newId = badges.isEmpty ? 0 : 
          badges.map((b) => b['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      
      badge['id'] = newId;
      badges.add(badge);

      await _badgeDoc.set({
        'badges': badges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Update cache
      _addToCache(newId, badge);
      _badgeUpdateController.add(badges);
    } catch (e) {
      print('Error adding badge: $e');
      rethrow;
    }
  }

  // Update badge
  Future<void> updateBadge(int id, Map<String, dynamic> updatedBadge) async {
    try {
      DocumentSnapshot doc = await _badgeDoc.get();
      if (!doc.exists) throw Exception('Badge document not found');

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> badges = 
          List<Map<String, dynamic>>.from(data['badges'] ?? []);

      int index = badges.indexWhere((b) => b['id'] == id);
      if (index == -1) throw Exception('Badge not found');

      updatedBadge['id'] = id;
      badges[index] = updatedBadge;

      await _badgeDoc.update({
        'badges': badges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Update cache
      _addToCache(id, updatedBadge);
      _badgeUpdateController.add(badges);
    } catch (e) {
      print('Error updating badge: $e');
      rethrow;
    }
  }

  // Delete badge
  Future<void> deleteBadge(int id) async {
    try {
      DocumentSnapshot doc = await _badgeDoc.get();
      if (!doc.exists) throw Exception('Badge document not found');

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> badges = 
          List<Map<String, dynamic>>.from(data['badges'] ?? []);

      badges.removeWhere((b) => b['id'] == id);

      await _badgeDoc.update({
        'badges': badges,
        'revision': FieldValue.increment(1),
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Update cache
      _badgeCache.remove(id);
      _batchCache.clear(); // Clear batch cache as it might contain deleted badge
      _badgeUpdateController.add(badges);
    } catch (e) {
      print('Error deleting badge: $e');
      rethrow;
    }
  }

  // Add these methods to BadgeService class

  // Add sync methods
  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Badge sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting badge sync process');
      _setSyncState(true);

      final quality = await _connectionManager.checkConnectionQuality();
      if (quality == ConnectionQuality.OFFLINE) {
        print('📡 No internet connection, aborting badge sync');
        return;
      }

      print('📥 Fetching badge data from server');
      DocumentSnapshot snapshot = await _badgeDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) {
        print('❌ Badge document not found on server');
        return;
      }

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      print('📊 Server revision: $serverRevision, Local revision: $localRevision');

      if (localRevision == null || serverRevision > localRevision) {
        print('🔄 Server has newer data, updating local cache');
        List<Map<String, dynamic>> serverBadges = 
            await _fetchAndUpdateLocal(snapshot);
        
        print('💾 Updating memory cache with ${serverBadges.length} badges');
        for (var badge in serverBadges) {
          _addToCache(badge['id'], badge);
        }

        print('📢 Notifying listeners of badge updates');
        _badgeUpdateController.add(serverBadges);
      } else {
        print('✅ Local badge data is up to date');
      }

    } catch (e) {
      print('❌ Error in badge sync: $e');
    } finally {
      print('🏁 Badge sync process completed');
      _setSyncState(false);
    }
  }

  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(SYNC_DEBOUNCE, () {
      _syncWithServer();
    });
  }

  // Add revision management
  Future<int?> _getLocalRevision() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(BADGE_REVISION_KEY);
    } catch (e) {
      print('Error getting local revision: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(DocumentSnapshot snapshot) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> badges = 
        data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
    
    await _storeBadgesLocally(badges);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    
    return badges;
  }

  Future<void> _storeLocalRevision(int revision) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(BADGE_REVISION_KEY, revision);
    } catch (e) {
      print('Error storing local revision: $e');
    }
  }

  // Add public method for background sync
  void triggerBackgroundSync() {
    _debouncedSync();
  }

  // Add new method for priority-based fetching
  Future<List<Map<String, dynamic>>> fetchBadgesWithPriority(
    String currentQuest,
    List<int> showcaseBadges, {
    BadgePriority priority = BadgePriority.BACKGROUND
  }) async {
    try {
      switch (priority) {
        case BadgePriority.CURRENT_QUEST:
          final questBadges = await _fetchQuestBadges(currentQuest);
          for (var badge in questBadges) {
            queueBadgeLoad(badge['id'], BadgePriority.CURRENT_QUEST);
          }
          return questBadges;
        
        case BadgePriority.SHOWCASE:
          for (var id in showcaseBadges) {
            queueBadgeLoad(id, BadgePriority.SHOWCASE);
          }
          return _fetchShowcaseBadges(showcaseBadges);
        
        case BadgePriority.NEXT_QUEST:
          final nextQuest = _getNextQuest(currentQuest);
          if (nextQuest != null) {
            final nextQuestBadges = await _fetchQuestBadges(nextQuest);
            for (var badge in nextQuestBadges) {
              queueBadgeLoad(badge['id'], BadgePriority.NEXT_QUEST);
            }
            return nextQuestBadges;
          }
          return [];
        
        case BadgePriority.BACKGROUND:
          final badges = await fetchBadges();
          for (var badge in badges) {
            queueBadgeLoad(badge['id'], BadgePriority.BACKGROUND);
          }
          return badges;
        case BadgePriority.HIGH:
          final badges = await fetchBadges();
          for (var badge in badges) {
            queueBadgeLoad(badge['id'], BadgePriority.HIGH);
          }
          return badges;
        case BadgePriority.MEDIUM:
        case BadgePriority.LOW:
          final badges = await fetchBadges();
          for (var badge in badges) {
            queueBadgeLoad(badge['id'], priority);
          }
          return badges;
      }
    } catch (e) {
      print('Error in fetchBadgesWithPriority: $e');
    }
    return [];
  }

  // Add helper methods for different priority fetches
  Future<List<Map<String, dynamic>>> _fetchQuestBadges(String questName) async {
    try {
      final badges = await fetchBadges();
      final questBadges = badges.where((badge) => 
        (badge['img'] as String).contains(questName.toLowerCase())).toList();
      
      // Update quest cache
      _questCache[questName] = QuestBadgeCache(
        questName: questName,
        badgeIds: questBadges.map((b) => b['id'] as int).toList(),
        timestamp: DateTime.now(),
      );
      
      return questBadges;
    } catch (e) {
      print('Error fetching quest badges: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchShowcaseBadges(List<int> badgeIds) async {
    try {
      final badges = await Future.wait(
        badgeIds.map((id) => getBadgeDetails(id))
      );
      return badges.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching showcase badges: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNextQuestBadges(String currentQuest) async {
    try {
      // Logic to determine next quest based on current quest
      final nextQuest = _getNextQuest(currentQuest);
      if (nextQuest != null) {
        return _fetchQuestBadges(nextQuest);
      }
      return [];
    } catch (e) {
      print('Error fetching next quest badges: $e');
      return [];
    }
  }

  // Helper method to determine next quest
  String? _getNextQuest(String currentQuest) {
    final quests = [
      'Quake Quest',
      'Storm Quest',
      'Volcano Quest',
      'Drought Quest',
      'Tsunami Quest',
      'Flood Quest'
    ];
    
    final currentIndex = quests.indexOf(currentQuest);
    if (currentIndex != -1 && currentIndex < quests.length - 1) {
      return quests[currentIndex + 1];
    }
    return null;
  }

  // Add method to handle viewport changes
  void handleViewportChange(ViewportInfo viewport, String questName) {
    _progressiveLoader.handleViewportChange(viewport, questName);
  }

  // Add method to clear progressive loading state
  void clearProgressiveLoadingState(String questName) {
    _progressiveLoader.clearLoadedBatches(questName);
  }

  // Add version tracking
  static final Map<int, BadgeVersion> _versionCache = {};
  
  // Add differential sync methods
  Future<List<BadgeChange>> _getChanges(DocumentSnapshot serverSnapshot) async {
    try {
      List<BadgeChange> changes = [];
      Map<String, dynamic> data = serverSnapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> serverBadges = 
          List<Map<String, dynamic>>.from(data['badges'] ?? []);
      
      // Get local badges
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      
      // Create maps for easier comparison
      Map<int, Map<String, dynamic>> localMap = {
        for (var badge in localBadges) badge['id'] as int: badge
      };
      Map<int, Map<String, dynamic>> serverMap = {
        for (var badge in serverBadges) badge['id'] as int: badge
      };
      
      // Find changes
      for (var serverId in serverMap.keys) {
        if (!localMap.containsKey(serverId)) {
          // Added badge
          changes.add(BadgeChange(
            badgeId: serverId,
            changeType: 'add',
            newData: serverMap[serverId],
          ));
        } else if (_hasChanged(localMap[serverId]!, serverMap[serverId]!)) {
          // Updated badge
          changes.add(BadgeChange(
            badgeId: serverId,
            changeType: 'update',
            oldData: localMap[serverId],
            newData: serverMap[serverId],
          ));
        }
      }
      
      // Find deleted badges
      for (var localId in localMap.keys) {
        if (!serverMap.containsKey(localId)) {
          changes.add(BadgeChange(
            badgeId: localId,
            changeType: 'delete',
            oldData: localMap[localId],
          ));
        }
      }
      
      return changes;
    } catch (e) {
      print('Error getting changes: $e');
      return [];
    }
  }

  bool _hasChanged(Map<String, dynamic> local, Map<String, dynamic> server) {
    int badgeId = local['id'] as int;
    String newHash = _computeHash(server);
    
    // Check version cache
    if (_versionCache.containsKey(badgeId)) {
      bool hasChanged = _versionCache[badgeId]!.hash != newHash;
      if (hasChanged) {
        // Update version cache with new version
        _versionCache[badgeId] = BadgeVersion(
          revision: _versionCache[badgeId]!.revision + 1,
          hash: newHash,
          timestamp: DateTime.now(),
        );
      }
      return hasChanged;
    }
    
    // First time seeing this badge
    _versionCache[badgeId] = BadgeVersion(
      revision: 1,
      hash: newHash,
      timestamp: DateTime.now(),
    );
    return true;
  }

  String _computeHash(Map<String, dynamic> data) {
    // Simple hash function for demonstration
    return jsonEncode(data).hashCode.toString();
  }

  // Update sync method to use differential updates
  Future<void> _syncWithServerDifferential() async {
    if (_isSyncing) {
      print('🔄 Badge sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting badge sync process');
      _setSyncState(true);

      DocumentSnapshot snapshot = await _badgeDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) return;

      // Get only changed badges
      List<BadgeChange> changes = await _getChanges(snapshot);
      
      if (changes.isEmpty) {
        print('✅ No changes detected');
        return;
      }

      print('📝 Applying ${changes.length} changes');
      
      // Apply changes to cache and storage
      for (var change in changes) {
        switch (change.changeType) {
          case 'add':
          case 'update':
            if (change.newData != null) {
              _addToCache(change.badgeId, change.newData!);
            }
            break;
          case 'delete':
            _badgeCache.remove(change.badgeId);
            break;
        }
      }

      // Update local storage
      List<Map<String, dynamic>> updatedBadges = await _getBadgesFromLocal();
      await _storeBadgesLocally(updatedBadges);
      
      // Notify listeners
      _badgeUpdateController.add(updatedBadges);
      
    } catch (e) {
      print('❌ Error in differential sync: $e');
    } finally {
      _setSyncState(false);
    }
  }
}
