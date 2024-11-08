import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BadgeService {
  final DocumentReference _badgeDoc = FirebaseFirestore.instance.collection('Game').doc('Badge');
  static const String BADGES_CACHE_KEY = 'badges_cache';
  static const String BADGE_REVISION_KEY = 'badge_revision';
  static const int MAX_STORED_VERSIONS = 5;
  static const int MAX_CACHE_SIZE = 100;

  // Memory cache
  final Map<int, Map<String, dynamic>> _badgeCache = {};

  // Stream controller for real-time updates
  final _badgeUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get badgeUpdates => _badgeUpdateController.stream;

  Timer? _fetchDebounce;

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    if (_fetchDebounce?.isActive ?? false) {
      return _getBadgesFromLocal();
    }
    
    _fetchDebounce = Timer(const Duration(milliseconds: 500), () {});
    
    try {
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      var connectivityResult = await (Connectivity().checkConnectivity());
      
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int serverRevision = data.containsKey('revision') ? data['revision'] : 0;
          
          if (!data.containsKey('revision')) {
            await _badgeDoc.update({
              'revision': 0,
              'lastModified': FieldValue.serverTimestamp(),
            });
          }
          
          int localRevision = await _getLocalRevision() ?? -1;
          
          if (serverRevision > localRevision || localBadges.isEmpty) {
            final badges = await _fetchAndUpdateLocal(snapshot);
            _badgeUpdateController.add(badges);
            return badges;
          }
        } else {
          await _badgeDoc.set({
            'badges': [],
            'revision': 0,
            'lastModified': FieldValue.serverTimestamp(),
          });
        }
      }
      return localBadges;
    } catch (e) {
      print('Error in fetchBadges: $e');
      await _logBadgeOperation('fetch_error', -1, e.toString());
      return await _getBadgesFromLocal();
    } finally {
      _fetchDebounce?.cancel();
    }
  }

  Future<Map<String, dynamic>?> getBadgeById(int id) async {
    try {
      if (_badgeCache.containsKey(id)) {
        return _badgeCache[id];
      }
      
      List<Map<String, dynamic>> badges = await _getBadgesFromLocal();
      var badge = badges.firstWhere((b) => b['id'] == id, orElse: () => {});
      
      if (badge.isNotEmpty) {
        _badgeCache[id] = badge;
        return badge;
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          List<Map<String, dynamic>> serverBadges = List<Map<String, dynamic>>.from(
              (snapshot.data() as Map<String, dynamic>)['badges'] ?? []);
          var serverBadge = serverBadges.firstWhere((b) => b['id'] == id, orElse: () => {});
          if (serverBadge.isNotEmpty) {
            _badgeCache[id] = serverBadge;
            return serverBadge;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error in getBadgeById: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndUpdateLocal(DocumentSnapshot snapshot) async {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    List<Map<String, dynamic>> badges = 
        data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
    
    await _storeBadgesLocally(badges);
    await _storeLocalRevision(snapshot.get('revision') ?? 0);
    await cleanupOldVersions();
    
    return badges;
  }

  Future<void> _storeBadgesLocally(List<Map<String, dynamic>> badges) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Store backup before updating
      String? existingData = prefs.getString(BADGES_CACHE_KEY);
      if (existingData != null) {
        await prefs.setString('${BADGES_CACHE_KEY}_backup', existingData);
      }
      
      String badgesJson = jsonEncode(badges);
      await prefs.setString(BADGES_CACHE_KEY, badgesJson);
      
      // Clear backup after successful update
      await prefs.remove('${BADGES_CACHE_KEY}_backup');
    } catch (e) {
      await _restoreFromBackup();
      print('Error storing badges locally: $e');
    }
  }

  Future<void> _restoreFromBackup() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? backup = prefs.getString('${BADGES_CACHE_KEY}_backup');
      if (backup != null) {
        await prefs.setString(BADGES_CACHE_KEY, backup);
      }
    } catch (e) {
      print('Error restoring from backup: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getBadgesFromLocal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? badgesJson = prefs.getString(BADGES_CACHE_KEY);
      if (badgesJson != null) {
        List<dynamic> badgesList = jsonDecode(badgesJson);
        return badgesList.map((badge) => badge as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error getting badges from local: $e');
    }
    return [];
  }

  Future<void> cleanupOldVersions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys()
          .where((key) => key.startsWith('badge_version_'))
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

  Future<void> _logBadgeOperation(String operation, int badgeId, String details) async {
    try {
      await FirebaseFirestore.instance.collection('Logs').add({
        'type': 'badge_operation',
        'operation': operation,
        'badgeId': badgeId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging operation: $e');
    }
  }

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(BADGE_REVISION_KEY);
  }

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(BADGE_REVISION_KEY, revision);
  }

  void clearBadgeCache(int id) {
    _badgeCache.remove(id);
  }

  void dispose() {
    _badgeUpdateController.close();
  }

  // Data integrity check
  Future<void> _verifyDataIntegrity() async {
    try {
      List<Map<String, dynamic>> serverBadges = [];
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          serverBadges = List<Map<String, dynamic>>.from(data['badges'] ?? []);
        }
      }

      bool needsRepair = false;
      
      // Check for duplicate IDs
      Set<int> seenIds = {};
      for (var badge in localBadges) {
        int id = badge['id'];
        if (seenIds.contains(id)) {
          needsRepair = true;
          break;
        }
        seenIds.add(id);
      }

      // Compare with server data if available
      if (serverBadges.isNotEmpty && serverBadges.length != localBadges.length) {
        needsRepair = true;
      }

      if (needsRepair) {
        await resolveConflicts(serverBadges, localBadges);
        await _logBadgeOperation('integrity_repair', -1, 'Data repaired');
      }

      _badgeCache.clear();
    } catch (e) {
      print('Error verifying data integrity: $e');
      await _logBadgeOperation('integrity_check_error', -1, e.toString());
    }
  }

  Future<void> resolveConflicts(List<Map<String, dynamic>> serverBadges, List<Map<String, dynamic>> localBadges) async {
    try {
      Map<int, Map<String, dynamic>> mergedBadges = {};
      
      for (var badge in serverBadges) {
        mergedBadges[badge['id']] = badge;
      }
      
      for (var localBadge in localBadges) {
        int id = localBadge['id'];
        if (!mergedBadges.containsKey(id) || 
            (localBadge['lastModified'] ?? 0) > (mergedBadges[id]!['lastModified'] ?? 0)) {
          mergedBadges[id] = localBadge;
        }
      }
      
      List<Map<String, dynamic>> resolvedBadges = mergedBadges.values.toList();
      await _storeBadgesLocally(resolvedBadges);
      await _updateServerBadges(resolvedBadges);
    } catch (e) {
      print('Error resolving conflicts: $e');
      await _logBadgeOperation('conflict_resolution_error', -1, e.toString());
    }
  }

  Future<void> _updateServerBadges(List<Map<String, dynamic>> badges) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _badgeDoc.update({
          'badges': badges,
          'revision': FieldValue.increment(1),
          'lastModified': FieldValue.serverTimestamp(),
        });
        await _logBadgeOperation('server_update', -1, 'Updated ${badges.length} badges');
      }
    } catch (e) {
      print('Error updating server badges: $e');
      await _logBadgeOperation('server_update_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> addBadge(Map<String, dynamic> badge) async {
    try {
      int nextId = await getNextId();
      badge['id'] = nextId;
      
      List<Map<String, dynamic>> badges = await fetchBadges();
      badges.add(badge);
      
      await _storeBadgesLocally(badges);
      await _updateServerBadges(badges);
    } catch (e) {
      print('Error adding badge: $e');
      await _logBadgeOperation('add_error', -1, e.toString());
      rethrow;
    }
  }

  Future<void> updateBadge(int id, Map<String, dynamic> updatedBadge) async {
    try {
      List<Map<String, dynamic>> badges = await fetchBadges();
      int index = badges.indexWhere((b) => b['id'] == id);
      if (index != -1) {
        badges[index] = updatedBadge;
        await _storeBadgesLocally(badges);
        await _updateServerBadges(badges);
      }
    } catch (e) {
      print('Error updating badge: $e');
      await _logBadgeOperation('update_error', id, e.toString());
      rethrow;
    }
  }

  Future<void> deleteBadge(int id) async {
    try {
      List<Map<String, dynamic>> badges = await fetchBadges();
      badges.removeWhere((b) => b['id'] == id);
      await _storeBadgesLocally(badges);
      await _updateServerBadges(badges);
    } catch (e) {
      print('Error deleting badge: $e');
      await _logBadgeOperation('delete_error', id, e.toString());
      rethrow;
    }
  }

  Future<int> getNextId() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> badges = 
              data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
          if (badges.isNotEmpty) {
            return badges.map((badge) => badge['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
        return 0;
      }

      // If offline, calculate from local storage
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      if (localBadges.isNotEmpty) {
        return localBadges.map((badge) => badge['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      return 0;
    } catch (e) {
      print('Error getting next badge ID: $e');
      return 0; // Start with 0 in case of error
    }
  }

  void _manageCacheSize() {
    if (_badgeCache.length > MAX_CACHE_SIZE) {
      final keysToRemove = _badgeCache.keys.take(_badgeCache.length - MAX_CACHE_SIZE);
      for (var key in keysToRemove) {
        _badgeCache.remove(key);
      }
    }
  }

  Future<void> invalidateCache() async {
    _badgeCache.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(BADGES_CACHE_KEY);
  }
}