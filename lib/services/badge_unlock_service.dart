import 'dart:async';
import 'dart:convert';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:handabatamae/models/pending_badge_unlock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QuestBadgeRange {
  final int stageStart;     // First badge ID for normal stages
  final int completeStart;  // Badge ID for completion
  final int fullClearStart; // Badge ID for full clear
  
  const QuestBadgeRange(this.stageStart, this.completeStart, this.fullClearStart);
}

enum UnlockPriority {
  ACHIEVEMENT,     // Important achievements (100% completion)
  QUEST_COMPLETE,  // Quest completion badges
  MILESTONE,       // Progress milestones
  REGULAR         // Regular gameplay unlocks
}

class BadgeUnlockService {
  // Singleton pattern
  static final BadgeUnlockService _instance = BadgeUnlockService._internal();
  factory BadgeUnlockService() => _instance;

  final AuthService _authService;
  final ConnectionManager _connectionManager = ConnectionManager();
  final BadgeService _badgeService = BadgeService();
  StreamSubscription? _connectivitySubscription;

  static const Map<String, QuestBadgeRange> questBadgeRanges = {
    'Quake Quest': QuestBadgeRange(0, 14, 16),
    'Storm Quest': QuestBadgeRange(18, 32, 34),
    'Volcano Quest': QuestBadgeRange(40, 54, 56),
    'Drought Quest': QuestBadgeRange(58, 72, 74),
    'Tsunami Quest': QuestBadgeRange(76, 90, 92),
    'Flood Quest': QuestBadgeRange(94, 108, 110),
  };

  static const String PENDING_UNLOCKS_KEY = 'pending_badge_unlocks';

  BadgeUnlockService._internal() : _authService = AuthService() {
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _processPendingUnlocks();
      }
    });
  }

  Future<void> _storePendingUnlock(List<int> badgeIds, String unlockType, Map<String, dynamic> context) async {
  try {
    print('💾 Storing pending unlock');
    print('🎯 Badges: $badgeIds');
    print('📝 Type: $unlockType');
    print('📊 Context: $context');
    
    final unlock = PendingBadgeUnlock(
      badgeIds: badgeIds,
      unlockType: unlockType,
      unlockContext: context,
      timestamp: DateTime.now(),
    );

    await _savePendingUnlock(unlock);
    print('✅ Pending unlock stored successfully');
  } catch (e) {
    print('❌ Error storing pending unlock: $e');
  }
}

  Future<void> _savePendingUnlock(PendingBadgeUnlock unlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUnlocks = await _getPendingUnlocks();
      pendingUnlocks.add(unlock);
      
      // Save the updated list
      final encodedList = pendingUnlocks.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList(PENDING_UNLOCKS_KEY, encodedList);
      
      print('✅ Pending unlock saved successfully');
    } catch (e) {
      print('❌ Error saving pending unlock: $e');
    }
  }

  Future<List<PendingBadgeUnlock>> _getPendingUnlocks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
    
    return encoded.map((json) => 
      PendingBadgeUnlock.fromJson(jsonDecode(json))
    ).toList();
  } catch (e) {
    print('❌ Error getting pending unlocks: $e');
    return [];
  }
}

  Future<void> unlockBadges(List<int> badgeIds, {
    String? questName,
    String? stageName,
    String? difficulty,
    int? stars,
    List<int>? allStageStars,
  }) async {
    try {
      final quality = await _connectionManager.checkConnectionQuality();
      print('📡 Connection quality: $quality');

      UserProfile? profile = await _authService.getUserProfile();
      if (profile == null) return;

      List<int> updatedUnlockedBadges = List<int>.from(profile.unlockedBadge);
      
      // Process any pending offline unlocks first
      if (quality != ConnectionQuality.OFFLINE) {
        final prefs = await SharedPreferences.getInstance();
        List<String> pendingUnlocks = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
        
        // Merge all pending unlocks with current badges
        for (String unlockJson in pendingUnlocks) {
          final unlock = PendingBadgeUnlock.fromJson(jsonDecode(unlockJson));
          for (var id in unlock.badgeIds) {
            if (id < updatedUnlockedBadges.length) {
              updatedUnlockedBadges[id] = 1;
            }
          }
        }
        
        // Clear pending unlocks only after successful merge
        if (quality == ConnectionQuality.GOOD || quality == ConnectionQuality.EXCELLENT) {
          await prefs.setStringList(PENDING_UNLOCKS_KEY, []);
        }
      }

      // Add new badges to unlock
      int maxBadgeId = badgeIds.reduce((max, id) => id > max ? id : max);
      if (maxBadgeId >= updatedUnlockedBadges.length) {
        updatedUnlockedBadges.addAll(
          List<int>.filled(maxBadgeId - updatedUnlockedBadges.length + 1, 0)
        );
      }
      
      for (var id in badgeIds) {
        if (!await _badgeService.getBadgeById(id)) {
          print('⚠️ Invalid badge ID: $id');
          return;
        }
        updatedUnlockedBadges[id] = 1;
      }

      // Convert to string representation before passing
      final String encodedList = jsonEncode({
        'type': 'badge_array',
        'data': updatedUnlockedBadges,
      });

      // Update profile with merged badges
      final userProfileService = UserProfileService();
      await userProfileService.updateProfileWithIntegration(
        'unlockedBadge',
        encodedList
      );

      if (quality == ConnectionQuality.OFFLINE) {
        print('📱 Offline mode: Badge unlocked and saved locally');
        await _queueUnlock(PendingBadgeUnlock(
          badgeIds: badgeIds,
          unlockType: 'adventure',
          unlockContext: {
            'questName': questName,
            'stageName': stageName,
            'difficulty': difficulty,
            'stars': stars,
            'allStageStars': allStageStars ?? List<int>.filled(16, 0),
          },
          timestamp: DateTime.now(),
        ));
      } else {
        print('🌐 Online mode: Updating profile with merged badges');
        await _authService.updateUserProfile('unlockedBadge', updatedUnlockedBadges);
      }
    } catch (e) {
      print('❌ Error unlocking badges: $e');
    }
  }

  Future<void> checkAdventureBadges({
    required String questName,
    required String stageName,
    required String difficulty,
    required int stars,
    required List<int> allStageStars,
  }) async {
    try {
      print('🎮 Checking adventure badges for $questName, $stageName');
      print('⭐ Current stage stars: $stars');
      print('📊 All stage stars: $allStageStars');
      
      int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
      List<int> updatedStageStars = List<int>.from(allStageStars);
      if (stageNumber < updatedStageStars.length) {
        updatedStageStars[stageNumber] = stars;
      }

      print('🔄 Updated stage stars array: $updatedStageStars');
      print('📍 Current stage number: ${stageNumber + 1}');

      final questRange = questBadgeRanges[questName];
      if (questRange == null) return;

      List<int> badgesToUnlock = [];
      
      // Stage badge
      int stageBadgeId = questRange.stageStart + (stageNumber * 2) + (difficulty == 'hard' ? 1 : 0);
      if (stars > 0) {
        print('🏅 Adding stage badge: $stageBadgeId (${difficulty == 'hard' ? 'Hard' : 'Normal'} mode)');
        badgesToUnlock.add(stageBadgeId);
      }
      
      // Complete badge check
      bool isCompleted = _hasAllStagesCleared(updatedStageStars);
      print('🔍 Checking quest completion...');
      print('📊 Normal stages: ${updatedStageStars.sublist(0, updatedStageStars.length)}');
      print('✅ All stages cleared? $isCompleted');
      
      if (isCompleted) {
        int completeBadgeId = difficulty == 'hard' 
            ? questRange.completeStart + 1
            : questRange.completeStart;
        print('🎖️ Adding completion badge: $completeBadgeId');
        badgesToUnlock.add(completeBadgeId);
      }
      
      // Full clear badge check
      bool isFullyCleared = _hasAllStagesFullyCleared(updatedStageStars);
      print('🔍 Checking quest full clear...');
      print('⭐ Required: All stages must have 3 stars');
      print('✨ All stages fully cleared? $isFullyCleared');
      
      if (isFullyCleared) {
        int fullClearBadgeId = difficulty == 'hard'
            ? questRange.fullClearStart + 1
            : questRange.fullClearStart;
        print('👑 Adding full clear badge: $fullClearBadgeId');
        badgesToUnlock.add(fullClearBadgeId);
      }

      if (badgesToUnlock.isNotEmpty) {
        print('🎯 Badges to unlock: $badgesToUnlock');
        final quality = await _connectionManager.checkConnectionQuality();
        print('📡 Connection quality: $quality');

        if (quality == ConnectionQuality.OFFLINE) {
          print('💾 Unlock queued for later sync');
          await _storePendingUnlock(
            badgesToUnlock,
            'adventure',
            {
              'questName': questName,
              'stageName': stageName,
              'difficulty': difficulty,
              'stars': stars,
              'allStageStars': allStageStars,
            },
          );
        await unlockBadges(badgesToUnlock);  // Actually unlock the badges
        } else {
          print('🌐 Online mode: Unlocking badges directly');
          await unlockBadges(badgesToUnlock);  // Actually unlock the badges
        }
      }
    } catch (e) {
      print('❌ Error checking adventure badges: $e');
    }
  }

 Future<void> checkArcadeBadges({
  required int totalTime,
  required double accuracy,
  required int streak,
  required double averageTimePerQuestion,
}) async {
  try {
    List<int> badgesToUnlock = [];

    if (accuracy >= 100) {
      badgesToUnlock.add(37);  // Perfect Accuracy
    }
    
    if (totalTime <= 120) {
      badgesToUnlock.add(36);  // Speed Demon
    }
    
    if (averageTimePerQuestion <= 15) {
      badgesToUnlock.add(39);  // Quick Thinker
    }
    
    if (streak >= 15) {
      badgesToUnlock.add(38);  // Streak Master
    }

    if (badgesToUnlock.isNotEmpty) {
      final quality = await _connectionManager.checkConnectionQuality();
      print('📡 Connection quality: $quality');

      if (quality == ConnectionQuality.OFFLINE) {
        print('💾 Unlock queued for later sync');
        await _storePendingUnlock(
          badgesToUnlock,
          'arcade',
          {
            'totalTime': totalTime,
            'accuracy': accuracy,
            'streak': streak,
            'averageTimePerQuestion': averageTimePerQuestion,
          },
        );
      await unlockBadges(badgesToUnlock);  // Actually unlock the badges
      } else {
        await unlockBadges(badgesToUnlock);
      }
    }
  } catch (e) {
    print('❌ Error checking arcade badges: $e');
  }
}

  bool _hasAllStagesCleared(List<int> stageStars) {
    // We need exactly 7 adventure stages (0-6) to be cleared
    print('🔍 Checking adventure stages for completion: $stageStars');
    if (stageStars.length < 7) return false;
    
    // Get first 7 stages (0-6), excluding arcade
    List<int> adventureStages = stageStars.sublist(0, 7);
    print('📊 Checking stages (excluding arcade): $adventureStages');
    return !adventureStages.contains(0);
  }

  bool _hasAllStagesFullyCleared(List<int> stageStars) {
    // We need exactly 7 adventure stages (0-6) to be 3-starred
    print('🔍 Checking adventure stages for full clear: $stageStars');
    if (stageStars.length < 7) return false;
    
    // Get first 7 stages (0-6), excluding arcade
    List<int> adventureStages = stageStars.sublist(0, 7);
    print('📊 Checking stages (excluding arcade): $adventureStages');
    return adventureStages.every((stars) => stars == 3);
  }

  Future<void> _queueUnlock(PendingBadgeUnlock unlock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingUnlocks = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
      pendingUnlocks.add(jsonEncode(unlock.toJson()));
      await prefs.setStringList(PENDING_UNLOCKS_KEY, pendingUnlocks);
      print('💾 Unlock queued for later sync');
    } catch (e) {
      print('❌ Error queueing unlock: $e');
    }
  }

Future<void> _processPendingUnlocks() async {
  try {
    final pendingUnlocks = await _getPendingUnlocks();
    print('🔄 Processing ${pendingUnlocks.length} pending unlocks');
    
    for (var unlock in pendingUnlocks) {
      print('🎯 Processing unlock: ${unlock.unlockType}');
      print('📊 Context: ${unlock.unlockContext}');
      
      if (unlock.unlockType == 'adventure') {
        await checkAdventureBadges(
          questName: unlock.unlockContext['questName'] as String,
          stageName: unlock.unlockContext['stageName'] as String,
          difficulty: unlock.unlockContext['difficulty'] as String,
          stars: unlock.unlockContext['stars'] as int,
          allStageStars: List<int>.from(unlock.unlockContext['allStageStars']),
        );
      } else if (unlock.unlockType == 'arcade') {
        await checkArcadeBadges(
          totalTime: unlock.unlockContext['totalTime'] as int,
          accuracy: unlock.unlockContext['accuracy'] as double,
          streak: unlock.unlockContext['streak'] as int,
          averageTimePerQuestion: unlock.unlockContext['averageTimePerQuestion'] as double,
        );
      }
    }
    
    // Clear processed unlocks
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(PENDING_UNLOCKS_KEY, []);
    print('✅ All pending unlocks processed');
  } catch (e) {
    print('❌ Error processing pending unlocks: $e');
    rethrow;
  }
}

  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 