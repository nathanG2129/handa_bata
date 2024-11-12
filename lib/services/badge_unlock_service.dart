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

  Future<void> unlockBadges(List<int> badgeIds, {
    String? questName,
    String? stageName,
    String? difficulty,
    int? stars,
    List<int>? allStageStars,
  }) async {
    if (badgeIds.isEmpty) return;
    print('🏅 Attempting to unlock badges: $badgeIds');

    try {
      final quality = await _connectionManager.checkConnectionQuality();
      print('📡 Connection quality: $quality');

      UserProfile? profile = await _authService.getUserProfile();
      if (profile == null) return;

      List<int> updatedUnlockedBadges = List<int>.from(profile.unlockedBadge);
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
        'data': updatedUnlockedBadges,  // This will be serialized as a JSON array
      });

      // Pass as string to UserProfileService
      final userProfileService = UserProfileService();
      await userProfileService.updateProfileWithIntegration(
        'unlockedBadge',
        encodedList  // Pass as string instead of List
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
        print('🌐 Online mode: Updating profile');
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
      final quality = await _connectionManager.checkConnectionQuality();
      
      int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
      List<int> updatedStageStars = List<int>.from(allStageStars);
      if (stageNumber < updatedStageStars.length) {
        updatedStageStars[stageNumber] = stars;
      }

      final questRange = questBadgeRanges[questName];
      if (questRange == null) return;

      List<int> badgesToUnlock = [];
      
      // Stage badge
      int stageBadgeId = questRange.stageStart + (stageNumber * 2) + (difficulty == 'hard' ? 1 : 0);
      if (stars > 0) {
        badgesToUnlock.add(stageBadgeId);
      }
      
      // Complete badge
      if (_hasAllStagesCleared(updatedStageStars)) {
        int completeBadgeId = difficulty == 'hard' 
            ? questRange.completeStart + 1
            : questRange.completeStart;
        badgesToUnlock.add(completeBadgeId);
      }
      
      // Full clear badge
      if (_hasAllStagesFullyCleared(updatedStageStars)) {
        int fullClearBadgeId = difficulty == 'hard'
            ? questRange.fullClearStart + 1
            : questRange.fullClearStart;
        badgesToUnlock.add(fullClearBadgeId);
      }

      if (badgesToUnlock.isNotEmpty) {
        if (quality == ConnectionQuality.OFFLINE) {
          await _queueUnlock(PendingBadgeUnlock(
            badgeIds: badgesToUnlock,
            unlockType: 'adventure',
            unlockContext: {
              'questName': questName,
              'stageName': stageName,
              'difficulty': difficulty,
              'stars': stars,
              'allStageStars': allStageStars,
            },
            timestamp: DateTime.now(),
          ));
        }
        await unlockBadges(badgesToUnlock);
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
      final quality = await _connectionManager.checkConnectionQuality();
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
        if (quality == ConnectionQuality.OFFLINE) {
          await _queueUnlock(PendingBadgeUnlock(
            badgeIds: badgesToUnlock,
            unlockType: 'arcade',
            unlockContext: {
              'totalTime': totalTime,
              'accuracy': accuracy,
              'streak': streak,
              'averageTimePerQuestion': averageTimePerQuestion,
            },
            timestamp: DateTime.now(),
          ));
        }
        await unlockBadges(badgesToUnlock);
      }
    } catch (e) {
      print('Error checking arcade badges: $e');
    }
  }

  bool _hasAllStagesCleared(List<int> stageStars) {
    List<int> normalStages = stageStars.sublist(0, stageStars.length - 1);
    return !normalStages.contains(0);
  }

  bool _hasAllStagesFullyCleared(List<int> stageStars) {
    List<int> normalStages = stageStars.sublist(0, stageStars.length - 1);
    return normalStages.every((stars) => stars == 3);
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
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingUnlocks = prefs.getStringList(PENDING_UNLOCKS_KEY) ?? [];
      
      if (pendingUnlocks.isEmpty) {
        print('✅ No pending unlocks to process');
        return;
      }

      print('🔄 Processing ${pendingUnlocks.length} pending unlocks');
      
      for (String unlockJson in pendingUnlocks) {
        final unlock = PendingBadgeUnlock.fromJson(jsonDecode(unlockJson));
        if (unlock.unlockType == 'adventure') {
          await checkAdventureBadges(
            questName: unlock.unlockContext['questName'],
            stageName: unlock.unlockContext['stageName'],
            difficulty: unlock.unlockContext['difficulty'],
            stars: unlock.unlockContext['stars'],
            allStageStars: List<int>.from(unlock.unlockContext['allStageStars']),
          );
        } else if (unlock.unlockType == 'arcade') {
          await checkArcadeBadges(
            totalTime: unlock.unlockContext['totalTime'],
            accuracy: unlock.unlockContext['accuracy'],
            streak: unlock.unlockContext['streak'],
            averageTimePerQuestion: unlock.unlockContext['averageTimePerQuestion'],
          );
        }
      }

      await prefs.setStringList(PENDING_UNLOCKS_KEY, []);
      print('✅ All pending unlocks processed');

      // Trigger a refresh of badge data
      await BadgeService().fetchBadges(); // Ensure this refreshes the cache

    } catch (e) {
      print('❌ Error processing pending unlocks: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 