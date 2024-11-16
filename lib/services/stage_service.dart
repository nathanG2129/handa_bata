import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/models/stage_models.dart';

class StageService {
  static final StageService _instance = StageService._internal();
  factory StageService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentReference _stageDoc = FirebaseFirestore.instance.collection('Game').doc('Stage');
  static const String STAGES_CACHE_KEY = 'stages_cache';
  static const String CATEGORIES_CACHE_KEY = 'categories_cache';
  static const String STAGE_REVISION_KEY = 'stage_revision';
  static const String STAGES_CACHE_KEY_PREFIX = 'stages_';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;

// New cache structure using CachedStage
final Map<String, CachedStage> _stageCache = {};
final Map<String, CachedStage> _categoryCache = {};

  // Stream controllers for real-time updates
  final _stageUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get stageUpdates => _stageUpdateController.stream;

  final _categoryUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get categoryUpdates => _categoryUpdateController.stream;

  // Add defaultLanguage field
  static const String defaultLanguage = 'en';

  // Add these new fields at the top of the StageService class
  static const String SYNC_STATUS_KEY = 'stage_sync_status';
  static const String LAST_SYNC_KEY = 'stage_last_sync';
  static const Duration SYNC_INTERVAL = Duration(hours: 1);
  
  // Add a sync queue for offline changes
  final List<Map<String, dynamic>> _syncQueue = [];
  bool _isSyncing = false;

  // Add sync status tracking
  Future<void> _updateSyncStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SYNC_STATUS_KEY, status);
    await prefs.setInt(LAST_SYNC_KEY, DateTime.now().millisecondsSinceEpoch);
  }

  // Add method to check if sync is needed
  Future<bool> _shouldSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(LAST_SYNC_KEY) ?? 0;
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    return DateTime.now().difference(lastSyncTime) > SYNC_INTERVAL;
  }

  // Add new synchronization method
  Future<void> synchronizeData() async {
    if (_isSyncing) {
      print('🔄 Stage sync already in progress, skipping...');
      return;
    }
    _isSyncing = true;

    try {
      print('🔄 Starting stage sync process');
      await _updateSyncStatus('syncing');
      
      // Process offline queue first
      print('📤 Processing offline queue');
      await _processSyncQueue();

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        print('📥 Fetching latest stage data from server');
        // Fetch latest data from server
        final serverData = await _fetchServerData();
        
        print('🔄 Resolving data conflicts');
        // Compare with local data and resolve conflicts
        await _resolveDataConflicts(serverData);
        
        print('💾 Updating local storage with resolved data');
        // Update local storage with resolved data
        await _updateLocalStorage(serverData);
        
        print('✅ Stage sync completed successfully');
        await _updateSyncStatus('completed');
      } else {
        print('📡 No internet connection, marking sync as offline');
        await _updateSyncStatus('offline');
      }
    } catch (e) {
      print('❌ Error during stage sync: $e');
      await _updateSyncStatus('error');
    } finally {
      print('🏁 Stage sync process completed');
      _isSyncing = false;
    }
  }

  // Add method to process sync queue
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty) {
      print('✅ No pending changes in sync queue');
      return;
    }

    print('🔄 Processing ${_syncQueue.length} queued changes');
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      print('📤 Sending queued changes to server');
      final batch = FirebaseFirestore.instance.batch();
      
      for (var change in _syncQueue) {
        print('📝 Processing change: ${change['type']}');
        switch (change['type']) {
          case 'update':
            batch.update(_stageDoc, change['data']);
            break;
          case 'delete':
            batch.delete(_stageDoc.collection(change['collection']).doc(change['id']));
            break;
        }
      }

      print('💾 Committing batch updates');
      await batch.commit();
      _syncQueue.clear();
      
      print('🔄 Updating local sync status');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('pending_stage_changes', []);
      
      print('✅ Sync queue processed successfully');
    } else {
      print('📡 No internet connection, keeping changes in queue');
    }
  }

  // Add method to fetch server data
  Future<Map<String, dynamic>> _fetchServerData() async {
    final snapshot = await _stageDoc.get();
    return snapshot.data() as Map<String, dynamic>;
  }

  // Add method to resolve data conflicts
  Future<void> _resolveDataConflicts(Map<String, dynamic> serverData) async {
    try {
      final localData = await _getLocalData();
      final resolvedData = await _mergeData(serverData, localData);
      await _updateLocalStorage(resolvedData);
    } catch (e) {
      print('Error resolving conflicts: $e');
      await _logStageOperation('conflict_resolution_error', 'all', e.toString());
    }
  }

  // Add method to merge data
  Future<Map<String, dynamic>> _mergeData(
    Map<String, dynamic> serverData, 
    Map<String, dynamic> localData
  ) async {
    final mergedData = Map<String, dynamic>.from(serverData);
    
    // Compare timestamps and take the newer version
    if (localData.containsKey('lastModified') && 
        serverData.containsKey('lastModified') &&
        localData['lastModified'] != null &&
        serverData['lastModified'] != null) {
      final localTimestamp = localData['lastModified'] as Timestamp;
      final serverTimestamp = serverData['lastModified'] as Timestamp;
      
      if (localTimestamp.compareTo(serverTimestamp) > 0) {
        // Local data is newer, merge with null checks
        mergedData.addAll(Map<String, dynamic>.from(localData)
          ..removeWhere((key, value) => value == null));
      }
    }
    
    return mergedData;
  }

  Future<List<Map<String, dynamic>>> fetchCategories(String language) async {
    try {
      // Check memory cache first
      if (_categoryCache.containsKey(language)) {
        final cachedData = _categoryCache[language]!.data['categories'] as List<dynamic>;
        return List<Map<String, dynamic>>.from(cachedData);
      }

      // Then check local storage
      List<Map<String, dynamic>> localCategories = await _getCategoriesFromLocal(language);
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        QuerySnapshot snapshot = await _stageDoc
            .collection(language)
            .get();

        List<Map<String, dynamic>> categories = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] ?? '',
            'description': doc['description'] ?? '',
          };
        }).toList();

        // Store in CachedStage
        _categoryCache[language] = CachedStage(
          data: {'categories': categories},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        await _storeCategoriesLocally(categories, language);
        return categories;
      }
      return localCategories;
    } catch (e) {
      print('Error in fetchCategories: $e');
      return await _getCategoriesFromLocal(language);
    }
  }

  Future<List<Map<String, dynamic>>> fetchStages(String language, String categoryId) async {
    try {
      // Check memory cache first
      String cacheKey = '${language}_${categoryId}_stages';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey]!;
        if (cachedData.isValid) {
          print('💾 Returning stages from memory cache');
          return List<Map<String, dynamic>>.from(cachedData.data['stages']);
        }
        print('📦 Memory cache expired for $cacheKey');
      }

      // Then check local storage
      print('🔍 Checking local storage for stages');
      List<Map<String, dynamic>> localStages = await getStagesFromLocal('${STAGES_CACHE_KEY}_$categoryId');
      if (localStages.isNotEmpty) {
        print('📱 Found ${localStages.length} stages in local storage');
        
        // Refresh memory cache from local storage
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': localStages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        return localStages;
      }
      
      // Only fetch from server if we have no local data
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        print('🌐 Fetching stages from server');
        QuerySnapshot snapshot = await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .get();

        List<Map<String, dynamic>> stages = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'stageName': doc.id,
            ...data,
          };
        }).toList();

        // Update both caches
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': stages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        await _storeStagesLocally(stages, categoryId);
        print('✅ Cached ${stages.length} stages in memory and local storage');
        
        return stages;
      }

      // If offline and no local data
      print('⚠️ No stages available - offline and no local cache');
      return [];
    } catch (e) {
      print('❌ Error in fetchStages: $e');
      // Final fallback to local storage
      return await getStagesFromLocal('${STAGES_CACHE_KEY}_$categoryId');
    }
  }

  // Add these constants at the top of StageService
  static const String LOCAL_STORAGE_VERSION = 'stage_storage_v1_';
  static const Duration BACKUP_RETENTION = Duration(days: 7);

  // Replace the multiple getFromLocal methods with one unified method
  Future<List<Map<String, dynamic>>> getStagesFromLocal(
    String categoryId, {
    bool isArcade = false,
    bool useRawCache = false,
  }) async {
    try {
      if (useRawCache) {
        return await _getAllRawStages();
      }

      String key = _getStorageKey(categoryId, isArcade);
      return await _getFromLocalWithBackup(key);
    } catch (e) {
      print('❌ Error getting stages from local: $e');
      return [];
    }
  }

  // Add helper methods
  String _getStorageKey(String categoryId, bool isArcade) {
    return isArcade 
        ? '${LOCAL_STORAGE_VERSION}${STAGES_CACHE_KEY}_arcade_$categoryId'
        : '${LOCAL_STORAGE_VERSION}${STAGES_CACHE_KEY}_$categoryId';
  }

Future<List<Map<String, dynamic>>> _getAllRawStages() async {
  print('🔍 Getting all raw stages from all categories');
  final allStages = <Map<String, dynamic>>[];
  int totalStages = 0;
  
  // First check memory cache
  print('📦 Checking memory cache...');
  _stageCache.forEach((key, value) {
    if (value.data.containsKey('stages')) {
      final stages = List<Map<String, dynamic>>.from(value.data['stages']);
      print('📦 Found ${stages.length} stages in memory cache for key: $key');
      allStages.addAll(stages);
      totalStages += stages.length;
    }
  });

  print('📦 Found $totalStages stages in memory cache');
  
  // Return memory cache if we have stages
  if (totalStages > 0) {
    print('📦 Returning $totalStages stages from memory cache');
    return allStages;
  }

  // If nothing in memory, check local storage
  print('💾 Checking local storage for stages...');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Get all stage cache keys
  final stageKeys = prefs.getKeys()
      .where((key) => key.startsWith(LOCAL_STORAGE_VERSION))
      .where((key) => key.contains('stages_cache'))
      .where((key) => !key.endsWith('_backup'))
      .toList();
  
  print('🔑 Found ${stageKeys.length} stage cache keys in local storage');
  
  // Load stages from each key
  for (var key in stageKeys) {
    try {
      final stages = await _getFromLocalWithBackup(key);
      print('📦 Found ${stages.length} stages for key: $key');
      allStages.addAll(stages);
      totalStages += stages.length;
    } catch (e) {
      print('⚠️ Error loading stages for key $key: $e');
    }
  }
  
  print('📦 Found $totalStages total stages across all storage');
  return allStages;
}

  Future<List<Map<String, dynamic>>> _getFromLocalWithBackup(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Try main storage
    String? dataJson = prefs.getString(key);
    if (dataJson != null) {
      return _parseStagesJson(dataJson);
    }
    
    // Try backup
    String? backupJson = prefs.getString('${key}_backup');
    if (backupJson != null) {
      print('📦 Restored from backup for $key');
      // Restore main from backup
      await prefs.setString(key, backupJson);
      return _parseStagesJson(backupJson);
    }
    
    return [];
  }

  List<Map<String, dynamic>> _parseStagesJson(String json) {
    List<dynamic> dataList = jsonDecode(json);
    return dataList.map((data) {
      Map<String, dynamic> stageMap = Map<String, dynamic>.from(data);
      return _restoreTimestamps(stageMap);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getCategoriesFromLocal(String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? categoriesJson = prefs.getString('${CATEGORIES_CACHE_KEY}_$language');
      if (categoriesJson != null) {
        Map<String, dynamic> data = jsonDecode(categoriesJson);
        List<dynamic> categoriesList = data['categories'];
        return categoriesList.map((category) => 
          Map<String, dynamic>.from(category)).toList();
      }
    } catch (e) {
      print('Error getting categories from local: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getStagesFromLocal(String categoryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? stagesJson = prefs.getString('${STAGES_CACHE_KEY}_$categoryId');
      if (stagesJson != null) {
        List<dynamic> stagesList = jsonDecode(stagesJson);
        return stagesList.map((stage) {
          Map<String, dynamic> stageMap = Map<String, dynamic>.from(stage);
          return _restoreTimestamps(stageMap);
        }).toList();
      }
    } catch (e) {
      print('Error getting stages from local: $e');
    }
    return [];
  }

  // Helper method to restore timestamps
  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> map) {
    Map<String, dynamic> restored = {};
    
    map.forEach((key, value) {
      if (key.toLowerCase().contains('timestamp') && value is int) {
        // Convert milliseconds back to Timestamp
        restored[key] = Timestamp.fromMillisecondsSinceEpoch(value);
      } else if (value is Map) {
        // Recursively restore nested maps
        restored[key] = _restoreTimestamps(value as Map<String, dynamic>);
      } else if (value is List) {
        // Restore lists
        restored[key] = _restoreList(value);
      } else {
        // Keep other values as is
        restored[key] = value;
      }
    });
    
    return restored;
  }

  // Helper method to restore lists
  List _restoreList(List list) {
    return list.map((item) {
      if (item is int && item > 946684800000) { // timestamp after 2000-01-01
        return Timestamp.fromMillisecondsSinceEpoch(item);
      } else if (item is Map) {
        return _restoreTimestamps(item as Map<String, dynamic>);
      } else if (item is List) {
        return _restoreList(item);
      }
      return item;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(
    DocumentSnapshot snapshot, 
    String language, 
    String categoryId
  ) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> stages = 
        data['stages'] != null ? List<Map<String, dynamic>>.from(data['stages']) : [];
    
    await _storeStagesLocally(stages, categoryId);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return stages;
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocalCategories(
    DocumentSnapshot snapshot,
    String language
  ) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> categories = 
        data['categories'] != null ? List<Map<String, dynamic>>.from(data['categories']) : [];
    
    await _storeCategoriesLocally(categories, language);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return categories;
  }

  Future<Map<String, dynamic>?> getStageById(String categoryId, String stageId) async {
    try {
      String cacheKey = '${categoryId}_$stageId';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey]!;
        return Map<String, dynamic>.from(cachedData.data);
      }
      
      List<Map<String, dynamic>> stages = await _getStagesFromLocal(categoryId);
      var stage = stages.firstWhere((s) => s['id'] == stageId, orElse: () => {});
      
      if (stage.isNotEmpty) {
        _stageCache[cacheKey] = CachedStage(
          data: stage,
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        _manageCacheSize();
        return stage;
      }

      // Fetch from server if not found locally
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Similar to avatar service server fetch
      }
      
      return null;
    } catch (e) {
      print('Error in getStageById: $e');
      return null;
    }
  }

  void _manageCacheSize() {
    if (_stageCache.length > MAX_CACHE_SIZE) {
      // Sort entries by priority and timestamp
      var entries = _stageCache.entries.toList()
        ..sort((a, b) {
          // First compare by priority
          final priorityCompare = b.value.priority.index.compareTo(a.value.priority.index);
          if (priorityCompare != 0) return priorityCompare;
          
          // Then by timestamp (older entries get removed first)
          return a.value.timestamp.compareTo(b.value.timestamp);
        });

      // Remove lowest priority and oldest entries until we're under the limit
      while (_stageCache.length > MAX_CACHE_SIZE) {
        var entry = entries.removeLast();
        _stageCache.remove(entry.key);
      }
    }

    // Also manage category cache
    if (_categoryCache.length > MAX_CACHE_SIZE) {
      var entries = _categoryCache.entries.toList()
        ..sort((a, b) {
          final priorityCompare = b.value.priority.index.compareTo(a.value.priority.index);
          if (priorityCompare != 0) return priorityCompare;
          return a.value.timestamp.compareTo(b.value.timestamp);
        });

      while (_categoryCache.length > MAX_CACHE_SIZE) {
        var entry = entries.removeLast();
        _categoryCache.remove(entry.key);
      }
    }
  }

  Future<void> invalidateCache() async {
    _stageCache.clear();
    _categoryCache.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(STAGES_CACHE_KEY);
  }

  // Add data integrity checks
  Future<void> _verifyDataIntegrity() async {
    try {
      List<Map<String, dynamic>> serverStages = [];
      List<Map<String, dynamic>> localStages = await _getStagesFromLocal('all');
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _stageDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverStages = List<Map<String, dynamic>>.from(data['stages'] ?? []);
          
          // Compare and repair data
          bool needsRepair = false;
          
          // Check for duplicate stages
          Set<String> seenStages = {};
          for (var stage in localStages) {
            String stageKey = '${stage['language']}_${stage['categoryId']}_${stage['stageName']}';
            if (seenStages.contains(stageKey)) {
              needsRepair = true;
              break;
            }
            seenStages.add(stageKey);
          }

          // Compare with server data
          if (serverStages.length != localStages.length) {
            needsRepair = true;
          }

          if (needsRepair) {
            await _resolveStageConflicts(serverStages, localStages);
            await _logStageOperation('integrity_repair', 'all', 'Data repaired');
          }
        }
      }

      // Clear cache after verification
      _stageCache.clear();
      
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logStageOperation('integrity_check_error', 'all', e.toString());
    }
  }

  Future<void> _resolveStageConflicts(
    List<Map<String, dynamic>> serverStages, 
    List<Map<String, dynamic>> localStages
  ) async {
    try {
      Map<String, Map<String, dynamic>> mergedStages = {};
      
      // Add server stages
      for (var stage in serverStages) {
        String key = '${stage['language']}_${stage['categoryId']}_${stage['stageName']}';
        mergedStages[key] = stage;
      }
      
      // Compare with local stages
      for (var localStage in localStages) {
        String key = '${localStage['language']}_${localStage['categoryId']}_${localStage['stageName']}';
        if (!mergedStages.containsKey(key) || 
            (localStage['lastModified'] ?? 0) > (mergedStages[key]!['lastModified'] ?? 0)) {
          mergedStages[key] = localStage;
        }
      }
      
      List<Map<String, dynamic>> resolvedStages = mergedStages.values.toList();
      await _storeStagesLocally(resolvedStages, 'all');
      await _updateServerStages(resolvedStages);
    } catch (e) {
      print('Error resolving stage conflicts: $e');
      await _logStageOperation('conflict_resolution_error', 'all', e.toString());
    }
  }

  // Add operation logging
  Future<void> _logStageOperation(String operation, String categoryId, String details) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'stage_operation',
        'operation': operation,
        'categoryId': categoryId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  Future<void> _storeStagesLocally(
    List<Map<String, dynamic>> stages, 
    String categoryId, {
    bool isArcade = false,
  }) async {
    try {
      String key = _getStorageKey(categoryId, isArcade);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Create backup first
      String? existingData = prefs.getString(key);
      if (existingData != null) {
        await prefs.setString('${key}_backup', existingData);
        print('📦 Created backup for $key');
      }

      // Store new data
      String stagesJson = jsonEncode(_sanitizeForStorage(stages));
      await prefs.setString(key, stagesJson);
      print('✅ Stored ${stages.length} stages for $key');
      
      // Clear old backup
      await prefs.remove('${key}_backup');
      
      // Clean up old backups periodically
      await _cleanupOldBackups();
    } catch (e) {
      print('❌ Error storing stages: $e');
      // Keep backup in case of error
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      for (String key in prefs.getKeys()) {
        if (key.startsWith(LOCAL_STORAGE_VERSION) && key.endsWith('_backup')) {
          String? timestamp = prefs.getString('${key}_timestamp');
          if (timestamp != null) {
            DateTime backupDate = DateTime.parse(timestamp);
            if (now.difference(backupDate) > BACKUP_RETENTION) {
              await prefs.remove(key);
              await prefs.remove('${key}_timestamp');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error cleaning up backups: $e');
    }
  }

  // Helper method to sanitize maps for JSON encoding
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    Map<String, dynamic> sanitized = {};
    
    map.forEach((key, value) {
      if (value != null) {
        sanitized[key] = _sanitizeForStorage(value);
      }
    });
    
    return sanitized;
  }

  // Helper method to sanitize lists
  List _sanitizeList(List list) {
    return list.map((item) => _sanitizeForStorage(item)).toList();
  }

  Future<void> _storeCategoriesLocally(List<Map<String, dynamic>> categories, String language) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${CATEGORIES_CACHE_KEY}_$language',
        jsonEncode({'categories': categories})
      );
    } catch (e) {
      print('Error storing categories locally: $e');
    }
  }

  Future<void> _restoreFromBackup(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('${STAGES_CACHE_KEY}_${key}_backup');
      if (backup != null) {
        await prefs.setString('${STAGES_CACHE_KEY}_$key', backup);
      }
    } catch (e) {
      print('Error restoring from backup: $e');
    }
  }

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(STAGE_REVISION_KEY);
  }

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(STAGE_REVISION_KEY, revision);
  }

  Future<void> cleanupOldVersions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys()
          .where((key) => key.startsWith('stage_version_'))
          .toList();
      
      if (oldKeys.length > MAX_STORED_VERSIONS) {
        oldKeys.sort();
        for (var key in oldKeys.take(oldKeys.length - MAX_STORED_VERSIONS)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error cleaning up versions: $e');
    }
  }

  void dispose() {
    _stageUpdateController.close();
    _categoryUpdateController.close();
  }

  // Admin Methods
  Future<void> addStage(String language, String categoryId, String stageName, Map<String, dynamic> stageData) async {
    try {
      // Validate stage data
      if (!_validateStageData(stageData)) {
        throw Exception('Invalid stage data');
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Add stage to Firestore
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName)
            .set({
          ...stageData,
          'lastModified': FieldValue.serverTimestamp(),
        });

        // Update local cache
        String cacheKey = '${language}_${categoryId}_stages';
        if (_stageCache.containsKey(cacheKey)) {
          List<Map<String, dynamic>> stages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
          stages.add({
            'stageName': stageName,
            ...stageData,
          });
          _stageCache[cacheKey] = CachedStage(
            data: {'stages': stages},
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );
        }

        await _logStageOperation('add_stage', categoryId, 'Added stage: $stageName');
      } else {
        // Queue for offline sync
        await addOfflineChange('add', {
          'language': language,
          'categoryId': categoryId,
          'stageName': stageName,
          'data': stageData,
        });
      }
    } catch (e) {
      print('Error adding stage: $e');
      await _logStageOperation('add_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  bool _validateStageData(Map<String, dynamic> data) {
    // Debug print to see what data we're getting
    print('Validating stage data: $data');
    
    // More lenient validation for stage updates
    return data.containsKey('stageDescription') || // Stage description is optional
           data.containsKey('questions') ||        // Questions might be updated separately
           data.containsKey('maxScore') ||         // Score might be updated separately
           data.containsKey('totalQuestions');     // Total questions might be updated separately
  }

  Future<void> updateStage(String language, String categoryId, String stageName, Map<String, dynamic> updatedData) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Update in Firestore
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName)
            .update({
          ...updatedData,
          'lastModified': FieldValue.serverTimestamp(),
        });

        // Update local cache
        String cacheKey = '${language}_${categoryId}_stages';
        if (_stageCache.containsKey(cacheKey)) {
          List<Map<String, dynamic>> stages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
          int index = stages.indexWhere((s) => s['stageName'] == stageName);
          if (index != -1) {
            stages[index] = {
              ...stages[index],
              ...updatedData,
            };
            _stageCache[cacheKey] = CachedStage(
              data: {'stages': stages},
              timestamp: DateTime.now(),
              priority: StagePriority.HIGH
            );
          }
        }

        await _logStageOperation('update_stage', categoryId, 'Updated stage: $stageName');
      } else {
        // Queue for offline sync
        await addOfflineChange('update', {
          'language': language,
          'categoryId': categoryId,
          'stageName': stageName,
          'data': updatedData,
        });
      }
    } catch (e) {
      print('Error updating stage: $e');
      await _logStageOperation('update_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<void> deleteStage(String language, String categoryId, String stageName) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Delete from Firestore
        await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName)
            .delete();

        // Update local cache
        String cacheKey = '${language}_${categoryId}_stages';
        if (_stageCache.containsKey(cacheKey)) {
          List<Map<String, dynamic>> stages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
          stages.removeWhere((s) => s['stageName'] == stageName);
          _stageCache[cacheKey] = CachedStage(
            data: {'stages': stages},
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );
        }

        await _logStageOperation('delete_stage', categoryId, 'Deleted stage: $stageName');
      } else {
        // Queue for offline sync
        await addOfflineChange('delete', {
          'language': language,
          'categoryId': categoryId,
          'stageName': stageName,
        });
      }
    } catch (e) {
      print('Error deleting stage: $e');
      await _logStageOperation('delete_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<void> updateCategory(String language, String categoryId, Map<String, dynamic> updatedData) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _stageDoc
            .collection(language)
            .doc(categoryId)
            .update(updatedData);

        // Update local cache
        if (_categoryCache.containsKey(language)) {
          final cachedData = _categoryCache[language]!.data;
          List<Map<String, dynamic>> categories = List<Map<String, dynamic>>.from(cachedData['categories']);
          int index = categories.indexWhere((c) => c['id'] == categoryId);
          if (index != -1) {
            categories[index] = {
              ...categories[index],
              ...updatedData,
            };
            // Update cache with new CachedStage
            _categoryCache[language] = CachedStage(
              data: {'categories': categories},
              timestamp: DateTime.now(),
              priority: StagePriority.HIGH
            );
          }
        }

        await _logStageOperation('update_category', categoryId, 'Updated category');
      } else {
        // Queue for offline sync
        await addOfflineChange('update_category', {
          'language': language,
          'categoryId': categoryId,
          'data': updatedData,
        });
      }
    } catch (e) {
      print('Error updating category: $e');
      await _logStageOperation('update_category_error', categoryId, e.toString());
    }
  }

  bool _validateCategoryData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
           data.containsKey('description');
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String categoryId, String stageName) async {
    try {
      // Check cache first
      String cacheKey = '${language}_${categoryId}_${stageName}_questions';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey]!;
        if (cachedData.data.containsKey('questions')) {
          return List<Map<String, dynamic>>.from(cachedData.data['questions']);
        }
      }

      // Get the stage document first
      Map<String, dynamic> stageDoc = await fetchStageDocument(language, categoryId, stageName);
      
      if (stageDoc.isNotEmpty && stageDoc.containsKey('questions')) {
        List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDoc['questions']);
        // Cache the questions
        _stageCache[cacheKey] = CachedStage(
          data: {'questions': questions},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        return questions;
      }

      return [];
    } catch (e) {
      print('Error fetching questions: $e');
      await _logStageOperation('fetch_questions_error', categoryId, e.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String categoryId, String stageName) async {
    try {
      // Check cache first
      String cacheKey = '${language}_${categoryId}_${stageName}_doc';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey];
        if (cachedData != null) {
          return Map<String, dynamic>.from(cachedData.data);
        }
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot doc = await _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName)
            .get();

        if (doc.exists) {
          Map<String, dynamic> stageData = doc.data() as Map<String, dynamic>;
          // Cache the document
          _stageCache[cacheKey] = CachedStage(
            data: stageData,
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );
          await _storeStageDocumentLocally(language, categoryId, stageName, stageData);
          return stageData;
        }
      }

      // If offline or not found, try local storage
      return await _getStageDocumentFromLocal(language, categoryId, stageName);
    } catch (e) {
      print('Error fetching stage document: $e');
      return await _getStageDocumentFromLocal(language, categoryId, stageName);
    }
  }

  Future<void> _storeStageDocumentLocally(String language, String categoryId, String stageName, Map<String, dynamic> stageData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$categoryId.$stageName';
      String stageJson = jsonEncode(stageData);
      await prefs.setString(key, stageJson);
    } catch (e) {
      print('Error storing stage document locally: $e');
    }
  }

  Future<Map<String, dynamic>> _getStageDocumentFromLocal(String language, String categoryId, String stageName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$categoryId.$stageName';
      String? stageJson = prefs.getString(key);
      if (stageJson != null) {
        return jsonDecode(stageJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting stage document from local: $e');
    }
    return {};
  }

  Future<void> _updateServerStages(List<Map<String, dynamic>> stages) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _stageDoc.update({
          'stages': stages,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });
        await _logStageOperation('server_update', 'all', 'Updated ${stages.length} stages');
      }
    } catch (e) {
      print('Error updating server stages: $e');
      await _logStageOperation('server_update_error', 'all', e.toString());
      rethrow;
    }
  }

  // Add batch operations for better performance
  Future<void> batchUpdateStages(List<Map<String, dynamic>> stages) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(_stageDoc, {
          'stages': stages,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });

        await _storeStagesLocally(stages, 'all');
        await _logStageOperation('batch_update', 'all', 'Updated ${stages.length} stages');
      });
    } catch (e) {
      print('Error in batch update: $e');
      await _logStageOperation('batch_update_error', 'all', e.toString());
      rethrow;
    }
  }

  // Add prefetching for better UX
  Future<void> prefetchCategory(String categoryId) async {
    try {
      if (_stageCache.containsKey(categoryId)) return;

      var stages = await fetchStages(defaultLanguage, categoryId);
      _stageCache[categoryId] = CachedStage(
        data: {'stages': stages},
        timestamp: DateTime.now(),
        priority: StagePriority.HIGH
      );
    } catch (e) {
      print('Error prefetching category: $e');
    }
  }

  // Add bulk operations
  Future<Map<String, List<Map<String, dynamic>>>> fetchMultipleCategories(
    List<String> categoryIds
  ) async {
    Map<String, List<Map<String, dynamic>>> results = {};
    
    await Future.wait(
      categoryIds.map((id) async {
        results[id] = await fetchStages(defaultLanguage, id);
      })
    );

    return results;
  }

  Future<bool> validateStageData(Map<String, dynamic> stageData) async {
    try {
      // Basic validation
      if (!_validateStageData(stageData)) return false;

      // Deep validation
      bool isValid = true;
      
      // Check questions
      if (stageData['questions'] != null) {
        for (var question in stageData['questions']) {
          if (!_validateQuestionData(question)) {
            isValid = false;
            break;
          }
        }
      }

      // Check stage progression
      if (stageData['prerequisites'] != null) {
        isValid = await _validatePrerequisites(stageData['prerequisites']);
      }

      return isValid;
    } catch (e) {
      print('Error validating stage data: $e');
      return false;
    }
  }

  bool _validateQuestionData(Map<String, dynamic> question) {
    // Add specific question validation logic
    return question.containsKey('type') &&
           question.containsKey('question') &&
           question.containsKey('answers');
  }

  Future<bool> _validatePrerequisites(List<String> prerequisites) async {
    try {
      for (var prereq in prerequisites) {
        var stageExists = await checkStageExists(prereq);
        if (!stageExists) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> performMaintenance() async {
    try {
      // Clean up old versions
      await cleanupOldVersions();
      
      // Verify data integrity
      await _verifyDataIntegrity();
      
      // Clean up old logs
      await _cleanupOldLogs();
      
      // Optimize storage
      await _optimizeStorage();
    } catch (e) {
      print('Error during maintenance: $e');
      await _logStageOperation('maintenance_error', 'all', e.toString());
    }
  }

  Future<void> _optimizeStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Remove unused cache entries
      final allKeys = prefs.getKeys();
      for (var key in allKeys) {
        if (key.startsWith('stage_') && !key.contains('_backup')) {
          final lastAccess = await _getLastAccess(key);
          if (DateTime.now().difference(lastAccess) > const Duration(days: 30)) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error optimizing storage: $e');
    }
  }

  Future<bool> checkStageExists(String stageId) async {
    try {
      var stages = await _getStagesFromLocal('all');
      return stages.any((stage) => stage['id'] == stageId);
    } catch (e) {
      print('Error checking stage existence: $e');
      return false;
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      // Delete logs older than 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await FirebaseFirestore.instance
          .collection('Logs')
          .where('type', isEqualTo: 'stage_operation')
          .where('timestamp', isLessThan: thirtyDaysAgo)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      print('Error cleaning up logs: $e');
    }
  }

  Future<DateTime> _getLastAccess(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? timestamp = prefs.getInt('${key}_last_access');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error getting last access: $e');
    }
    return DateTime.now().subtract(const Duration(days: 31)); // Return old date to trigger cleanup
  }

  Future<void> _updateLastAccess(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${key}_last_access', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating last access: $e');
    }
  }

  Future<void> _handleOfflineChanges() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Sync any pending changes
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final pendingChanges = prefs.getStringList('pending_stage_changes') ?? [];
        
        for (var changeJson in pendingChanges) {
          Map<String, dynamic> change = jsonDecode(changeJson);
          await _syncChange(change);
        }
        
        // Clear pending changes after successful sync
        await prefs.setStringList('pending_stage_changes', []);
      }
    } catch (e) {
      print('Error handling offline changes: $e');
    }
  }

  Future<void> _syncChange(Map<String, dynamic> change) async {
    try {
      switch (change['type']) {
        case 'update':
          await _updateServerStages(change['data']);
          break;
        case 'delete':
          // Handle delete sync
          break;
        // Add other cases as needed
      }
    } catch (e) {
      print('Error syncing change: $e');
    }
  }

  Future<void> _recoverFromError(String operation, String categoryId, dynamic error) async {
    try {
      await _logStageOperation('error_recovery', categoryId, 'Attempting recovery from $operation error');
      
      // Verify data integrity
      await _verifyDataIntegrity();
      
      // Clear corrupted cache
      _stageCache.clear();
      _categoryCache.clear();
      
      // Attempt to restore from backup
      await _restoreFromBackup(categoryId);
      
      await _logStageOperation('recovery_complete', categoryId, 'Successfully recovered from error');
    } catch (e) {
      print('Error during recovery: $e');
      await _logStageOperation('recovery_failed', categoryId, e.toString());
    }
  }

  Future<void> _syncData() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Handle offline changes first
        await _handleOfflineChanges();
        
        // Then sync with server
        DocumentSnapshot snapshot = await _stageDoc.get();
        if (snapshot.exists) {
          int serverRevision = snapshot.get('revision') ?? 0;
          int localRevision = await _getLocalRevision() ?? -1;
          
          if (serverRevision > localRevision) {
            // Server has newer data
            await _fetchAndUpdateLocal(snapshot, defaultLanguage, 'all');
          }
        }
      }
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Add method to handle offline changes
  Future<void> addOfflineChange(String type, Map<String, dynamic> data) async {
    _syncQueue.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingChanges = prefs.getStringList('pending_stage_changes') ?? [];
    pendingChanges.add(jsonEncode({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
    await prefs.setStringList('pending_stage_changes', pendingChanges);
  }

  // Add these methods to the StageService class

  // Method to get local data
  Future<Map<String, dynamic>> _getLocalData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get all stage-related data from local storage
      Map<String, dynamic> localData = {};
      
      // Get stages
      for (String key in prefs.getKeys()) {
        if (key.startsWith(STAGES_CACHE_KEY_PREFIX)) {
          String? data = prefs.getString(key);
          if (data != null) {
            localData[key] = jsonDecode(data);
          }
        }
      }
      
      // Get categories
      String? categoriesData = prefs.getString(CATEGORIES_CACHE_KEY);
      if (categoriesData != null) {
        localData['categories'] = jsonDecode(categoriesData);
      }
      
      // Get revision
      int? revision = prefs.getInt(STAGE_REVISION_KEY);
      if (revision != null) {
        localData['revision'] = revision;
      }
      
      // Add timestamp
      localData['lastModified'] = Timestamp.now();
      
      return localData;
    } catch (e) {
      print('Error getting local data: $e');
      return {};
    }
  }

  // Method to update local storage
  Future<void> _updateLocalStorage(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Store stages
      if (data.containsKey('stages')) {
        List<Map<String, dynamic>> stages = List<Map<String, dynamic>>.from(data['stages'] ?? []);
        for (var stage in stages) {
          String categoryId = stage['categoryId'] ?? '';
          if (categoryId.isNotEmpty) {
            await _storeStagesLocally(stages, categoryId);
          }
        }
      }
      
      // Store categories
      if (data.containsKey('categories')) {
        List<Map<String, dynamic>> categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        for (var category in categories) {
          String language = category['language'] ?? defaultLanguage;
          if (category.isNotEmpty) {
            await _storeCategoriesLocally(categories, language);
          }
        }
      }
      
      // Store revision with null check
      if (data.containsKey('revision') && data['revision'] != null) {
        await prefs.setInt(STAGE_REVISION_KEY, data['revision']);
      }
      
      // Manage cache size
      _manageCacheSize();
      
      // Update sync status
      await _updateSyncStatus('completed');
    } catch (e) {
      print('Error updating local storage: $e');
      await _logStageOperation('local_storage_error', 'all', e.toString());
      
      // Try to recover
      await _recoverFromError('local_storage_update', 'all', e);
    }
  }

  // Add new connection manager
  final ConnectionManager _connectionManager = ConnectionManager();

  // Keep existing constructor
  StageService._internal() {
    // Add connection quality listener
    _connectionManager.connectionQuality.listen((quality) {
      // Handle connection quality changes
    });
  }

  // Add after existing cache structures and before stream controllers
  final Map<StagePriority, Queue<StageLoadRequest>> _loadQueues = {
    StagePriority.CRITICAL: Queue<StageLoadRequest>(),
    StagePriority.HIGH: Queue<StageLoadRequest>(),
    StagePriority.MEDIUM: Queue<StageLoadRequest>(),
    StagePriority.LOW: Queue<StageLoadRequest>(),
  };

  // Add queue processing methods
  Future<void> _processQueue(StagePriority priority) async {
    final quality = await _connectionManager.checkConnectionQuality();
    final queue = _loadQueues[priority]!;
    
    // Adjust batch size based on connection quality
    int batchSize = quality == ConnectionQuality.EXCELLENT ? 5 :
                    quality == ConnectionQuality.GOOD ? 3 :
                    quality == ConnectionQuality.POOR ? 1 : 0;
                  
    if (batchSize == 0) return; // Don't process if offline

    while (queue.isNotEmpty) {
      final request = queue.removeFirst();
      try {
        if (request.stageName.isNotEmpty) {
          // Stage request
          await _fetchStageWithPriority(
            request.categoryId,
            request.stageName,
            request.priority
          );
        } else {
          // Category request
          await _fetchCategoryWithPriority(
            request.categoryId,
            request.priority
          );
        }
      } catch (e) {
        print('Error processing queue item: $e');
        await _logStageOperation('queue_processing_error', request.categoryId, e.toString());
      }
    }
  }

  // Add method to queue stage loads
  void queueStageLoad(String categoryId, String stageName, StagePriority priority) {
    final request = StageLoadRequest(
      categoryId: categoryId,
      stageName: stageName,
      priority: priority,
      timestamp: DateTime.now(),
    );
    
    _loadQueues[priority]!.add(request);
    
    // Start processing immediately for CRITICAL priority
    if (priority == StagePriority.CRITICAL) {
      _processQueue(priority);
    }
  }

  Future<void> _fetchStageWithPriority(
    String categoryId,
    String stageName,
    StagePriority priority
  ) async {
    try {
      final quality = await _connectionManager.checkConnectionQuality();
      final cacheKey = '${categoryId}_$stageName';

      // Check cache first
      if (_stageCache.containsKey(cacheKey)) {
        return;
      }

      // If offline, try to get from local storage
      if (quality == ConnectionQuality.OFFLINE) {
        final localData = await _getFromLocal('$STAGES_CACHE_KEY_PREFIX$cacheKey');
        if (localData.isNotEmpty) {
          _stageCache[cacheKey] = CachedStage(
            data: localData.first,
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );
          return;
        }
        return;
      }

      // Fetch from Firebase
      final stageDoc = await _stageDoc
          .collection(defaultLanguage)
          .doc(categoryId)
          .collection('stages')
          .doc(stageName)
          .get();

      if (stageDoc.exists) {
        final stageData = stageDoc.data() as Map<String, dynamic>;
        _stageCache[cacheKey] = CachedStage(
          data: stageData,
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        // Store locally
        await _storeStagesLocally([stageData], categoryId);
      }
    } catch (e) {
      print('Error fetching stage with priority: $e');
      await _logStageOperation('fetch_stage_error', categoryId, e.toString());
    }
  }

  Future<void> _fetchCategoryWithPriority(
    String categoryId,
    StagePriority priority
  ) async {
    try {
      final quality = await _connectionManager.checkConnectionQuality();

      // Check cache first
      if (_categoryCache.containsKey(categoryId)) {
        return;
      }

      // If offline, try to get from local storage
      if (quality == ConnectionQuality.OFFLINE) {
        final localData = await _getFromLocal('${CATEGORIES_CACHE_KEY}_$categoryId');
        if (localData.isNotEmpty) {
          _categoryCache[categoryId] = CachedStage(
            data: {'categories': localData},
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );
          return;
        }
        return;
      }

      // Fetch from Firebase
      final categoryDoc = await _stageDoc
          .collection(defaultLanguage)
          .doc(categoryId)
          .get();

      if (categoryDoc.exists) {
        final categoryData = categoryDoc.data() as Map<String, dynamic>;
        _categoryCache[categoryId] = CachedStage(
          data: {'categories': [categoryData]},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        // Store locally
        await _storeCategoriesLocally([categoryData], defaultLanguage);
        
        // Notify listeners
        _categoryUpdateController.add([categoryData]);
      }
    } catch (e) {
      print('Error fetching category with priority: $e');
      await _logStageOperation('fetch_category_error', categoryId, e.toString());
    }
  }

  // Add this method to StageService
  Future<List<Map<String, dynamic>>> _getFromLocal(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(key);
      
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map) {
          return [Map<String, dynamic>.from(decoded)];
        }
      }
      return [];
    } catch (e) {
      print('Error getting data from local storage: $e');
      await _logStageOperation('local_storage_error', key, e.toString());
      return [];
    }
  }

  // Add these properties at the top of the class
  Timer? _syncDebounceTimer;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  // Add this method
  void triggerBackgroundSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncWithServer();
    });
  }

  // Add this helper method
  void _setSyncState(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(syncing);
  }

  // Add the sync method
  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Stage sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting stage sync process');
      _setSyncState(true);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Sync categories by re-fetching them
        print('📥 Syncing categories...');
        final enCategories = await fetchCategories('en');
        final filCategories = await fetchCategories('fil');
        
        // Sync stages for each category using existing fetchStages method
        print('📥 Syncing stages for all categories...');
        for (var category in enCategories) {
          await fetchStages('en', category['id']);
        }
        
        for (var category in filCategories) {
          await fetchStages('fil', category['id']);
        }

        print('✅ Stage sync completed');
      }
    } catch (e) {
      print('❌ Error in stage sync: $e');
    } finally {
      print('🏁 Stage sync process completed');
      _setSyncState(false);
    }
  }

  // Add these methods to StageService class

  void _logCacheStatus(String cacheKey, String operation) {
    print('📦 Cache $operation - Key: $cacheKey');
    print('💾 Memory cache size: ${_stageCache.length}');
    print('🗄️ Cache keys: ${_stageCache.keys.join(', ')}');
  }
  Future<void> debugCacheState() async {
    try {
      print('\n🔍 Stage Service Cache Debug:');
      print('📦 Memory Cache:');
      _stageCache.forEach((key, value) {
        print('  Key: $key');
        print('  Priority: ${value.priority}');
        print('  Age: ${DateTime.now().difference(value.timestamp).inMinutes}m');
        print('  Valid: ${value.isValid}\n');
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final localKeys = prefs.getKeys()
          .where((key) => key.startsWith(STAGES_CACHE_KEY))
          .toList();
      
      print('💾 Local Storage Cache:');
      for (var key in localKeys) {
        print('  Key: $key');
      }
      print('------------------------\n');
    } catch (e) {
      print('❌ Error in debugCacheState: $e');
    }
  }

  // Add this method to StageService class
  dynamic _sanitizeForStorage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      return _sanitizeMap(data);
    } else if (data is Map) {
      // Convert other Map types to Map<String, dynamic>
      return _sanitizeMap(Map<String, dynamic>.from(data));
    }
    
    if (data is List) {
      return data.map((item) => _sanitizeForStorage(item)).toList();
    }
    
    if (data is Timestamp) {
      return data.toDate().millisecondsSinceEpoch;
    }
    
    if (data is DateTime) {
      return data.millisecondsSinceEpoch;
    }
    
    return data;
  }
}