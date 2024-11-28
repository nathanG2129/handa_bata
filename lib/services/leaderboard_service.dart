import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_save_data.dart';

class LeaderboardEntry {
  final String nickname;
  final int crntRecord;
  final int avatarId;
  
  const LeaderboardEntry({
    required this.nickname,
    required this.crntRecord,
    required this.avatarId,
  });
  
  Map<String, dynamic> toMap() => {
    'nickname': nickname,
    'crntRecord': crntRecord,
    'avatarId': avatarId,
  };
  
  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
    nickname: map['nickname'] as String,
    crntRecord: map['crntRecord'] as int,
    avatarId: map['avatarId'] as int,
  );
}

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String CACHE_KEY_PREFIX = 'leaderboard_cache_';
  static const Duration CACHE_DURATION = Duration(minutes: 5);
  
  LeaderboardService._internal();

  Future<List<LeaderboardEntry>> getLeaderboard(String categoryId) async {
    try {
      // Check cache first with a shorter duration for leaderboards
      final cachedData = await _getCachedLeaderboard(categoryId);
      if (cachedData != null && cachedData.isNotEmpty) {
        // Try to refresh cache in background if it's getting old
        _refreshCacheIfNeeded(categoryId, cachedData);
        return cachedData;
      }

      // If no cache, fetch from Firestore
      final leaderboardRef = _firestore.collection('Leaderboards').doc(categoryId);
      final snapshot = await leaderboardRef.get();

      if (!snapshot.exists || !snapshot.data()?['entries']?.isNotEmpty) {
        // If no data exists, aggregate from user records
        final entries = await _aggregateAndUpdateLeaderboard(categoryId);
        await _cacheLeaderboard(categoryId, entries);
        return entries;
      }

      // Convert and cache the data
      final entries = (snapshot.data()!['entries'] as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      
      await _cacheLeaderboard(categoryId, entries);
      return entries;

    } catch (e) {
      // On error, try to return cached data even if expired
      final cachedData = await _getCachedLeaderboard(categoryId, ignoreExpiry: true);
      return cachedData ?? [];
    }
  }

  Future<void> _refreshCacheIfNeeded(String categoryId, List<LeaderboardEntry> currentCache) async {
    try {
      // Check if cache is getting old (e.g., more than 2 minutes old)
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$CACHE_KEY_PREFIX$categoryId';
      final cacheData = prefs.getString(cacheKey);
      
      if (cacheData != null) {
        final data = jsonDecode(cacheData);
        final cacheTime = DateTime.parse(data['timestamp']);
        
        if (DateTime.now().difference(cacheTime) > const Duration(minutes: 2)) {
          // Refresh in background
          _firestore
              .collection('Leaderboards')
              .doc(categoryId)
              .get()
              .then((snapshot) async {
                if (snapshot.exists && snapshot.data()?['entries']?.isNotEmpty) {
                  final entries = (snapshot.data()!['entries'] as List)
                      .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
                      .toList();
                  await _cacheLeaderboard(categoryId, entries);
                }
              })
              .catchError((_) {
                // Ignore errors in background refresh
              });
        }
      }
    } catch (e) {
      // Ignore errors in background refresh
    }
  }

  Future<void> _cacheLeaderboard(String categoryId, List<LeaderboardEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'entries': entries.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$CACHE_KEY_PREFIX$categoryId', jsonEncode(cacheData));
  }

  Future<List<LeaderboardEntry>?> _getCachedLeaderboard(
    String categoryId, {
    bool ignoreExpiry = false
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$CACHE_KEY_PREFIX$categoryId');
      
      if (cachedJson == null) return null;

      final cachedData = jsonDecode(cachedJson);
      final timestamp = DateTime.parse(cachedData['timestamp']);

      // Use a shorter cache duration for leaderboards
      if (!ignoreExpiry && 
          DateTime.now().difference(timestamp) > const Duration(minutes: 5)) {
        return null;
      }

      return (cachedData['entries'] as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<List<LeaderboardEntry>> _aggregateAndUpdateLeaderboard(String categoryId) async {
    List<LeaderboardEntry> entries = [];
    
    try {
      // First, get all users who have arcade records
      final QuerySnapshot userSnapshot = await _firestore
          .collection('User')
          .where('hasArcadeRecord', isEqualTo: true)  // Only get users with arcade records
          .get();
      

      // Get all game save data in one batch
      final futures = userSnapshot.docs.map((userDoc) async {
        try {
          // Get game save data and profile in parallel
          final results = await Future.wait([
            userDoc.reference
                .collection('GameSaveData')
                .doc(categoryId)
                .get(),
            userDoc.reference
                .collection('ProfileData')
                .doc(userDoc.id)
                .get(),
          ]);

          final gameSaveDoc = results[0] as DocumentSnapshot;
          final profileDoc = results[1] as DocumentSnapshot;

          if (!gameSaveDoc.exists || !profileDoc.exists) return null;

          final gameSaveData = GameSaveData.fromMap(gameSaveDoc.data() as Map<String, dynamic>);
          final arcadeKey = GameSaveData.getArcadeKey(categoryId);
          final arcadeData = gameSaveData.stageData[arcadeKey];
          
          if (arcadeData is! ArcadeStageData || arcadeData.crntRecord == -1) return null;

          final profileData = profileDoc.data() as Map<String, dynamic>;
          return LeaderboardEntry(
            nickname: profileData['nickname'] as String,
            crntRecord: arcadeData.crntRecord,
            avatarId: profileData['avatarId'] as int,
          );
        } catch (e) {
          return null;
        }
      });

      // Wait for all futures to complete
      final results = await Future.wait(futures);
      entries = results.whereType<LeaderboardEntry>().toList();


      if (entries.isNotEmpty) {
        // Sort entries
        entries.sort((a, b) => a.crntRecord.compareTo(b.crntRecord));

        // Store in Firestore
        await _firestore.collection('Leaderboards').doc(categoryId).set({
          'entries': entries.map((e) => e.toMap()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      return entries;
    } catch (e) {
      return entries;
    }
  }

  Future<void> updateLeaderboard(String categoryId, String userId, int newRecord) async {
    try {
      // First try online update
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _updateLeaderboardOnline(categoryId, userId, newRecord);
      } else {
        // If offline, queue the update
        await _queueLeaderboardUpdate(categoryId, userId, newRecord);
      }
    } catch (e) {
      // If online update fails, queue it
      await _queueLeaderboardUpdate(categoryId, userId, newRecord);
      rethrow;
    }
  }

  Future<void> _updateLeaderboardOnline(String categoryId, String userId, int newRecord) async {
    try {
      // Get current leaderboard first
      final leaderboardRef = _firestore.collection('Leaderboards').doc(categoryId);
      final snapshot = await leaderboardRef.get();
      
      List<LeaderboardEntry> entries = [];
      if (snapshot.exists) {
        final data = snapshot.data()!;
        entries = (data['entries'] as List)
            .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      // Get user's profile
      final profileDoc = await _firestore
          .collection('User')
          .doc(userId)
          .collection('ProfileData')
          .doc(userId)
          .get();

      if (!profileDoc.exists) {
        return;
      }

      // Update or add user's entry
      final profileData = profileDoc.data() as Map<String, dynamic>;
      final newEntry = LeaderboardEntry(
        nickname: profileData['nickname'] as String,
        crntRecord: newRecord,
        avatarId: profileData['avatarId'] as int,
      );
      
      // Remove existing entry for this user if exists
      entries.removeWhere((e) => e.nickname == newEntry.nickname);
      entries.add(newEntry);
      
      // Sort entries by record (ascending for time-based records)
      entries.sort((a, b) => a.crntRecord.compareTo(b.crntRecord));

      // Update Firestore in batch
      final batch = _firestore.batch();
      
      // Update user's hasArcadeRecord flag
      batch.update(
        _firestore.collection('User').doc(userId),
        {'hasArcadeRecord': true}
      );
      
      // Update leaderboard
      batch.set(leaderboardRef, {
        'entries': entries.map((e) => e.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Clear cache to force refresh
      await _clearLeaderboardCache(categoryId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _queueLeaderboardUpdate(String categoryId, String userId, int newRecord) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing queue
      List<Map<String, dynamic>> queue = await _getLeaderboardQueue();
      
      // Add new update to queue
      queue.add({
        'categoryId': categoryId,
        'userId': userId,
        'record': newRecord,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save queue
      await prefs.setString('leaderboard_update_queue', jsonEncode(queue));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getLeaderboardQueue() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? queueJson = prefs.getString('leaderboard_update_queue');
      if (queueJson != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> processLeaderboardQueue() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      List<Map<String, dynamic>> queue = await _getLeaderboardQueue();
      if (queue.isEmpty) return;

      // Process each queued update
      for (var update in queue) {
        try {
          await _updateLeaderboardOnline(
            update['categoryId'],
            update['userId'],
            update['record'],
          );
        } catch (e) {
          // Continue processing other updates even if one fails
          continue;
        }
      }

      // Clear queue after processing
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('leaderboard_update_queue');
    } catch (e) {
      rethrow;
    }
  }

  // Add method to clear cache
  Future<void> _clearLeaderboardCache(String categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$CACHE_KEY_PREFIX$categoryId');
  }

  // Clean up old caches
  Future<void> cleanupOldCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(CACHE_KEY_PREFIX));
    
    for (final key in keys) {
      final cachedJson = prefs.getString(key);
      if (cachedJson == null) continue;

      final cachedData = jsonDecode(cachedJson);
      final timestamp = DateTime.parse(cachedData['timestamp']);

      if (DateTime.now().difference(timestamp) > const Duration(days: 1)) {
        await prefs.remove(key);
      }
    }
  }

  // Add method to update when arcade record changes
  Future<void> updateArcadeRecord(String categoryId, String userId, ArcadeStageData arcadeData) async {
    try {
      
      // Only update if there's a valid record
      if (arcadeData.crntRecord == -1) {
        return;
      }

      await updateLeaderboard(categoryId, userId, arcadeData.crntRecord);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> batchUpdateLeaderboards(Map<String, ArcadeStageData> categoryRecords, String userId) async {
    try {
      
      // Process each category in parallel
      await Future.wait(
        categoryRecords.entries.map((entry) => 
          updateArcadeRecord(entry.key, userId, entry.value)
        )
      );

    } catch (e) {
      rethrow;
    }
  }

  Future<void> queueLeaderboardUpdate(String categoryId, String userId, int newRecord) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing queue
      List<Map<String, dynamic>> queue = await _getLeaderboardQueue();
      
      // Remove any existing updates for this category/user combination
      queue.removeWhere((update) => 
        update['categoryId'] == categoryId && update['userId'] == userId
      );
      
      // Add new update to queue
      queue.add({
        'categoryId': categoryId,
        'userId': userId,
        'record': newRecord,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save queue
      await prefs.setString('leaderboard_update_queue', jsonEncode(queue));

      // Try to process immediately if online
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _updateLeaderboardOnline(categoryId, userId, newRecord);
          // If successful, remove from queue
          queue.removeWhere((update) => 
            update['categoryId'] == categoryId && update['userId'] == userId
          );
          await prefs.setString('leaderboard_update_queue', jsonEncode(queue));
        } catch (e) {
          // Keep in queue if update fails
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add method to update avatar in leaderboard entries
  Future<void> updateAvatarInLeaderboards(String userId, int newAvatarId) async {
    try {
      // First try online update
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _updateAvatarOnline(userId, newAvatarId);
      } else {
        // If offline, queue the update
        await _queueAvatarUpdate(userId, newAvatarId);
      }
    } catch (e) {
      // If online update fails, queue it
      await _queueAvatarUpdate(userId, newAvatarId);
      rethrow;
    }
  }

  Future<void> _updateAvatarOnline(String userId, int newAvatarId) async {
    try {
      // Get user's nickname first
      final profileDoc = await _firestore
          .collection('User')
          .doc(userId)
          .collection('ProfileData')
          .doc(userId)
          .get();

      if (!profileDoc.exists) return;
      final nickname = profileDoc.get('nickname') as String;

      // Get all leaderboards
      final leaderboardsSnapshot = await _firestore
          .collection('Leaderboards')
          .get();

      // Update each leaderboard in a batch
      final batch = _firestore.batch();
      
      for (var doc in leaderboardsSnapshot.docs) {
        final data = doc.data();
        if (data['entries'] == null) continue;

        List<LeaderboardEntry> entries = (data['entries'] as List)
            .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
            .toList();

        // Find and update user's entries
        bool hasUpdated = false;
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].nickname == nickname) {
            entries[i] = LeaderboardEntry(
              nickname: nickname,
              crntRecord: entries[i].crntRecord,
              avatarId: newAvatarId,
            );
            hasUpdated = true;
          }
        }

        if (hasUpdated) {
          batch.update(doc.reference, {
            'entries': entries.map((e) => e.toMap()).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Clear cache for this leaderboard
          await _clearLeaderboardCache(doc.id);
        }
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _queueAvatarUpdate(String userId, int newAvatarId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing queue
      List<Map<String, dynamic>> queue = await _getAvatarUpdateQueue();
      
      // Remove any existing updates for this user
      queue.removeWhere((update) => update['userId'] == userId);
      
      // Add new update
      queue.add({
        'userId': userId,
        'avatarId': newAvatarId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save queue
      await prefs.setString('avatar_update_queue', jsonEncode(queue));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getAvatarUpdateQueue() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? queueJson = prefs.getString('avatar_update_queue');
      if (queueJson != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> processAvatarUpdateQueue() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      List<Map<String, dynamic>> queue = await _getAvatarUpdateQueue();
      if (queue.isEmpty) return;

      // Process each queued update
      for (var update in queue) {
        try {
          await _updateAvatarOnline(
            update['userId'],
            update['avatarId'],
          );
        } catch (e) {
          continue;
        }
      }

      // Clear queue after processing
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('avatar_update_queue');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNicknameInLeaderboards(String userId, String oldNickname, String newNickname) async {
    try {
      // First try online update
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        await _updateNicknameOnline(userId, oldNickname, newNickname);
      } else {
        // If offline, queue the update
        await _queueNicknameUpdate(userId, oldNickname, newNickname);
      }
    } catch (e) {
      // If online update fails, queue it
      await _queueNicknameUpdate(userId, oldNickname, newNickname);
      rethrow;
    }
  }

  Future<void> _updateNicknameOnline(String userId, String oldNickname, String newNickname) async {
    try {
      // Get all leaderboards
      final leaderboardsSnapshot = await _firestore
          .collection('Leaderboards')
          .get();

      // Update each leaderboard in a batch
      final batch = _firestore.batch();
      
      for (var doc in leaderboardsSnapshot.docs) {
        final data = doc.data();
        if (data['entries'] == null) continue;

        List<LeaderboardEntry> entries = (data['entries'] as List)
            .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
            .toList();

        // Find and update user's entries
        bool hasUpdated = false;
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].nickname == oldNickname) {
            entries[i] = LeaderboardEntry(
              nickname: newNickname,
              crntRecord: entries[i].crntRecord,
              avatarId: entries[i].avatarId,
            );
            hasUpdated = true;
          }
        }

        if (hasUpdated) {
          batch.update(doc.reference, {
            'entries': entries.map((e) => e.toMap()).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Clear cache for this leaderboard
          await _clearLeaderboardCache(doc.id);
        }
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _queueNicknameUpdate(String userId, String oldNickname, String newNickname) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing queue
      List<Map<String, dynamic>> queue = await _getNicknameUpdateQueue();
      
      // Remove any existing updates for this user
      queue.removeWhere((update) => update['userId'] == userId);
      
      // Add new update
      queue.add({
        'userId': userId,
        'oldNickname': oldNickname,
        'newNickname': newNickname,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save queue
      await prefs.setString('nickname_update_queue', jsonEncode(queue));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getNicknameUpdateQueue() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? queueJson = prefs.getString('nickname_update_queue');
      if (queueJson != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> processNicknameUpdateQueue() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      List<Map<String, dynamic>> queue = await _getNicknameUpdateQueue();
      if (queue.isEmpty) return;

      // Process each queued update
      for (var update in queue) {
        try {
          await _updateNicknameOnline(
            update['userId'],
            update['oldNickname'],
            update['newNickname'],
          );
        } catch (e) {
          continue;
        }
      }

      // Clear queue after processing
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('nickname_update_queue');
    } catch (e) {
      rethrow;
    }
  }
} 