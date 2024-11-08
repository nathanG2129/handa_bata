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
    int attempts = 0;
    while (attempts < MAX_RETRY_ATTEMPTS) {
      try {
        if (badgeIds.isEmpty) return;
        print('🏅 Attempting to unlock badges: $badgeIds');

        UserProfile? profile = await _authService.getUserProfile();
        if (profile == null) return;

        List<int> unlockedBadges = List<int>.from(profile.unlockedBadge);
        bool hasNewUnlocks = false;

        for (int badgeId in badgeIds) {
          if (badgeId < unlockedBadges.length && unlockedBadges[badgeId] == 0) {
            print('🏅 New badge unlocked: $badgeId');
            unlockedBadges[badgeId] = 1;
            hasNewUnlocks = true;
            _pendingBadgeNotifications.add(badgeId);
            print('🏅 Current pending notifications queue: ${_pendingBadgeNotifications.toList()}');
          }
        }

        if (hasNewUnlocks) {
          int totalUnlocked = unlockedBadges.where((badge) => badge == 1).length;
          print('🏅 Updating user profile with new unlocks. Total unlocked: $totalUnlocked');
          await _authService.updateUserProfile('unlockedBadge', unlockedBadges);
          await _authService.updateUserProfile('totalBadgeUnlocked', totalUnlocked);
        }
        return;
      } catch (e) {
        attempts++;
        if (attempts == MAX_RETRY_ATTEMPTS) {
          print('Failed to unlock badges after $MAX_RETRY_ATTEMPTS attempts');
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
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
    final questRange = questBadgeRanges[questName];
    if (questRange == null) return;

    List<int> newBadges = [];
    
    // Extract stage number from stageName (e.g., "Stage 1" -> 1)
    int stageNumber = int.parse(stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
    
    // 1. Stage badge (any stars)
    int stageBadgeId = questRange.stageStart + (stageNumber * 2) + (difficulty == 'hard' ? 1 : 0);
    if (stars > 0) {
      newBadges.add(stageBadgeId);
    }
    
    // 2. Complete badge (all stages with stars)
    if (_hasAllStagesCleared(allStageStars)) {
      int completeBadgeId = difficulty == 'hard' 
          ? questRange.completeStart + 1
          : questRange.completeStart;
      newBadges.add(completeBadgeId);
    }
    
    // 3. Full clear badge (all stages with 3 stars)
    if (_hasAllStagesFullyCleared(allStageStars)) {
      int fullClearBadgeId = difficulty == 'hard'
          ? questRange.fullClearStart + 1
          : questRange.fullClearStart;
      newBadges.add(fullClearBadgeId);
    }
    
    await _unlockBadges(newBadges);
  }

  // Check Arcade Mode badges
  Future<void> checkArcadeBadges({
    required int totalTime,
    required double accuracy,
    required int streak,
    required double averageTimePerQuestion,
  }) async {
    List<int> newBadges = [];
    
    // Speed Demon - Complete under 2 minutes
    if (totalTime <= 120) newBadges.add(36);
    
    // Perfect Accuracy - 100% accuracy
    if (accuracy >= 100) newBadges.add(37);
    
    // Streak Master - 15+ streak
    if (streak >= 15) newBadges.add(38);
    
    // Quick Thinker - Average time per question under 15 seconds
    if (averageTimePerQuestion <= 15) newBadges.add(39);
    
    await _unlockBadges(newBadges);
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