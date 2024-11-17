import 'dart:async';
import 'dart:convert';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/user_model.dart';
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

  BadgeUnlockService._internal() {
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

  Future<void> unlockBadges(
    List<int> badgeIds, {
    String? questName,
    String? stageName,
    String? difficulty,
    int? stars,
    List<int>? allStageStars,
  }) async {
    try {
      print('\n🎯 BADGE UNLOCK ATTEMPT');
      print('Badge IDs to unlock: $badgeIds');
      
      final quality = await _connectionManager.checkConnectionQuality();
      print('📡 Badge Service Connection: $quality');

      final userProfileService = UserProfileService();
      UserProfile? profile = await userProfileService.fetchUserProfile();
      if (profile == null) return;

      print('📊 Current Badge Array: ${profile.unlockedBadge}');
      List<int> updatedUnlockedBadges = List<int>.from(profile.unlockedBadge);
      
      // Process badges...
      for (var id in badgeIds) {
        if (!await _badgeService.getBadgeById(id)) {
          print('⚠️ Invalid badge ID: $id');
          return;
        }
        updatedUnlockedBadges[id] = 1;
      }

      print('📊 Updated Badge Array: $updatedUnlockedBadges');

      print('🔄 Sending to UserProfileService...');
      await userProfileService.updateProfileWithIntegration(
        'unlockedBadge',
        updatedUnlockedBadges
      );

      if (quality == ConnectionQuality.OFFLINE) {
        print('\n💾 QUEUEING OFFLINE BADGE UNLOCK');
        print('Context Data:');
        print('  Quest: $questName');
        print('  Stage: $stageName');
        print('  Difficulty: $difficulty');
        print('  Stars: $stars');
        print('  Stage Stars: $allStageStars');
        
        await _queueUnlock(PendingBadgeUnlock(
          badgeIds: badgeIds,
          unlockType: 'adventure',
          unlockContext: {
            if (questName != null) 'questName': questName,
            if (stageName != null) 'stageName': stageName,
            if (difficulty != null) 'difficulty': difficulty,
            if (stars != null) 'stars': stars,
            if (allStageStars != null) 'allStageStars': allStageStars,
          },
          timestamp: DateTime.now(),
        ));
      }

      print('✅ Badge unlock process completed\n');
    } catch (e) {
      print('❌ Error in badge unlock process: $e');
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
      print('\n🎮 Adventure Badge Check');
      print('📋 Quest: $questName');
      print('🎯 Stage: $stageName');
      print('⚔️ Difficulty: $difficulty');
      print('⭐ Stars earned: $stars');
      print('📊 All stage stars: $allStageStars');

      // Validate inputs
      if (questName.isEmpty || stageName.isEmpty || difficulty.isEmpty) {
        throw GameSaveDataException('Invalid input parameters');
      }

      // Get quest badge range
      final questRange = questBadgeRanges[questName];
      if (questRange == null) {
        print('⚠️ No badge range found for quest: $questName');
        return;
      }

      int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
      List<int> updatedStageStars = List<int>.from(allStageStars);
      
      // Validate stage number
      if (stageNumber < 0 || stageNumber >= updatedStageStars.length) {
        throw GameSaveDataException('Invalid stage number: $stageNumber');
      }

      // Update stars for current stage
      updatedStageStars[stageNumber] = stars;
      print('🔄 Updated stage stars array: $updatedStageStars');
      print('📍 Current stage number: ${stageNumber + 1}');

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

      print('\n🏅 Badge Calculations:');
      print('Stage badge ID: $stageBadgeId');
      print('Complete badge ID: ${questRange.completeStart + (difficulty == "hard" ? 1 : 0)}');
      print('Full clear badge ID: ${questRange.fullClearStart + (difficulty == "hard" ? 1 : 0)}');

      if (badgesToUnlock.isNotEmpty) {
        print('\n🎯 Unlocking badges:');
        print('Total badges: ${badgesToUnlock.length}');
        print('Badge IDs: $badgesToUnlock');
        await unlockBadges(
          badgesToUnlock,
          questName: questName,
          stageName: stageName,
          difficulty: difficulty,
          stars: stars,
          allStageStars: allStageStars,
        );
      }
    } catch (e) {
      print('❌ Error in checkAdventureBadges: $e');
      rethrow;
    }
  }

 Future<void> checkArcadeBadges({
  required int totalTime,
  required double accuracy,
  required int streak,
  required double averageTimePerQuestion,
}) async {
  try {
    print('\n🎮 Arcade Badge Check');
    print('⏱️ Total time: $totalTime seconds');
    print('🎯 Accuracy: ${accuracy.toStringAsFixed(2)}%');
    print('🔥 Streak: $streak');
    print('⚡ Avg time per question: ${averageTimePerQuestion.toStringAsFixed(2)} seconds');

    List<int> badgesToUnlock = [];
    
    // Add detailed logging for each badge condition
    if (accuracy >= 100) {
      print('✨ Perfect Accuracy achieved! Adding badge 37');
      badgesToUnlock.add(37);
    }
    
    if (totalTime <= 120) {
      print('⚡ Speed Demon achieved! Adding badge 36');
      badgesToUnlock.add(36);
    }
    
    if (averageTimePerQuestion <= 15) {
      print('🚀 Quick Thinker achieved! Adding badge 39');
      badgesToUnlock.add(39);
    }
    
    if (streak >= 15) {
      print('🔥 Streak Master achieved! Adding badge 38');
      badgesToUnlock.add(38);
    }

    if (badgesToUnlock.isNotEmpty) {
      print('\n🎯 Unlocking badges:');
      print('Total badges: ${badgesToUnlock.length}');
      print('Badge IDs: $badgesToUnlock');
    } else {
      print('\n⚠️ No badges to unlock');
    }

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
    }
    await unlockBadges(badgesToUnlock);  // Single unlock call for both online and offline
  } catch (e) {
    print('❌ Error in checkArcadeBadges: $e');
    rethrow;
  }
}

  bool _hasAllStagesCleared(List<int> stageStars) {
    // Check if we have enough stages
    if (stageStars.isEmpty) return false;
    
    // Get adventure stages (excluding arcade stages)
    List<int> adventureStages = stageStars.sublist(0, 7);
    print('📊 Checking stages (excluding arcade): $adventureStages');
    
    // A stage is cleared if it has at least 1 star
    return adventureStages.every((stars) => stars > 0);
  }

  bool _hasAllStagesFullyCleared(List<int> stageStars) {
    // Check if we have enough stages
    if (stageStars.isEmpty) return false;
    
    // Get adventure stages (excluding arcade stages)
    List<int> adventureStages = stageStars.sublist(0, 7);
    print('📊 Checking stages (excluding arcade): $adventureStages');
    
    // A stage is fully cleared if it has 3 stars
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
    print('\n🔄 PROCESSING PENDING BADGE UNLOCKS');
    final pendingUnlocks = await _getPendingUnlocks();
    print('Found ${pendingUnlocks.length} pending badge unlocks');
    
    // Create backup before processing
    await _backupPendingUnlocks(pendingUnlocks);
    
    // Process each unlock with delay and retry logic
    for (var unlock in pendingUnlocks) {
      try {
        print('\n🎯 Processing Badge Unlock:');
        print('Type: ${unlock.unlockType}');
        print('Badges: ${unlock.badgeIds}');
        print('Context: ${unlock.unlockContext}');
        
        // Add delay between unlocks to avoid rate limits
        if (pendingUnlocks.indexOf(unlock) > 0) {
          print('⏳ Waiting 3 seconds before next unlock...');
          await Future.delayed(Duration(seconds: 3));
        }

        int retryCount = 0;
        bool success = false;
        
        while (!success && retryCount < 3) {
          try {
            if (unlock.unlockType == 'adventure') {
              final questName = unlock.unlockContext['questName'] as String?;
              final stageName = unlock.unlockContext['stageName'] as String?;
              final difficulty = unlock.unlockContext['difficulty'] as String?;
              final stars = unlock.unlockContext['stars'] as int?;
              final allStageStars = unlock.unlockContext['allStageStars'] as List<dynamic>?;
              
              if (questName != null && stageName != null && 
                  difficulty != null && stars != null && 
                  allStageStars != null) {
                await checkAdventureBadges(
                  questName: questName,
                  stageName: stageName,
                  difficulty: difficulty,
                  stars: stars,
                  allStageStars: List<int>.from(allStageStars),
                );
                success = true;
              } else {
                print('⚠️ Skipping invalid adventure unlock - missing required data');
                break;
              }
            } else if (unlock.unlockType == 'arcade') {
              final totalTime = unlock.unlockContext['totalTime'] as int?;
              final accuracy = unlock.unlockContext['accuracy'] as double?;
              final streak = unlock.unlockContext['streak'] as int?;
              final avgTime = unlock.unlockContext['averageTimePerQuestion'] as double?;
              
              if (totalTime != null && accuracy != null && 
                  streak != null && avgTime != null) {
                await checkArcadeBadges(
                  totalTime: totalTime,
                  accuracy: accuracy,
                  streak: streak,
                  averageTimePerQuestion: avgTime,
                );
                success = true;
              } else {
                print('⚠️ Skipping invalid arcade unlock - missing required data');
                break;
              }
            }
          } catch (e) {
            retryCount++;
            if (e.toString().contains('Too many updates')) {
              print('⚠️ Rate limit hit, waiting longer...');
              await Future.delayed(Duration(seconds: 5 * retryCount));
            } else {
              rethrow;
            }
          }
        }

        if (!success) {
          print('❌ Failed to process unlock after retries');
        }
      } catch (e) {
        print('❌ Error processing single unlock: $e');
        // Continue with next unlock instead of failing entire process
        continue;
      }
    }
    
    // Only clear unlocks after successful processing
    if (pendingUnlocks.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(PENDING_UNLOCKS_KEY, []);
      print('\n🧹 Cleared processed unlocks');
    }
    
    print('\n✅ Badge sync completed');
  } catch (e) {
    print('❌ Error processing badge unlocks: $e');
    rethrow;
  }
}

// Add backup method
Future<void> _backupPendingUnlocks(List<PendingBadgeUnlock> unlocks) async {
  try {
    print('📦 Creating queue backup');
    final prefs = await SharedPreferences.getInstance();
    final encodedList = unlocks.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('${PENDING_UNLOCKS_KEY}_backup', encodedList);
    print('✅ Queue backup created');
  } catch (e) {
    print('❌ Error creating backup: $e');
  }
}

  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 