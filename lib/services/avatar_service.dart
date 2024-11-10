import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AvatarService {
  final DocumentReference _avatarDoc = FirebaseFirestore.instance.collection('Game').doc('Avatar');
  static const String AVATARS_CACHE_KEY = 'avatars_cache';
  static const String AVATAR_VERSION_KEY = 'avatar_version';
  static const String AVATAR_REVISION_KEY = 'avatar_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;
  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  // Add stream controller for real-time updates
  final _avatarUpdateController = StreamController<Map<int, String>>.broadcast();
  Stream<Map<int, String>> get avatarUpdates => _avatarUpdateController.stream;

  // Add stream for avatar image updates
  final _avatarImageController = StreamController<Map<int, String>>.broadcast();
  Stream<Map<int, String>> get avatarImageUpdates => _avatarImageController.stream;

  // Add version tracking
  Future<void> _updateVersion() async {
    try {
      await _avatarDoc.update({
        'version': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating avatar version: $e');
    }
  }

  // Modified fetch method for admin
  Future<List<Map<String, dynamic>>> fetchAvatars({bool isAdmin = false}) async {
    try {
      if (isAdmin) {
        // For admin, always fetch from server
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (!snapshot.exists) return [];

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> avatars = 
            data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
            
        // Update cache after fetching
        for (var avatar in avatars) {
          _avatarCache[avatar['id']] = avatar;
        }
        
        return avatars;
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
            localAvatars = data['avatars'] != null ? List<Map<String, dynamic>>.from(data['avatars']) : [];
            // Store in local
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

  // Version control helpers
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

  // Add avatar method
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
      _avatarCache[newId] = avatar;
      
      // Update version
      await _updateVersion();
    } catch (e) {
      print('Error adding avatar: $e');
      throw Exception('Failed to add avatar');
    }
  }

  // Update avatar method
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
      _avatarCache[id] = updatedAvatar;
      
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

  // Helper method to compare old and new avatar data
  String _getChangedFields(Map<String, dynamic> oldAvatar, Map<String, dynamic> newAvatar) {
    List<String> changes = [];
    
    newAvatar.forEach((key, value) {
      if (oldAvatar[key] != value) {
        changes.add('$key: ${oldAvatar[key]} → $value');
      }
    });
    
    return changes.join(', ');
  }

  // Delete avatar method
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

  // Add dispose method
  void dispose() {
    _avatarUpdateController.close();
    _avatarImageController.close();
    _syncDebounceTimer?.cancel();
    _syncStatusController.close();
  }

  // Add better caching mechanism
  final Map<int, Map<String, dynamic>> _avatarCache = {};
  
  Future<Map<String, dynamic>?> getAvatarDetails(int id) async {
    try {
      // Check memory cache first
      if (_avatarCache.containsKey(id)) {
        return _avatarCache[id];
      }

      // Check local storage
      List<Map<String, dynamic>> localAvatars = await _getAvatarsFromLocal();
      var avatar = localAvatars.firstWhere(
        (a) => a['id'] == id,
        orElse: () => {},
      );

      if (avatar.isNotEmpty) {
        _avatarCache[id] = avatar;
        return avatar;
      }

      // Only fetch from server if not found locally
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot doc = await _avatarDoc.get()
            .timeout(SYNC_TIMEOUT);
            
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> avatars = 
              List<Map<String, dynamic>>.from(data['avatars'] ?? []);
              
          var serverAvatar = avatars.firstWhere(
            (a) => a['id'] == id,
            orElse: () => {},
          );
          
          if (serverAvatar.isNotEmpty) {
            _avatarCache[id] = serverAvatar;
            return serverAvatar;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error in getAvatarDetails: $e');
      return null;
    }
  }

  // Add method to clear specific avatar from cache
  void clearAvatarCache(int id) {
    _avatarCache.remove(id);
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
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
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

  void _manageCacheSize() {
    if (_avatarCache.length > MAX_CACHE_SIZE) {
      // Remove oldest entries if cache is too large
      final keysToRemove = _avatarCache.keys.take(_avatarCache.length - MAX_CACHE_SIZE + 1);
      for (var key in keysToRemove) {
        _avatarCache.remove(key);
      }
    }
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
    if (_isSyncing) return;

    try {
      _setSyncState(true);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return;
      }

      // Add timeout to prevent hanging
      DocumentSnapshot snapshot = await _avatarDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) return;

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      // Only sync if server has newer data
      if (localRevision == null || serverRevision > localRevision) {
        List<Map<String, dynamic>> serverAvatars = 
            await _fetchAndUpdateLocal(snapshot);
        
        // Update memory cache
        for (var avatar in serverAvatars) {
          _avatarCache[avatar['id']] = avatar;
        }

        // Notify listeners of new data
        _avatarUpdateController.add({serverAvatars.first['id']: serverAvatars.first['img']});
      }

    } catch (e) {
      print('Error in sync: $e');
    } finally {
      _setSyncState(false);
    }
  }
}