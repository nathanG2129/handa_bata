import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/services/auth_service.dart';

class QuestBadgeRange {
  final int stageStart;     // First badge ID for normal stages
  final int completeStart;  // Badge ID for completion
  final int fullClearStart; // Badge ID for full clear
  
  const QuestBadgeRange(this.stageStart, this.completeStart, this.fullClearStart);
}

class BadgeUnlockService {
  final AuthService _authService;
  
  // Quest badge ranges
  static const Map<String, QuestBadgeRange> questBadgeRanges = {
    'Quake': QuestBadgeRange(0, 14, 16),
    'Storm': QuestBadgeRange(18, 32, 34),
    'Volcano': QuestBadgeRange(40, 54, 56),
    'Drought': QuestBadgeRange(58, 72, 74),
    'Tsunami': QuestBadgeRange(76, 90, 92),
    'Landslide': QuestBadgeRange(94, 108, 110),
  };

  BadgeUnlockService(this._authService);

  // Helper method to unlock badges
  Future<void> _unlockBadges(List<int> badgeIds) async {
    if (badgeIds.isEmpty) return;

    UserProfile? profile = await _authService.getUserProfile();
    if (profile == null) return;

    List<int> unlockedBadges = List<int>.from(profile.unlockedBadge);
    bool hasNewUnlocks = false;

    for (int badgeId in badgeIds) {
      if (badgeId < unlockedBadges.length && unlockedBadges[badgeId] == 0) {
        unlockedBadges[badgeId] = 1;
        hasNewUnlocks = true;
      }
    }

    if (hasNewUnlocks) {
      int totalUnlocked = unlockedBadges.where((badge) => badge == 1).length;
      await _authService.updateUserProfile('unlockedBadge', unlockedBadges);
      await _authService.updateUserProfile('totalBadgeUnlocked', totalUnlocked);
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
} 