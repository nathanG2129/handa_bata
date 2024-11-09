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
  
  // Sync-related constants and controllers
  static const Duration SYNC_DEBOUNCE = Duration(milliseconds: 500);
  static const Duration SYNC_TIMEOUT = Duration(seconds: 5);
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatus => _syncStatusController.stream;

  // Memory cache
  final Map<int, Map<String, dynamic>> _badgeCache = {};

  // Stream controller for real-time updates
  final _badgeUpdateController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get badgeUpdates => _badgeUpdateController.stream;

  void _setSyncState(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(syncing);
  }

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    try {
      // Return cached data immediately if available
      if (_badgeCache.isNotEmpty) {
        return _badgeCache.values.toList();
      }

      // Get local data
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      
      // Start sync process if online, but don't wait for it
      _debouncedSync();
      
      // Return local data immediately
      return localBadges;
    } catch (e) {
      print('Error in fetchBadges: $e');
      return [];
    }
  }

  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(SYNC_DEBOUNCE, () {
      _syncWithServer();
    });
  }

  Future<void> _syncWithServer() async {
    if (_isSyncing) return;

    try {
      _setSyncState(true);

      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return;
      }

      DocumentSnapshot snapshot = await _badgeDoc.get()
          .timeout(SYNC_TIMEOUT);

      if (!snapshot.exists) return;

      int serverRevision = snapshot.get('revision') ?? 0;
      int? localRevision = await _getLocalRevision();

      if (localRevision == null || serverRevision > localRevision) {
        List<Map<String, dynamic>> serverBadges = 
            await _fetchAndUpdateLocal(snapshot);
        
        // Update memory cache
        for (var badge in serverBadges) {
          _badgeCache[badge['id']] = badge;
        }

        // Notify listeners of new data
        _badgeUpdateController.add(serverBadges);
      }

    } catch (e) {
      print('Error in sync: $e');
    } finally {
      _setSyncState(false);
    }
  }

  Future<Map<String, dynamic>?> getBadgeDetails(int id) async {
    try {
      // Check memory cache first
      if (_badgeCache.containsKey(id)) {
        return _badgeCache[id];
      }

      // Check local storage
      List<Map<String, dynamic>> localBadges = await _getBadgesFromLocal();
      var badge = localBadges.firstWhere(
        (b) => b['id'] == id,
        orElse: () => {},
      );

      if (badge.isNotEmpty) {
        _badgeCache[id] = badge;
        return badge;
      }

      // Only fetch from server if not found locally
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
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
            _badgeCache[id] = serverBadge;
            return serverBadge;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error in getBadgeDetails: $e');
      return null;
    }
  }

  Future<void> addBadge(Map<String, dynamic> badge) async {
    try {
      int nextId = await getNextId();
      badge['id'] = nextId;
      
      List<Map<String, dynamic>> badges = await fetchBadges();
      badges.add(badge);
      
      // Update local first
      await _storeBadgesLocally(badges);
      _badgeCache[nextId] = badge;
      
      // Then update server if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _updateServerBadges(badges);
      }
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
        
        // Update local first
        await _storeBadgesLocally(badges);
        _badgeCache[id] = updatedBadge;
        
        // Then update server if online
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await _updateServerBadges(badges);
        }
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
      
      // Update local first
      await _storeBadgesLocally(badges);
      _badgeCache.remove(id);
      
      // Then update server if online
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _updateServerBadges(badges);
      }

      // Log the operation
      await _logBadgeOperation('delete', id, 'Badge deleted successfully');
    } catch (e) {
      print('Error deleting badge: $e');
      await _logBadgeOperation('delete_error', id, e.toString());
      rethrow;
    }
  }

  void dispose() {
    _syncDebounceTimer?.cancel();
    _syncStatusController.close();
    _badgeUpdateController.close();
  }

  // Add these methods to the BadgeService class

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

  Future<int?> _getLocalRevision() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(BADGE_REVISION_KEY);
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
      String? existingData = prefs.getString(BADGES_CACHE_KEY);
      if (existingData != null) {
        await prefs.setString('${BADGES_CACHE_KEY}_backup', existingData);
      }
      
      String badgesJson = jsonEncode(badges);
      await prefs.setString(BADGES_CACHE_KEY, badgesJson);
      
      await prefs.remove('${BADGES_CACHE_KEY}_backup');
    } catch (e) {
      await _restoreFromBackup();
      print('Error storing badges locally: $e');
    }
  }

  Future<void> _updateServerBadges(List<Map<String, dynamic>> badges) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
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

  Future<void> _storeLocalRevision(int revision) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(BADGE_REVISION_KEY, revision);
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

  Future<int> getNextId() async {
    try {
      // Try to get from Firebase first
      var connectivityResult = await Connectivity().checkConnectivity();
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

  // Add this method for the auth service
  Future<List<Map<String, dynamic>>> getLocalBadges() async {
    return _getBadgesFromLocal();
  }

  // Add this method for the user profile service
  Future<bool> getBadgeById(int id) async {
    final badge = await getBadgeDetails(id);
    return badge != null;
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
}