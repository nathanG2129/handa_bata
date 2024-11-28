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
      return;
    }
    _isSyncing = true;

    try {
      await _updateSyncStatus('syncing');
      
      // Process offline queue first
      await _processSyncQueue();

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Fetch latest data from server
        final serverData = await _fetchServerData();
        
        // Compare with local data and resolve conflicts
        await _resolveDataConflicts(serverData);
        
        // Update local storage with resolved data
        await _updateLocalStorage(serverData);
        
        await _updateSyncStatus('completed');
      } else {
        await _updateSyncStatus('offline');
      }
    } catch (e) {
      await _updateSyncStatus('error');
    } finally {
      _isSyncing = false;
    }
  }

  // Add method to process sync queue
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty) {
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      final batch = FirebaseFirestore.instance.batch();
      
      for (var change in _syncQueue) {
        switch (change['type']) {
          case 'update':
            batch.update(_stageDoc, change['data']);
            break;
          case 'delete':
            batch.delete(_stageDoc.collection(change['collection']).doc(change['id']));
            break;
        }
      }

      await batch.commit();
      _syncQueue.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('pending_stage_changes', []);
      
    } else {
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
      return await _getCategoriesFromLocal(language);
    }
  }

  Future<List<Map<String, dynamic>>> fetchStages(
    String language, 
    String categoryId, {
    bool isArcade = false
  }) async {
    try {
      // Check memory cache first
      String cacheKey = '${language}_${categoryId}_stages';
      if (_stageCache.containsKey(cacheKey)) {
        final cachedData = _stageCache[cacheKey]!;
        if (cachedData.isValid) {
          final stages = List<Map<String, dynamic>>.from(cachedData.data['stages']);
          return _filterStages(stages, isArcade);
        }
      }

      // Add this check for prefetch
      bool isPrefetching = StackTrace.current.toString().contains('_prefetchData');
      if (isPrefetching) {
        return await _fetchFreshStages(language, categoryId);
      }

      // Try local storage
      List<Map<String, dynamic>> localStages = await getStagesFromLocal(categoryId);
      if (localStages.isNotEmpty) {
        // Refresh memory cache from local storage
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': localStages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        return _filterStages(localStages, isArcade);
      }
      
      // If nothing in local storage, fetch fresh
      final stages = await _fetchFreshStages(language, categoryId);
      return _filterStages(stages, isArcade);
    } catch (e) {
      final stages = await getStagesFromLocal(categoryId);
      return _filterStages(stages, isArcade);
    }
  }

  // Helper method to filter stages based on arcade flag
  List<Map<String, dynamic>> _filterStages(List<Map<String, dynamic>> stages, bool isArcade) {
    return stages.where((stage) {
      final stageName = stage['stageName'].toString().toLowerCase();
      return isArcade ? stageName.contains('arcade') : !stageName.contains('arcade');
    }).toList();
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

      String key = getStorageKey(categoryId, isArcade);
      List<Map<String, dynamic>> stages = await _getFromLocalWithBackup(key);

      // If no stages found with arcade key, try getting from all stages
      if (stages.isEmpty && isArcade) {
        // Try getting all stages and filter for arcade
        stages = await _getFromLocalWithBackup(getStorageKey(categoryId, false));
        stages = stages.where((stage) => 
          stage['stageName'].toString().toLowerCase().contains('arcade')
        ).toList();
      }

      return stages;
    } catch (e) {
      return [];
    }
  }

  // Add helper methods
  String getStorageKey(String categoryId, bool isArcade) {
    return isArcade 
        ? '${LOCAL_STORAGE_VERSION}${STAGES_CACHE_KEY}_arcade_$categoryId'
        : '${LOCAL_STORAGE_VERSION}${STAGES_CACHE_KEY}_$categoryId';
  }

Future<List<Map<String, dynamic>>> _getAllRawStages() async {
  final allStages = <Map<String, dynamic>>[];
  int totalStages = 0;
  
  // First check memory cache
  _stageCache.forEach((key, value) {
    if (value.data.containsKey('stages')) {
      final stages = List<Map<String, dynamic>>.from(value.data['stages']);
      allStages.addAll(stages);
      totalStages += stages.length;
    }
  });

  
  // Return memory cache if we have stages
  if (totalStages > 0) {
    return allStages;
  }

  // If nothing in memory, check local storage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Get all stage cache keys
  final stageKeys = prefs.getKeys()
      .where((key) => key.startsWith(LOCAL_STORAGE_VERSION))
      .where((key) => key.contains('stages_cache'))
      .where((key) => !key.endsWith('_backup'))
      .toList();
  
  
  // Load stages from each key
  for (var key in stageKeys) {
    try {
      final stages = await _getFromLocalWithBackup(key);
      allStages.addAll(stages);
      totalStages += stages.length;
    } catch (e) {
    }
  }
  
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
    }
  }

  Future<void> _storeStagesLocally(
    List<Map<String, dynamic>> newStages, 
    String categoryId, {
    bool isArcade = false,
  }) async {
    try {
      String key = getStorageKey(categoryId, isArcade);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Create backup first
      String? existingData = prefs.getString(key);
      if (existingData != null) {
        await prefs.setString('${key}_backup', existingData);
      }

      // Get existing stages
      List<Map<String, dynamic>> existingStages = [];
      if (existingData != null) {
        final decoded = jsonDecode(existingData);
        existingStages = List<Map<String, dynamic>>.from(decoded);
      }

      // Merge stages
      Map<String, Map<String, dynamic>> mergedStagesMap = {};
      
      // Add existing stages to map
      for (var stage in existingStages) {
        String stageKey = '${stage['stageName']}_${stage['language'] ?? 'en'}';
        mergedStagesMap[stageKey] = stage;
      }
      
      // Add or update new stages
      for (var stage in newStages) {
        String stageKey = '${stage['stageName']}_${stage['language'] ?? 'en'}';
        mergedStagesMap[stageKey] = stage;
      }

      // Convert map back to list
      List<Map<String, dynamic>> mergedStages = mergedStagesMap.values.toList();

      // Store merged data
      String stagesJson = jsonEncode(_sanitizeForStorage(mergedStages));
      await prefs.setString(key, stagesJson);
      
      // Clear old backup after successful save
      await prefs.remove('${key}_backup');
    } catch (e) {
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
    }
  }

  void dispose() {
    _stageUpdateController.close();
    _categoryUpdateController.close();
  }


  bool _validateStageData(Map<String, dynamic> data) {
    // Debug print to see what data we're getting
    
    // More lenient validation for stage updates
    return data.containsKey('stageDescription') || // Stage description is optional
           data.containsKey('questions') ||        // Questions might be updated separately
           data.containsKey('maxScore') ||         // Score might be updated separately
           data.containsKey('totalQuestions');     // Total questions might be updated separately
  }

  Future<void> updateCategory(String language, String categoryId, Map<String, dynamic> updatedData) async {
    try {
      if (!_validateCategoryData(updatedData)) {
        throw Exception('Invalid category data');
      }

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Update in Firestore
        await _stageDoc
            .collection(language)
            .doc(categoryId)
            .update({
          ...updatedData,
          'lastModified': FieldValue.serverTimestamp(),
        });

        // Update server timestamp for sync checking
        await _firestore
            .collection('Game')
            .doc('Stage')
            .update({'lastModified': FieldValue.serverTimestamp()});

        // Update local cache
        if (_categoryCache.containsKey(language)) {
          final cachedData = _categoryCache[language]!.data;
          List<Map<String, dynamic>> categories = List<Map<String, dynamic>>.from(cachedData['categories']);
          int index = categories.indexWhere((c) => c['id'] == categoryId);
          if (index != -1) {
            categories[index] = {
              ...categories[index],
              ...updatedData,
              'lastModified': DateTime.now().millisecondsSinceEpoch,
            };
            
            // Update cache with new CachedStage
            _categoryCache[language] = CachedStage(
              data: {'categories': categories},
              timestamp: DateTime.now(),
              priority: StagePriority.HIGH
            );

            // Update local storage
            await _storeCategoriesLocally(categories, language);
          }
        }

        // Update admin timestamps
        await updateLastAdminUpdateTimestamp();
        
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
      await _logStageOperation('update_category_error', categoryId, e.toString());
      rethrow;
    }
  }

  bool _validateCategoryData(Map<String, dynamic> data) {
    
    // Required fields
    if (!data.containsKey('name') || data['name'].toString().trim().isEmpty) {
      return false;
    }
    
    if (!data.containsKey('description') || data['description'].toString().trim().isEmpty) {
      return false;
    }

    // Optional fields with defaults
    if (data.containsKey('color') && data['color'].toString().trim().isEmpty) {
      data['color'] = 'defaultColor';
    }

    if (data.containsKey('position') && (data['position'] == null || data['position'] < 0)) {
      data['position'] = 0;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String language, String categoryId, String stageName) async {
    try {
      // Get the full stage document which includes questions
      Map<String, dynamic> stageDoc = await fetchStageDocument(language, categoryId, stageName);
      
      if (stageDoc.isNotEmpty && stageDoc.containsKey('questions')) {
        List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(stageDoc['questions']);
        
        // Update questions cache
        String cacheKey = '${language}_${categoryId}_${stageName}_questions';
        _stageCache[cacheKey] = CachedStage(
          data: {'questions': questions},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );
        
        return questions;
      }
      return [];
    } catch (e) {
      await _logStageOperation('fetch_questions_error', categoryId, e.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchStageDocument(String language, String categoryId, String stageName) async {
    try {
      // Always try to get fresh data from Firestore first
      var connectivityResult = await Connectivity().checkConnectivity();
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
          
          // Update both caches
          String cacheKey = '${language}_${categoryId}_stages';
          
          // Update stage list cache
          List<Map<String, dynamic>> currentStages = [];
          if (_stageCache.containsKey(cacheKey)) {
            currentStages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
            int index = currentStages.indexWhere((s) => s['stageName'] == stageName);
            if (index != -1) {
              currentStages[index] = stageData;
            }
            _stageCache[cacheKey] = CachedStage(
              data: {'stages': currentStages},
              timestamp: DateTime.now(),
              priority: StagePriority.HIGH
            );
          }

          // Update individual stage cache
          String stageKey = '${language}_${categoryId}_${stageName}_doc';
          _stageCache[stageKey] = CachedStage(
            data: stageData,
            timestamp: DateTime.now(),
            priority: StagePriority.HIGH
          );

          // Update local storage
          await _storeStagesLocally(currentStages, categoryId);
          await _storeStageDocumentLocally(language, categoryId, stageName, stageData);
          
          return stageData;
        }
      }

      // If offline or document doesn't exist, try cache
      String stageKey = '${language}_${categoryId}_${stageName}_doc';
      if (_stageCache.containsKey(stageKey)) {
        return Map<String, dynamic>.from(_stageCache[stageKey]!.data);
      }

      // Finally, try local storage
      return await _getStageDocumentFromLocal(language, categoryId, stageName);
    } catch (e) {
      await _logStageOperation('fetch_stage_doc_error', categoryId, e.toString());
      return {};
    }
  }

  Future<void> _storeStageDocumentLocally(String language, String categoryId, String stageName, Map<String, dynamic> stageData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Store individual stage document
      String docKey = '${STAGES_CACHE_KEY_PREFIX}doc_$language.$categoryId.$stageName';
      await prefs.setString(docKey, jsonEncode(stageData));

      // Update stage in the list
      String listKey = '${STAGES_CACHE_KEY}_$categoryId';
      String? stagesJson = prefs.getString(listKey);
      if (stagesJson != null) {
        List<dynamic> stages = jsonDecode(stagesJson);
        int index = stages.indexWhere((s) => s['stageName'] == stageName);
        if (index != -1) {
          stages[index] = stageData;
          await prefs.setString(listKey, jsonEncode(stages));
        }
      }

    } catch (e) {
      await _logStageOperation('store_stage_doc_error', categoryId, e.toString());
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
    }
  }

  Future<bool> checkStageExists(String stageId) async {
    try {
      var stages = await _getStagesFromLocal('all');
      return stages.any((stage) => stage['id'] == stageId);
    } catch (e) {
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
    }
    return DateTime.now().subtract(const Duration(days: 31)); // Return old date to trigger cleanup
  }

  Future<void> _updateLastAccess(String key) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${key}_last_access', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
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
      return;
    }

    try {
      _setSyncState(true);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Sync categories by re-fetching them
        final enCategories = await fetchCategories('en');
        final filCategories = await fetchCategories('fil');
        
        // Sync stages for each category using existing fetchStages method
        for (var category in enCategories) {
          await fetchStages('en', category['id']);
        }
        
        for (var category in filCategories) {
          await fetchStages('fil', category['id']);
        }

      }
    } catch (e) {
    } finally {
      _setSyncState(false);
    }
  }

  // Add these methods to StageService class

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

  // Add these constants at the top of the class
  static const String LAST_ADMIN_UPDATE_KEY = 'last_admin_update';
  static const String LAST_PREFETCH_KEY = 'last_prefetch';

  // Add these methods to track admin updates and prefetch timing
  Future<void> updateLastAdminUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_ADMIN_UPDATE_KEY, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> getLastAdminUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(LAST_ADMIN_UPDATE_KEY) ?? 0;
  }

  Future<void> updateLastPrefetchTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_PREFETCH_KEY, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> getLastPrefetchTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(LAST_PREFETCH_KEY) ?? 0;
  }

  Future<void> clearLocalCache() async {
    _stageCache.clear();
    _categoryCache.clear();
    
    final prefs = await SharedPreferences.getInstance();
    for (String key in prefs.getKeys()) {
      if (key.startsWith(STAGES_CACHE_KEY) || 
          key.startsWith(CATEGORIES_CACHE_KEY) ||
          key.startsWith(LOCAL_STORAGE_VERSION)) {
        await prefs.remove(key);
      }
    }
  }

  // Add these constants at the top of the class
  static const String SERVER_TIMESTAMP_KEY = 'server_stage_timestamp';
  static const String LOCAL_TIMESTAMP_KEY = 'local_stage_timestamp';

  // Add method to get server timestamp
  Future<int> getServerTimestamp() async {
    try {
      DocumentSnapshot doc = await _stageDoc.get();
      if (doc.exists) {
        Timestamp? timestamp = doc.get('lastModified') as Timestamp?;
        if (timestamp != null) {
          return timestamp.millisecondsSinceEpoch;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Add method to check if server has newer data
  Future<bool> hasServerUpdates() async {
    try {
      
      // Get server timestamp
      int serverTimestamp = await getServerTimestamp();
      
      // Get local timestamp
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int localTimestamp = prefs.getInt(LOCAL_TIMESTAMP_KEY) ?? 0;
      
      
      return serverTimestamp > localTimestamp;
    } catch (e) {
      return true; // Force refresh on error to be safe
    }
  }

  // Update this method to store the server timestamp after successful fetch
  Future<List<Map<String, dynamic>>> _fetchFreshStages(String language, String categoryId) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      
      // Get server timestamp first
      int serverTimestamp = await getServerTimestamp();
      
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
          'language': language,  // Add language to stage data
          ...data,
        };
      }).toList();

      // Update both caches
      String cacheKey = '${language}_${categoryId}_stages';
      _stageCache[cacheKey] = CachedStage(
        data: {'stages': stages},
        timestamp: DateTime.now(),
        priority: StagePriority.HIGH
      );
      
      await _storeStagesLocally(stages, categoryId);
      
      // Store the server timestamp
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LOCAL_TIMESTAMP_KEY, serverTimestamp);
      
      
      return stages;
    }
    
    return [];
  }

  // Update these methods to update server timestamp
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

        // Update local cache and storage
        String cacheKey = '${language}_${categoryId}_stages';
        List<Map<String, dynamic>> currentStages = [];
        
        // Get current stages from cache or storage
        if (_stageCache.containsKey(cacheKey)) {
          currentStages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
        } else {
          currentStages = await getStagesFromLocal('${STAGES_CACHE_KEY}_$categoryId');
        }

        // Add new stage
        currentStages.add({
          'stageName': stageName,
          ...stageData,
        });

        // Update cache
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': currentStages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );

        // Update local storage
        await _storeStagesLocally(currentStages, categoryId);

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
      await _logStageOperation('add_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<void> updateStage(String language, String categoryId, String stageName, Map<String, dynamic> updatedData) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        // Start a batch write
        WriteBatch batch = _firestore.batch();

        // 1. Update the stage document
        DocumentReference stageRef = _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId)
            .collection('stages')
            .doc(stageName);

        batch.update(stageRef, {
          ...updatedData,
          'lastModified': FieldValue.serverTimestamp(),
        });

        // 2. Update the category document timestamp
        DocumentReference categoryRef = _firestore
            .collection('Game')
            .doc('Stage')
            .collection(language)
            .doc(categoryId);

        batch.update(categoryRef, {
          'lastModified': FieldValue.serverTimestamp(),
        });

        // 3. Update the root Stage document timestamp
        DocumentReference rootRef = _firestore
            .collection('Game')
            .doc('Stage');

        batch.update(rootRef, {
          'lastModified': FieldValue.serverTimestamp(),
        });

        // Commit all updates atomically
        await batch.commit();

        // Update local cache and storage
        String cacheKey = '${language}_${categoryId}_stages';
        List<Map<String, dynamic>> currentStages = [];
        
        // Get current stages from cache or storage
        if (_stageCache.containsKey(cacheKey)) {
          currentStages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
        } else {
          currentStages = await getStagesFromLocal('${STAGES_CACHE_KEY}_$categoryId');
        }

        // Update the stage in the list
        int index = currentStages.indexWhere((s) => s['stageName'] == stageName);
        if (index != -1) {
          currentStages[index] = {
            ...currentStages[index],
            ...updatedData,
            'lastModified': DateTime.now().millisecondsSinceEpoch,
          };
        }

        // Update cache with new data
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': currentStages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );

        // Update individual stage cache
        String stageKey = '${language}_${categoryId}_${stageName}_doc';
        _stageCache[stageKey] = CachedStage(
          data: {...updatedData, 'lastModified': DateTime.now().millisecondsSinceEpoch},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );

        // Update local storage
        await _storeStagesLocally(currentStages, categoryId);

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

        // Update local cache and storage
        String cacheKey = '${language}_${categoryId}_stages';
        List<Map<String, dynamic>> currentStages = [];
        
        // Get current stages from cache or storage
        if (_stageCache.containsKey(cacheKey)) {
          currentStages = List<Map<String, dynamic>>.from(_stageCache[cacheKey]!.data['stages']);
        } else {
          currentStages = await getStagesFromLocal('${STAGES_CACHE_KEY}_$categoryId');
        }

        // Remove the stage
        currentStages.removeWhere((s) => s['stageName'] == stageName);

        // Update cache
        _stageCache[cacheKey] = CachedStage(
          data: {'stages': currentStages},
          timestamp: DateTime.now(),
          priority: StagePriority.HIGH
        );

        // Update local storage
        await _storeStagesLocally(currentStages, categoryId);

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
      await _logStageOperation('delete_stage_error', categoryId, e.toString());
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRandomizedArcadeQuestions(
    String categoryId,
    String language,
    {int questionCount = 25}
  ) async {
    try {
      
      // Get all non-arcade stages for this category
      List<Map<String, dynamic>> stages = await getStagesFromLocal(categoryId, useRawCache: false);
      
      // Filter stages by language and exclude arcade stages
      stages = stages.where((stage) => 
        !stage['stageName'].toLowerCase().contains('arcade') &&
        (stage['language'] ?? 'en') == language
      ).toList();


      // Collect all questions from these stages
      List<Map<String, dynamic>> allQuestions = [];
      for (var stage in stages) {
        if (stage['questions'] != null) {
          final stageQuestions = List<Map<String, dynamic>>.from(stage['questions']);
          allQuestions.addAll(stageQuestions);
        }
      }


      // Shuffle questions
      allQuestions.shuffle();

      // If we don't have enough questions, repeat some to reach the desired count
      if (allQuestions.length < questionCount) {
        final originalQuestions = List<Map<String, dynamic>>.from(allQuestions);
        while (allQuestions.length < questionCount) {
          originalQuestions.shuffle(); // Shuffle again for more randomness
          allQuestions.addAll(originalQuestions.take(questionCount - allQuestions.length));
        }
      }

      // Take exactly questionCount questions
      final selectedQuestions = allQuestions.take(questionCount).toList();

      return selectedQuestions;
    } catch (e) {
      return [];
    }
  }
}