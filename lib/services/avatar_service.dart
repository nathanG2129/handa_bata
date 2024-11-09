import 'dart:async';
import 'dart:convert';
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

  // Enhanced fetch with version check
  Future<List<Map<String, dynamic>>> fetchAvatars() async {
    // Initialize empty list as fallback
    List<Map<String, dynamic>> localAvatars = [];
    
    try {
      localAvatars = await _getAvatarsFromLocal();
      var connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          int serverRevision = snapshot.get('revision') ?? 0;
          int localRevision = await _getLocalRevision() ?? -1;
          
          if (serverRevision > localRevision) {
            final avatars = await _fetchAndUpdateLocal(snapshot);
            _avatarUpdateController.add({avatars.first['id']: avatars.first['img']}); // Notify listeners
            return avatars;
          }
        }
      }
      return localAvatars;
    } catch (e) {
      print('Error in fetchAvatars: $e');
      await _logAvatarOperation('fetch_error', -1, e.toString());
      return localAvatars;
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

  // Enhanced delete with user profile updates
  Future<void> deleteAvatar(int id) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get current state
        DocumentSnapshot avatarDoc = await transaction.get(_avatarDoc);
        QuerySnapshot userProfiles = await FirebaseFirestore.instance
            .collectionGroup('ProfileData')
            .where('avatarId', isEqualTo: id)
            .get();

        // Prepare updates
        List<Map<String, dynamic>> avatars = List<Map<String, dynamic>>.from(
            (avatarDoc.data() as Map<String, dynamic>)['avatars'] ?? []);
        avatars.removeWhere((avatar) => avatar['id'] == id);

        // Update avatar document
        transaction.update(_avatarDoc, {
          'avatars': avatars,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });

        // Update affected user profiles
        for (var doc in userProfiles.docs) {
          transaction.update(doc.reference, {
            'avatarId': 0,
            'lastUpdated': FieldValue.serverTimestamp()
          });
        }

        // Update local cache after successful transaction
        await _storeAvatarsLocally(avatars);
        await _logAvatarOperation('delete', id, 'Success');
      });
    } catch (e) {
      print('Error in deleteAvatar: $e');
      await _logAvatarOperation('delete_error', id, e.toString());
      rethrow;
    }
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

  // Enhanced update with validation
  Future<void> updateAvatar(int id, Map<String, dynamic> updatedAvatar, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          if (!_validateAvatarData(updatedAvatar)) {
            throw Exception('Invalid avatar data');
          }

          DocumentSnapshot snapshot = await transaction.get(_avatarDoc);
          List<Map<String, dynamic>> avatars = List<Map<String, dynamic>>.from(
              (snapshot.data() as Map<String, dynamic>)['avatars'] ?? []);
          
          int index = avatars.indexWhere((avatar) => avatar['id'] == id);
          if (index == -1) throw Exception('Avatar not found');
          
          avatars[index] = updatedAvatar;
          
          transaction.update(_avatarDoc, {
            'avatars': avatars,
            'revision': FieldValue.increment(1),
            'lastModified': FieldValue.serverTimestamp(),
          });

          await _storeAvatarsLocally(avatars);
          await _logAvatarOperation('update', id, 'Success');
        });
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) {
          await _logAvatarOperation('update_error', id, e.toString());
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
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
      // 1. Get next available ID
      int nextId = await getNextId();
      avatar['id'] = nextId;
      
      // 2. Get current avatars list
      List<Map<String, dynamic>> avatars = await fetchAvatars();
      avatars.add(avatar);
      
      // 3. Save locally first
      await _storeAvatarsLocally(avatars);
      
      // 4. Then update Firebase if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _avatarDoc.update({'avatars': avatars});
      }
    } catch (e) {
      // If Firebase update fails, at least we have local storage
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
  }

  // Add better caching mechanism
  final Map<int, Map<String, dynamic>> _avatarCache = {};
  
  Future<Map<String, dynamic>?> getAvatarDetails(int id) async {
    try {
      if (_avatarCache.containsKey(id)) {
        var avatar = _avatarCache[id]!;
        _avatarImageController.add({id: avatar['img']});
        return avatar;
      }
      
      List<Map<String, dynamic>> avatars = await _getAvatarsFromLocal();
      var avatar = avatars.firstWhere((a) => a['id'] == id, orElse: () => {});
      
      if (avatar.isNotEmpty) {
        _avatarCache[id] = avatar;
        _manageCacheSize();
        _avatarImageController.add({id: avatar['img']});
        return avatar;
      }

      // Fetch from server if not found locally
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _avatarDoc.get();
        if (snapshot.exists) {
          List<Map<String, dynamic>> serverAvatars = List<Map<String, dynamic>>.from(
              (snapshot.data() as Map<String, dynamic>)['avatars'] ?? []);
          var serverAvatar = serverAvatars.firstWhere((a) => a['id'] == id, orElse: () => {});
          if (serverAvatar.isNotEmpty) {
            _avatarCache[id] = serverAvatar;
            _avatarImageController.add({id: serverAvatar['img']});
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
}