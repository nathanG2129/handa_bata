import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'dart:collection';

class QuestBadgeRange {
  final int stageStart;     // First badge ID for normal stages
  final int completeStart;  // Badge ID for completion
  final int fullClearStart; // Badge ID for full clear
  
  const QuestBadgeRange(this.stageStart, this.completeStart, this.fullClearStart);
}

class BadgeUnlockService {
  final AuthService _authService;
  static final Queue<int> _pendingBadgeNotifications = Queue<int>();
  static bool _isShowingNotification = false;
  
  // Quest badge ranges
  static const Map<String, QuestBadgeRange> questBadgeRanges = {
    'Quake Quest': QuestBadgeRange(0, 14, 16),
    'Storm Quest': QuestBadgeRange(18, 32, 34),
    'Volcano Quest': QuestBadgeRange(40, 54, 56),
    'Drought Quest': QuestBadgeRange(58, 72, 74),
    'Tsunami Quest': QuestBadgeRange(76, 90, 92),
    'Flood Quest': QuestBadgeRange(94, 108, 110),
  };

  static const int MAX_RETRY_ATTEMPTS = 3;

  BadgeUnlockService(this._authService);

  // Helper method to unlock badges
  Future<void> _unlockBadges(List<int> badgeIds) async {
    try {
      print('🎯 Attempting to unlock badges: $badgeIds');
      UserProfile? profile = await _authService.getUserProfile();
      if (profile == null) {
        print('❌ No user profile found');
        return;
      }

      print('📊 Current unlocked badges array: ${profile.unlockedBadge}');
      List<int> unlockedBadge = List<int>.from(profile.unlockedBadge);
      bool needsUpdate = false;

      // Unlock new badges
      for (int badgeId in badgeIds) {
        if (badgeId < unlockedBadge.length && unlockedBadge[badgeId] == 0) {
          print('🔓 Unlocking badge ID: $badgeId');
          unlockedBadge[badgeId] = 1;
          needsUpdate = true;
          _pendingBadgeNotifications.add(badgeId);
        }
      }

      if (needsUpdate) {
        print('💾 Updated unlocked badges array: $unlockedBadge');
        int totalUnlocked = unlockedBadge.where((badge) => badge == 1).length;
        print('📈 Total unlocked badges: $totalUnlocked');
        
        // Create updated profile
        UserProfile updatedProfile = profile.copyWith(
          unlockedBadge: unlockedBadge,
          totalBadgeUnlocked: totalUnlocked
        );

        // Save to local storage first
        await _authService.saveUserProfileLocally(updatedProfile);
        print('💾 Saved to local storage');

        // Then update Firestore
        await _authService.updateUserProfile('unlockedBadge', unlockedBadge);
        await _authService.updateUserProfile('totalBadgeUnlocked', totalUnlocked);
        print('🌐 Updated Firestore');
      }
    } catch (e) {
      print('❌ Error unlocking badges: $e');
    }
  }

  // Check Adventure Mode badges
  Future<void> checkAdventureBadges({
    required String questName,
    required String stageName,
    required String difficulty,
    required int stars,
    required List<int> allStageStars,
  }) async {
    try {
      UserProfile? profile = await _authService.getUserProfile();
      if (profile == null) return;

      final questRange = questBadgeRanges[questName];
      if (questRange == null) return;

      List<int> badgesToUnlock = [];
      
      // Extract stage number from stageName (e.g., "Stage 1" -> 1)
      int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
      
      // 1. Stage badge (any stars)
      int stageBadgeId = questRange.stageStart + (stageNumber * 2) + (difficulty == 'hard' ? 1 : 0);
      if (stars > 0) {
        badgesToUnlock.add(stageBadgeId);
      }
      
      // 2. Complete badge (all stages with stars)
      if (_hasAllStagesCleared(allStageStars)) {
        int completeBadgeId = difficulty == 'hard' 
            ? questRange.completeStart + 1
            : questRange.completeStart;
        badgesToUnlock.add(completeBadgeId);
      }
      
      // 3. Full clear badge (all stages with 3 stars)
      if (_hasAllStagesFullyCleared(allStageStars)) {
        int fullClearBadgeId = difficulty == 'hard'
            ? questRange.fullClearStart + 1
            : questRange.fullClearStart;
        badgesToUnlock.add(fullClearBadgeId);
      }

      // Use the helper method to unlock badges
      if (badgesToUnlock.isNotEmpty) {
        await _unlockBadges(badgesToUnlock);
      }
    } catch (e) {
      print('Error checking adventure badges: $e');
    }
  }

  // Check Arcade Mode badges
  Future<void> checkArcadeBadges({
    required int totalTime,
    required double accuracy,
    required int streak,
    required double averageTimePerQuestion,
  }) async {
    try {
      List<int> badgesToUnlock = [];

      // Speed Demon - Complete under 2 minutes
      if (totalTime <= 120) {
        badgesToUnlock.add(36);
      }
      
      // Perfect Accuracy - 100% accuracy
      if (accuracy >= 100) {
        badgesToUnlock.add(37);
      }
      
      // Streak Master - 15+ streak
      if (streak >= 15) {
        badgesToUnlock.add(38);
      }
      
      // Quick Thinker - Average time per question under 15 seconds
      if (averageTimePerQuestion <= 15) {
        badgesToUnlock.add(39);
      }

      // Use the helper method to unlock badges
      if (badgesToUnlock.isNotEmpty) {
        await _unlockBadges(badgesToUnlock);
      }
    } catch (e) {
      print('Error checking arcade badges: $e');
    }
  }

  bool _hasAllStagesCleared(List<int> stageStars) {
    return !stageStars.contains(0);
  }

  bool _hasAllStagesFullyCleared(List<int> stageStars) {
    return stageStars.every((stars) => stars == 3);
  }

  // Add this method to get pending notifications
  static Queue<int> get pendingNotifications => _pendingBadgeNotifications;

  // Add this method to check notification status
  static bool get isShowingNotification => _isShowingNotification;

  // Add this method to set notification status
  static set isShowingNotification(bool value) {
    _isShowingNotification = value;
  }
} 