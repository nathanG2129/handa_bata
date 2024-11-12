import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:collection';
import 'package:handabatamae/shared/connection_quality.dart';

enum LoadPriority {
  CRITICAL,  // Current user's avatar
  HIGH,      // Visible avatars
  MEDIUM,    // Next likely needed
  LOW        // Background loading
}

class LoadRequest {
  final int avatarId;
  final LoadPriority priority;
  final DateTime timestamp;
  final Completer<Map<String, dynamic>> completer;
  
  LoadRequest({
    required this.avatarId,
    required this.priority,
    required this.timestamp,
    required this.completer,
  });
}

class CachedAvatar {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  CachedAvatar(this.data, this.timestamp);
  
  bool get isValid => 
    DateTime.now().difference(timestamp) < const Duration(hours: 1);
}

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal() {
    _connectionManager.connectionQuality.listen((quality) {
      _connectionQualityController.add(quality);
    });
    _startQueueProcessing();
  }

  final DocumentReference _avatarDoc = FirebaseFirestore.instance.collection('Game').doc('Avatar');
  
  static const String AVATARS_CACHE_KEY = 'avatars_cache';
  static const String AVATAR_VERSION_KEY = 'avatar_version';
  static const String AVATAR_REVISION_KEY = 'avatar_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;
  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  static const Duration CACHE_DURATION = Duration(hours: 1);

  static final Map<int, CachedAvatar> _avatarCache = {};
  static final Map<String, CachedAvatar> _batchCache = {};

  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  final _avatarUpdateController = StreamController<Map<int, String>>.broadcast();
  Stream<Map<int, String>> get avatarUpdates => _avatarUpdateController.stream;

  final _avatarImageController = StreamController<Map<int, String>>.broadcast();
  Stream<Map<int, String>> get avatarImageUpdates => _avatarImageController.stream;

  final Map<LoadPriority, Queue<LoadRequest>> _loadQueues = {
    LoadPriority.CRITICAL: Queue<LoadRequest>(),
    LoadPriority.HIGH: Queue<LoadRequest>(),
    LoadPriority.MEDIUM: Queue<LoadRequest>(),
    LoadPriority.LOW: Queue<LoadRequest>(),
  };

  final ConnectionManager _connectionManager = ConnectionManager();
  final StreamController<ConnectionQuality> _connectionQualityController = 
      StreamController<ConnectionQuality>.broadcast();
  Stream<ConnectionQuality> get connectionQuality => _connectionQualityController.stream;

  Future<void> _startQueueProcessing() async {
    while (true) {
      try {
        // Process CRITICAL queue immediately
        await _processQueue(LoadPriority.CRITICAL);

        // Process other queues based on connection quality
        switch (await _connectionManager.checkConnectionQuality()) {
          case ConnectionQuality.EXCELLENT:
            await _processQueue(LoadPriority.HIGH);
            await _processQueue(LoadPriority.MEDIUM);
            await _processQueue(LoadPriority.LOW);
            break;
          case ConnectionQuality.GOOD:
            await _processQueue(LoadPriority.HIGH);
            await _processQueue(LoadPriority.MEDIUM);
            break;
          case ConnectionQuality.POOR:
            await _processQueue(LoadPriority.HIGH);
            break;
          case ConnectionQuality.OFFLINE:
            // Only process from cache
            print('📡 Offline - Only processing from cache');
            break;
        }
      } catch (e) {
        print('Error processing load queue: $e');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _processQueue(LoadPriority priority) async {
    final queue = _loadQueues[priority]!;
    while (queue.isNotEmpty) {
      final request = queue.removeFirst();
      try {
        final result = await _fetchAvatarWithPriority(
          request.avatarId, 
          request.priority
        );
        request.completer.complete(result);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }

  Future<void> _updateVersion() async {
    try {
      await _avatarDoc.update({
        'version': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating avatar version: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvatars({bool isAdmin = false}) async {
    try {
      final cacheKey = 'all_avatars${isAdmin ? '_admin' : ''}';
      
      if (isAdmin) {
        // For admin, always fetch from server
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (!snapshot.exists) return [];

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = 
            data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
            
        // Update both caches
        _batchCache[cacheKey] = CachedAvatar({'avatars': avatars}, DateTime.now());
        for (var avatar in avatars) {
          _addToCache(avatar['id'], avatar);
        }
        
        return avatars;
      }

      // Check batch cache first
      if (_batchCache.containsKey(cacheKey) && _batchCache[cacheKey]!.isValid) {
        return List<Map<String, dynamic>>.from(_batchCache[cacheKey]!.data['avatars']);
      }

      // Get from local storage first
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      
      // If local storage is empty, try fetching from server
      if (localAvatars.isEmpty) {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot snapshot = await _avatarDoc.get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            localAvatars = data['avatars'] != null ? 
                List<Map<String, dynamic>>.from(data['avatars']) : [];
            
            // Update caches and local storage
            _batchCache[cacheKey] = CachedAvatar({'avatars': localAvatars}, DateTime.now());
            for (var avatar in localAvatars) {
              _addToCache(avatar['id'], avatar);
            }
            await _storeAvatarsLocally(localAvatars);
          }
        }
      }
      
      return localAvatars;
    } catch (e) {
      print('Error in fetchAvatars: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(DocumentSnapshot snapshot) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> avatars = 
        data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
    
    await _storeAvatarsLocally(avatars);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return avatars;
  }

  Future<Timestamp?> _getLocalVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? versionStr = prefs.getString(AVATAR_VERSION_KEY);
    if (versionStr != null) {
      return Timestamp.fromMillisecondsSinceEpoch(int.parse(versionStr));
    }
    return null;
  }

  Future<void> _storeLocalVersion(Timestamp version) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AVATAR_VERSION_KEY, version.millisecondsSinceEpoch.toString());
  }

  bool _validateAvatarData(Map<String, dynamic> avatar) {
    return avatar.containsKey('id') &&
           avatar.containsKey('img') &&
           avatar.containsKey('title') &&
           avatar['img'].toString().isNotEmpty &&
           avatar['title'].toString().isNotEmpty;
  }

  Future<void> _storeAvatarsLocally(List<Map<String, dynamic>> avatars) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Store backup before updating
      String? existingData = prefs.getString(AVATARS_CACHE_KEY);
      if (existingData != null) {
        await prefs.setString('${AVATARS_CACHE_KEY}_backup', existingData);
      }
      
      String avatarsJson = jsonEncode(avatars);
      await prefs.setString(AVATARS_CACHE_KEY, avatarsJson);
      
      // Clear backup after successful update
      await prefs.remove('${AVATARS_CACHE_KEY}_backup');
    } catch (e) {
      // Try to restore from backup
      await _restoreFromBackup();
      print('Error storing avatars locally: $e');
    }
  }

  Future<void> _restoreFromBackup() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('${AVATARS_CACHE_KEY}_backup');
      if (backup != null) {
        await prefs.setString(AVATARS_CACHE_KEY, backup);
      }
    } catch (e) {
      print('Error restoring from backup: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getAvatarsFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? avatarsJson = prefs.getString(AVATARS_CACHE_KEY);
      if (avatarsJson != null) {
        List<dynamic> avatarsList = jsonDecode(avatarsJson);
        return avatarsList.map((avatar) => avatar as Map<String, dynamic>).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return []; // Return empty list if local storage fails or is empty
  }

  Future<int> getNextId() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> avatars = 
              data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
          if (avatars.isNotEmpty) {
            return avatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        return 0;
      }

      // If offline, calculate from local storage
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      if (localAvatars.isNotEmpty) {
        return localAvatars.map((avatar) => avatar['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      return 0;
    } catch (e) {
      return 0; // Start with 0 in case of error
    }
  }

  Future<void> addAvatar(Map<String, dynamic> avatar) async {
    try {
      // Get current avatars
      DocumentSnapshot snapshot = await _avatarDoc.get();
      List<Map<String, dynamic>> avatars = [];
      
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        avatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
      }

      // Generate new ID
      int newId = 1;
      if (avatars.isNotEmpty) {
        newId = avatars.map((a) => a['id'] as int).reduce(max) + 1;
      }

      // Add new avatar with ID
      avatar['id'] = newId;
      avatars.add(avatar);

      // Update Firestore
      await _avatarDoc.set({
        'avatars': avatars,
        'revision': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Update cache
      _addToCache(newId, avatar);
      
      // Update version
      await _updateVersion();
    } catch (e) {
      print('Error adding avatar: $e');
      throw Exception('Failed to add avatar');
    }
  }

  Future<void> updateAvatar(int id, Map<String, dynamic> updatedAvatar) async {
    try {
      // Get current avatars
      DocumentSnapshot snapshot = await _avatarDoc.get();
      if (!snapshot.exists) throw Exception('Avatar document not found');

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> avatars = 
          data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];

      // Find and update avatar
      int index = avatars.indexWhere((avatar) => avatar['id'] == id);
      if (index == -1) throw Exception('Avatar not found');

      // Store old data for logging
      Map<String, dynamic> oldAvatar = Map<String, dynamic>.from(avatars[index]);
      
      // Update avatar
      avatars[index] = updatedAvatar;

      // Update Firestore
      await _avatarDoc.update({
        'avatars': avatars,
        'revision': FieldValue.increment(1),
      });

      // Update cache
      _addToCache(id, updatedAvatar);
      
      // Update version
      await _updateVersion();

      // Log the operation with details of what changed
      String changeDetails = 'Changed: ${_getChangedFields(oldAvatar, updatedAvatar)}';
      await _logAvatarOperation('update', id, changeDetails);

    } catch (e) {
      print('Error updating avatar: $e');
      await _logAvatarOperation('update_error', id, e.toString());
      throw Exception('Failed to update avatar');
    }
  }

  String _getChangedFields(Map<String, dynamic> oldAvatar, Map<String, dynamic> newAvatar) {
    List<String> changes = [];
    
    newAvatar.forEach((key, value) {
      if (oldAvatar[key] != value) {
        changes.add('$key: ${oldAvatar[key]} → $value');
      }
    });
    
    return changes.join(', ');
  }

  Future<void> deleteAvatar(int id) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(_avatarDoc);
        if (!snapshot.exists) throw Exception('Avatar document not found');

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = 
            data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];

        // Remove avatar
        avatars.removeWhere((avatar) => avatar['id'] == id);

        // Update document
        transaction.update(_avatarDoc, {
          'avatars': avatars,
          'revision': FieldValue.increment(1),
        });

        // Remove from cache
        _avatarCache.remove(id);
      });

      // Update version after successful deletion
      await _updateVersion();
    } catch (e) {
      print('Error deleting avatar: $e');
      throw Exception('Failed to delete avatar');
    }
  }

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AVATAR_REVISION_KEY);
  }

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AVATAR_REVISION_KEY, revision);
  }

  Future<void> cleanupOldVersions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys()
          .where((key) => key.startsWith('avatar_version_'))
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

  Future<void> _logAvatarOperation(String operation, int avatarId, String details) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'avatar_operation',
        'operation': operation,
        'avatarId': avatarId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  Future<void> resolveConflicts(List<Map<String, dynamic>> serverAvatars, List<Map<String, dynamic>> localAvatars) async {
    try {
      // Compare timestamps and take newer versions
      Map<int, Map<String, dynamic>> mergedAvatars = {};
      
      // Add server avatars
      for (var avatar in serverAvatars) {
        mergedAvatars[avatar['id']] = avatar;
      }
      
      // Compare with local avatars
      for (var localAvatar in localAvatars) {
        int id = localAvatar['id'];
        if (!mergedAvatars.containsKey(id) || 
            (localAvatar['lastModified'] ?? 0) > (mergedAvatars[id]!['lastModified'] ?? 0)) {
          mergedAvatars[id] = localAvatar;
        }
      }
      
      // Update both local and server
      List<Map<String, dynamic>> resolvedAvatars = mergedAvatars.values.toList();
      await _storeAvatarsLocally(resolvedAvatars);
      await _updateServerAvatars(resolvedAvatars);
    } catch (e) {
      print('Error resolving conflicts: $e');
      await _logAvatarOperation('conflict_resolution_error', -1, e.toString());
    }
  }

  void dispose() {
    _avatarUpdateController.close();
    _avatarImageController.close();
    _syncDebounceTimer?.cancel();
    _syncStatusController.close();
    _connectionQualityController.close();
  }

  Future<Map<String, dynamic>?> getAvatarDetails(
    int id, {
    LoadPriority priority = LoadPriority.HIGH
  }) async {
    // Check memory cache first
    if (_avatarCache.containsKey(id) && _avatarCache[id]!.isValid) {
      return _avatarCache[id]!.data;
    }

    // Create load request
    final completer = Completer<Map<String, dynamic>>();
    final request = LoadRequest(
      avatarId: id,
      priority: priority,
      timestamp: DateTime.now(),
      completer: completer,
    );

    _loadQueues[priority]!.add(request);

    return completer.future;
  }

  Future<Map<String, dynamic>?> _fetchAvatarWithPriority(
    int id,
    LoadPriority priority
  ) async {
    try {
      // Check local storage first
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      var avatar = localAvatars.firstWhere(
        (a) => a['id'] == id,
        orElse: () => {},
      );

      if (avatar.isNotEmpty) {
        _addToCache(id, avatar);
        return avatar;
      }

      // Only fetch from server for HIGH or CRITICAL priority when offline
      if (await _connectionManager.checkConnectionQuality() == ConnectionQuality.OFFLINE && 
          priority != LoadPriority.CRITICAL &&
          priority != LoadPriority.HIGH) {
        return null;
      }

      // Fetch from server with timeout based on priority
      final timeout = _getTimeoutForPriority(priority);
      DocumentSnapshot doc = await _avatarDoc.get().timeout(timeout);
            
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = 
            List<Map<String, dynamic>>.from(data['avatars'] ?? []);
              
        var serverAvatar = avatars.firstWhere(
          (a) => a['id'] == id,
          orElse: () => {},
        );
          
        if (serverAvatar.isNotEmpty) {
          _addToCache(id, serverAvatar);
          return serverAvatar;
        }
      }

      return null;
    } catch (e) {
      print('Error in _fetchAvatarWithPriority: $e');
      return null;
    }
  }

  Duration _getTimeoutForPriority(LoadPriority priority) {
    switch (priority) {
      case LoadPriority.CRITICAL:
        return const Duration(seconds: 10);
      case LoadPriority.HIGH:
        return const Duration(seconds: 5);
      case LoadPriority.MEDIUM:
        return const Duration(seconds: 3);
      case LoadPriority.LOW:
        return const Duration(seconds: 2);
    }
  }

  void _addToCache(int id, Map<String, dynamic> data) {
    _avatarCache[id] = CachedAvatar(data, DateTime.now());
    _manageCacheSize();
  }

  void _manageCacheSize() {
    if (_avatarCache.length > MAX_CACHE_SIZE) {
      // Remove oldest or invalid entries first
      var entriesByAge = _avatarCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      for (var entry in entriesByAge) {
        if (_avatarCache.length <= MAX_CACHE_SIZE) break;
        if (!entry.value.isValid) {
          _avatarCache.remove(entry.key);
        }
      }
      
      // If still too large, remove oldest entries
      while (_avatarCache.length > MAX_CACHE_SIZE) {
        var oldest = entriesByAge.removeAt(0);
        _avatarCache.remove(oldest.key);
      }
    }
  }

  void clearAvatarCache(int id) {
    _avatarCache.remove(id);
    _batchCache.clear(); // Clear batch cache as it might contain outdated data
  }

  Future<void> clearAllCaches() async {
    _avatarCache.clear();
    _batchCache.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AVATARS_CACHE_KEY);
  }

  Future<void> performMaintenance() async {
    try {
      // Clean up old versions
      await cleanupOldVersions();
      
      // Clear old logs
      await _cleanupOldLogs();
      
      // Verify data integrity
      await _verifyDataIntegrity();
      
      // Clear memory cache
      _avatarCache.clear();
    } catch (e) {
      print('Error during maintenance: $e');
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      // Delete logs older than 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await FirebaseFirestore.instance
          .collection('Logs')
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

  Future<void> _updateServerAvatars(List<Map<String, dynamic>> avatars) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _avatarDoc.update({
          'avatars': avatars,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });
        
        // Log successful update
        await _logAvatarOperation('server_update', -1, 'Updated ${avatars.length} avatars');
      }
    } catch (e) {
      print('Error updating server avatars: $e');
      await _logAvatarOperation('server_update_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> _verifyDataIntegrity() async {
    try {
      // Get both server and local data
      List<Map<String, dynamic>> serverAvatars = [];
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverAvatars = List<Map<String, dynamic>>.from(data['avatars'] ?? []);
        }
      }

      // Check for data inconsistencies
      bool needsRepair = false;
      
      // 1. Check for duplicate IDs
      Set<int> seenIds = {};
      for (var avatar in localAvatars) {
        int id = avatar['id'];
        if (seenIds.contains(id)) {
          needsRepair = true;
          break;
        }
        seenIds.add(id);
      }

      // 2. Validate all avatar data
      for (var avatar in localAvatars) {
        if (!_validateAvatarData(avatar)) {
          needsRepair = true;
          break;
        }
      }

      // 3. Compare with server data if available
      if (serverAvatars.isNotEmpty && serverAvatars.length != localAvatars.length) {
        needsRepair = true;
      }

      // Repair if needed
      if (needsRepair) {
        await resolveConflicts(serverAvatars, localAvatars);
        await _logAvatarOperation('integrity_repair', -1, 'Data repaired');
      }

      // Clear memory cache to ensure fresh data
      _avatarCache.clear();
      
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logAvatarOperation('integrity_check_error', -1, e.toString());
    }
  }

  Future<bool> getAvatarById(int id) async {
    final avatar = await getAvatarDetails(id);
    return avatar != null;
  }

  // Add this method to handle sync state
  void _setSyncState(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(syncing);
  }

  // Add new debounced sync method
  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(SYNC_DEBOUNCE, () {
      _syncWithServer();
    });
  }

  // Add new sync method
  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Avatar sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting avatar sync process');
      _setSyncState(true);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('📡 No internet connection, aborting avatar sync');
        return;
      }

      print('📥 Fetching avatar data from server');
      // Add timeout to prevent hanging
      DocumentSnapshot snapshot = await _avatarDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) {
        print('❌ Avatar document not found on server');
        return;
      }

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      print('📊 Server revision: $serverRevision, Local revision: $localRevision');

      // Only sync if server has newer data
      if (localRevision == null || serverRevision > localRevision) {
        print('🔄 Server has newer data, updating local cache');
        List<Map<String, dynamic>> serverAvatars = 
            await _fetchAndUpdateLocal(snapshot);
        
        print('💾 Updating memory cache with ${serverAvatars.length} avatars');
        // Update memory cache
        for (var avatar in serverAvatars) {
          _addToCache(avatar['id'], avatar);
        }

        print('📢 Notifying listeners of avatar updates');
        // Notify listeners of new data
        _avatarUpdateController.add({serverAvatars.first['id']: serverAvatars.first['img']});
      } else {
        print('✅ Local avatar data is up to date');
      }

    } catch (e) {
      print('❌ Error in avatar sync: $e');
    } finally {
      print('🏁 Avatar sync process completed');
      _setSyncState(false);
    }
  }

  // Add this public method
  void triggerBackgroundSync() {
    _debouncedSync();
  }
}