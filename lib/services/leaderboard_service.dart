import 'package:cloud_firestore/cloud_firestore.dart';
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
      
      // Check cache first
      final cachedData = await _getCachedLeaderboard(categoryId);
      if (cachedData != null && cachedData.isNotEmpty) {
        return cachedData;
      }

      // If no cache or empty cache, fetch from Firestore
      final leaderboardData = await _fetchLeaderboardFromFirestore(categoryId);
      
      // Only cache if we have data
      if (leaderboardData.isNotEmpty) {
        await _cacheLeaderboard(categoryId, leaderboardData);
      }
      
      return leaderboardData;
    } catch (e) {
      // Return cached data if available, even if expired
      final cachedData = await _getCachedLeaderboard(categoryId, ignoreExpiry: true);
      if (cachedData != null) {
        return cachedData;
      }
      return []; // Return empty list instead of throwing
    }
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboardFromFirestore(String categoryId) async {
    
    try {
      final leaderboardRef = _firestore.collection('Leaderboards').doc(categoryId);
      final snapshot = await leaderboardRef.get();


      // Check both existence and data validity
      final data = snapshot.data();
      final hasValidEntries = data != null && 
                            data['entries'] != null && 
                            (data['entries'] as List).isNotEmpty;

      if (!snapshot.exists || !hasValidEntries) {
        return _aggregateAndUpdateLeaderboard(categoryId);
      }

      final entries = (data['entries'] as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
      
      return entries;
    } catch (e) {
      // Try aggregating as fallback
      return _aggregateAndUpdateLeaderboard(categoryId);
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

  Future<void> _cacheLeaderboard(String categoryId, List<LeaderboardEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'entries': entries.map((e) => e.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$CACHE_KEY_PREFIX$categoryId', jsonEncode(cacheData));
  }

  Future<List<LeaderboardEntry>?> _getCachedLeaderboard(String categoryId, {bool ignoreExpiry = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('$CACHE_KEY_PREFIX$categoryId');
    
    if (cachedJson == null) {
      return null;
    }

    final cachedData = jsonDecode(cachedJson);
    final timestamp = DateTime.parse(cachedData['timestamp']);

    if (!ignoreExpiry && DateTime.now().difference(timestamp) > CACHE_DURATION) {
      return null;
    }

    final entries = (cachedData['entries'] as List)
        .map((e) => LeaderboardEntry.fromMap(e))
        .toList();
    return entries;
  }

  Future<void> updateLeaderboard(String categoryId, String userId, int newRecord) async {
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
      final nickname = (profileDoc.data() as Map<String, dynamic>)['nickname'] as String;
      final newEntry = LeaderboardEntry(nickname: nickname, crntRecord: newRecord, avatarId: (profileDoc.data() as Map<String, dynamic>)['avatarId'] as int);
      
      // Remove existing entry for this user if exists
      entries.removeWhere((e) => e.nickname == nickname);
      entries.add(newEntry);
      
      // Sort entries
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$CACHE_KEY_PREFIX$categoryId');
    } catch (e) {
      rethrow;
    }
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
} 