import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/user_profile_service.dart';

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

  // Add UserProfileService
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  AuthService get _authService => AuthService();
  UserProfileService get _userProfileService => UserProfileService();

  void _setSyncState(bool syncing) {
    _isSyncing = syncing;
    _syncStatusController.add(syncing);
  }

  Future<List<Map<String, dynamic>>> fetchBadges({bool isAdmin = false}) async {
    try {
      if (isAdmin) {
        // For admin, always fetch from server
        DocumentSnapshot snapshot = await _badgeDoc.get();
        if (!snapshot.exists) return [];

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> badges = 
            data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
            
        // Update cache after fetching
        for (var badge in badges) {
          _badgeCache[badge['id']] = badge;
        }
        
        return badges;
      }

      // Get badge details from local storage first
      List<Map<String, dynamic>> badges = await _getBadgesFromLocal();
      
      // Get local profile for unlock states
      UserProfile? profile = await _authService.getLocalUserProfile();
      
      // If local storage is empty, try fetching from server
      if (badges.isEmpty) {
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentSnapshot snapshot = await _badgeDoc.get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
            // Store in local
            await _storeBadgesLocally(badges);
          }
        }
      }

      // Update memory cache
      for (var badge in badges) {
        _badgeCache[badge['id']] = badge;
      }

      // Merge with profile unlock states if available
      if (profile != null) {
        badges = _mergeBadgeStates(badges, profile.unlockedBadge);
      }

      return badges;
    } catch (e) {
      print('Error in fetchBadges: $e');
      return _badgeCache.values.toList();
    }
  }

  List<Map<String, dynamic>> _mergeBadgeStates(
    List<Map<String, dynamic>> badges, 
    List<int> unlockedStates
  ) {
    return badges.map((badge) {
      final id = badge['id'] as int;
      return {
        ...badge,
        'unlocked': id < unlockedStates.length ? unlockedStates[id] == 1 : false,
      };
    }).toList();
  }

  void _debouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(SYNC_DEBOUNCE, () {
      _syncWithServer();
    });
  }

  Future<void> _syncWithServer() async {
    if (_isSyncing) {
      print('🔄 Badge sync already in progress, skipping...');
      return;
    }

    try {
      print('🔄 Starting badge sync process');
      _setSyncState(true);

      // Get server badges
      print('📥 Fetching badges from server');
      List<Map<String, dynamic>> serverBadges = await _fetchFromServer();
      
      // Get current profile for unlock states
      print('👤 Fetching user profile for badge states');
      // Use AuthService for local profile first
      UserProfile? profile = await _authService.getLocalUserProfile();

      if (profile != null) {
        print('🔄 Merging server badges with profile unlock states');
        // Merge server badges with profile unlock states
        serverBadges = _mergeBadgeStates(serverBadges, profile.unlockedBadge);
        
        print('💾 Updating local storage with merged badge data');
        // Update local storage with merged data
        await _storeBadgesLocally(serverBadges);
        
        print('🔄 Updating memory cache');
        // Update memory cache
        for (var badge in serverBadges) {
          _badgeCache[badge['id']] = badge;
        }

        print('📢 Notifying listeners of badge updates');
        // Notify listeners
        _badgeUpdateController.add(serverBadges);
      } else {
        print('⚠️ No user profile found for badge sync');
      }
    } catch (e) {
      print('❌ Error in badge sync: $e');
      await _logBadgeOperation('sync_error', -1, e.toString());
    } finally {
      print('🏁 Badge sync process completed');
      _setSyncState(false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFromServer() async {
    DocumentSnapshot snapshot = await _badgeDoc.get().timeout(SYNC_TIMEOUT);
    if (!snapshot.exists) return [];

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return data['badges'] != null 
        ? List<Map<String, dynamic>>.from(data['badges']) 
        : [];
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
      // Get current badges
      DocumentSnapshot snapshot = await _badgeDoc.get();
      List<Map<String, dynamic>> badges = [];
      
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        badges = data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];
      }

      // Generate new ID
      int newId = 1;
      if (badges.isNotEmpty) {
        newId = badges.map((b) => b['id'] as int).reduce(max) + 1;
      }

      // Add new badge with ID
      badge['id'] = newId;
      badges.add(badge);

      // Update Firestore
      await _badgeDoc.set({
        'badges': badges,
        'revision': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Update cache
      _badgeCache[newId] = badge;
      
      // Log the operation
      await _logBadgeOperation('add', newId, 'Added new badge: ${badge['title']}');

    } catch (e) {
      print('Error adding badge: $e');
      await _logBadgeOperation('add_error', -1, e.toString());
      throw Exception('Failed to add badge');
    }
  }

  Future<void> updateBadge(int id, Map<String, dynamic> updatedBadge) async {
    try {
      // Get current badges
      DocumentSnapshot snapshot = await _badgeDoc.get();
      if (!snapshot.exists) throw Exception('Badge document not found');

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> badges = 
          data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];

      // Find and update badge
      int index = badges.indexWhere((badge) => badge['id'] == id);
      if (index == -1) throw Exception('Badge not found');

      // Store old data for logging
      Map<String, dynamic> oldBadge = Map<String, dynamic>.from(badges[index]);
      
      // Update badge
      badges[index] = updatedBadge;

      // Use _updateServerBadges for the update
      await _updateServerBadges(badges);

      // Update cache
      _badgeCache[id] = updatedBadge;

      // Log the operation with details of what changed
      String changeDetails = 'Changed: ${_getChangedFields(oldBadge, updatedBadge)}';
      await _logBadgeOperation('update', id, changeDetails);

    } catch (e) {
      print('Error updating badge: $e');
      await _logBadgeOperation('update_error', id, e.toString());
      throw Exception('Failed to update badge');
    }
  }

  Future<void> deleteBadge(int id) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(_badgeDoc);
        if (!snapshot.exists) throw Exception('Badge document not found');

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> badges = 
            data['badges'] != null ? List<Map<String, dynamic>>.from(data['badges']) : [];

        // Store badge info for logging before removal
        Map<String, dynamic>? deletedBadge = 
            badges.firstWhere((badge) => badge['id'] == id, orElse: () => {});

        // Remove badge
        badges.removeWhere((badge) => badge['id'] == id);

        // Update document
        transaction.update(_badgeDoc, {
          'badges': badges,
          'revision': FieldValue.increment(1),
        });

        // Remove from cache
        _badgeCache.remove(id);

        // Log the deletion
        await _logBadgeOperation('delete', id, 
            'Deleted badge: ${deletedBadge['title'] ?? 'Unknown'}');
      });

    } catch (e) {
      print('Error deleting badge: $e');
      await _logBadgeOperation('delete_error', id, e.toString());
      throw Exception('Failed to delete badge');
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
      String badgesJson = jsonEncode(badges);
      await prefs.setString(BADGES_CACHE_KEY, badgesJson);
      
      // Update memory cache
      for (var badge in badges) {
        _badgeCache[badge['id']] = badge;
      }

      // Notify listeners of updates
      _badgeUpdateController.add(badges);
    } catch (e) {
      print('Error storing badges locally: $e');
      await _restoreFromBackup();
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

  // Helper method to compare old and new badge data
  String _getChangedFields(Map<String, dynamic> oldBadge, Map<String, dynamic> newBadge) {
    List<String> changes = [];
    
    newBadge.forEach((key, value) {
      if (oldBadge[key] != value) {
        changes.add('$key: ${oldBadge[key]} → $value');
      }
    });
    
    return changes.join(', ');
  }
}