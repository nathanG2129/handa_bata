/// Exception class for GameSaveData related errors
class GameSaveDataException implements Exception {
  final String message;
  GameSaveDataException(this.message);
  
  @override
  String toString() => 'GameSaveDataException: $message';
}

/// Base class for stage data with type-safe access and backward compatibility
/// 
/// This abstract class provides the foundation for both arcade and adventure
/// stage data types while maintaining compatibility with existing code through
/// operator overloading.
abstract class StageDataEntry {
  final int maxScore;
  
  const StageDataEntry({required this.maxScore});
  
  Map<String, dynamic> toMap();
  
  // Add operator overloads for backward compatibility
  dynamic operator [](String key);
  operator []=(String key, dynamic value);
}

/// Stores progress data for adventure mode stages including normal and hard scores
/// 
/// Manages:
/// - Maximum possible score
/// - Normal mode score
/// - Hard mode score
class AdventureStageData extends StageDataEntry {
  int scoreNormal;
  int scoreHard;
  
  AdventureStageData({
    required super.maxScore,
    this.scoreNormal = 0,
    this.scoreHard = 0,
  });

  @override
  Map<String, dynamic> toMap() => {
    'maxScore': maxScore,
    'scoreNormal': scoreNormal,
    'scoreHard': scoreHard,
  };

  // Add operator overloads for backward compatibility
  @override
  dynamic operator [](String key) {
    switch (key) {
      case 'maxScore': return maxScore;
      case 'scoreNormal': return scoreNormal;
      case 'scoreHard': return scoreHard;
      default: return null;
    }
  }

  @override
  operator []=(String key, dynamic value) {
    switch (key) {
      case 'scoreNormal': scoreNormal = value as int; break;
      case 'scoreHard': scoreHard = value as int; break;
    }
  }

  factory AdventureStageData.fromMap(Map<String, dynamic> map) {
    return AdventureStageData(
      maxScore: map['maxScore'] ?? 0,
      scoreNormal: map['scoreNormal'] ?? 0,
      scoreHard: map['scoreHard'] ?? 0,
    );
  }
}

/// Stores progress data for arcade mode stages including best and current records
/// 
/// Manages:
/// - Best time record (-1 indicates no record)
/// - Current season record
class ArcadeStageData extends StageDataEntry {
  int bestRecord;
  int crntRecord;
  
  ArcadeStageData({
    required super.maxScore,
    this.bestRecord = -1,
    this.crntRecord = -1,
  });

  @override
  Map<String, dynamic> toMap() => {
    'maxScore': maxScore,
    'bestRecord': bestRecord,
    'crntRecord': crntRecord,
  };

  // Add operator overloads for backward compatibility
  @override
  dynamic operator [](String key) {
    switch (key) {
      case 'maxScore': return maxScore;
      case 'bestRecord': return bestRecord;
      case 'crntRecord': return crntRecord;
      default: return null;
    }
  }

  @override
  operator []=(String key, dynamic value) {
    switch (key) {
      case 'bestRecord': bestRecord = value as int; break;
      case 'crntRecord': crntRecord = value as int; break;
    }
  }

  factory ArcadeStageData.fromMap(Map<String, dynamic> map) {
    return ArcadeStageData(
      maxScore: map['maxScore'] ?? 0,
      bestRecord: map['bestRecord'] ?? -1,
      crntRecord: map['crntRecord'] ?? -1,
    );
  }

  // Add helper method for updating records
  void updateRecord(int newRecord) {
    crntRecord = newRecord;
    if (bestRecord == -1 || newRecord < bestRecord) {
      bestRecord = newRecord;
    }
  }
}

/// Main container for all game save data including progression and unlocks
/// 
/// This class manages:
/// - Stage data for both arcade and adventure modes
/// - Star progression for normal and hard modes
/// - Stage unlocking state
/// - Prerequisites tracking
/// 
/// Usage:
/// ```dart
/// // Create new save data
/// final saveData = GameSaveData.initial(stageCount: 10);
/// 
/// // Update stage progress
/// saveData.updateScore(
///   GameSaveData.getStageKey(categoryId, stageNumber),
///   score: 100,
///   mode: 'normal'
/// );
/// 
/// // Update arcade record
/// saveData.updateArcadeRecord(
///   GameSaveData.getArcadeKey(categoryId),
///   record: 120
/// );
/// ```
class GameSaveData {
  final Map<String, StageDataEntry> stageData;
  final List<int> normalStageStars;
  final List<int> hardStageStars;
  final List<bool> unlockedNormalStages;
  final List<bool> unlockedHardStages;
  final List<bool> hasSeenPrerequisite;

  const GameSaveData({
    required this.stageData,
    required this.normalStageStars,
    required this.hardStageStars,
    required this.unlockedNormalStages,
    required this.unlockedHardStages,
    required this.hasSeenPrerequisite,
  });

  // Keep existing toMap for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'stageData': stageData.map((key, value) => MapEntry(key, value.toMap())),
      'normalStageStars': normalStageStars,
      'hardStageStars': hardStageStars,
      'unlockedNormalStages': unlockedNormalStages,
      'unlockedHardStages': unlockedHardStages,
      'hasSeenPrerequisite': hasSeenPrerequisite,
    };
  }

  // Add helper methods for common operations
  StageDataEntry? getStageData(String stageKey) => stageData[stageKey];
  
  bool isArcadeStage(String stageKey) => 
    stageData[stageKey] is ArcadeStageData;

  // Add methods for updating scores and records
  void updateScore(String stageKey, int score, String mode) {
    try {
      final data = stageData[stageKey];
      if (data == null) {
        throw GameSaveDataException('Stage data not found for key: $stageKey');
      }
      if (data is! AdventureStageData) {
        throw GameSaveDataException('Cannot update score for non-adventure stage');
      }
      
      if (score < 0) {
        throw GameSaveDataException('Score cannot be negative');
      }
      
      if (score > data.maxScore) {
        throw GameSaveDataException('Score cannot exceed max score');
      }

      if (mode.toLowerCase() == 'normal') {
        data.scoreNormal = score;
      } else if (mode.toLowerCase() == 'hard') {
        data.scoreHard = score;
      } else {
        throw GameSaveDataException('Invalid mode: $mode');
      }
    } catch (e) {
      if (e is GameSaveDataException) rethrow;
      throw GameSaveDataException('Error updating score: $e');
    }
  }

  void updateArcadeRecord(String stageKey, int record) {
    try {
      final data = stageData[stageKey];
      if (data == null) {
        throw GameSaveDataException('Stage data not found for key: $stageKey');
      }
      if (data is! ArcadeStageData) {
        throw GameSaveDataException('Cannot update record for non-arcade stage');
      }
      
      if (record < 0) {
        throw GameSaveDataException('Record cannot be negative');
      }

      data.updateRecord(record);
    } catch (e) {
      if (e is GameSaveDataException) rethrow;
      throw GameSaveDataException('Error updating arcade record: $e');
    }
  }

  // Add methods for stars and unlocks
  void updateStars(int stageIndex, int stars, String mode) {
    try {
      if (!isValidStageIndex(stageIndex)) return;
      
      if (stars < 0 || stars > 3) {
        throw GameSaveDataException('Stars must be between 0 and 3');
      }

      final list = mode.toLowerCase() == 'normal' 
          ? normalStageStars 
          : hardStageStars;
      
      if (stars > list[stageIndex]) {
        list[stageIndex] = stars;
      }
    } catch (e) {
      if (e is GameSaveDataException) rethrow;
      throw GameSaveDataException('Error updating stars: $e');
    }
  }

  void unlockStage(int stageIndex, String mode) {
    final list = mode.toLowerCase() == 'normal' ? unlockedNormalStages : unlockedHardStages;
    if (stageIndex >= 0 && stageIndex < list.length) {
      list[stageIndex] = true;
    }
  }

  void markPrerequisiteSeen(int stageIndex) {
    if (stageIndex >= 0 && stageIndex < hasSeenPrerequisite.length) {
      hasSeenPrerequisite[stageIndex] = true;
    }
  }

  // Factory constructor remains compatible with existing code
  factory GameSaveData.fromMap(Map<String, dynamic> map) {
    final stageDataMap = Map<String, StageDataEntry>.fromEntries(
      (map['stageData'] as Map<String, dynamic>).entries.map((e) {
        final data = e.value as Map<String, dynamic>;
        // Determine type based on data structure
        final isArcade = data.containsKey('bestRecord');
        return MapEntry(
          e.key,
          isArcade 
              ? ArcadeStageData.fromMap(data)
              : AdventureStageData.fromMap(data),
        );
      }),
    );

    return GameSaveData(
      stageData: stageDataMap,
      normalStageStars: List<int>.from(map['normalStageStars']),
      hardStageStars: List<int>.from(map['hardStageStars']),
      unlockedNormalStages: List<bool>.from(map['unlockedNormalStages']),
      unlockedHardStages: List<bool>.from(map['unlockedHardStages']),
      hasSeenPrerequisite: List<bool>.from(map['hasSeenPrerequisite']),
    );
  }

  // Add method to create initial data
  factory GameSaveData.initial(int stageCount) {
    return GameSaveData(
      stageData: {},
      normalStageStars: List<int>.filled(stageCount + 1, 0),
      hardStageStars: List<int>.filled(stageCount + 1, 0),
      unlockedNormalStages: List.generate(stageCount + 1, (i) => i == 0),
      unlockedHardStages: List.generate(stageCount + 1, (i) => i == 0),
      hasSeenPrerequisite: List<bool>.filled(stageCount + 1, false),
    );
  }

  // Helper to get stage key format
  static String getStageKey(String categoryId, int stageNumber) => 
    '${categoryId}$stageNumber';

  // Helper to get arcade key format
  static String getArcadeKey(String categoryId) => 
    '${categoryId}Arcade';

  // Get stage data with auto-creation if missing
  StageDataEntry getOrCreateStageData(String key, bool isArcade, int maxScore) {
    return stageData[key] ?? (isArcade 
      ? ArcadeStageData(maxScore: maxScore)
      : AdventureStageData(maxScore: maxScore));
  }

  // Get stage stats in standardized format
  Map<String, dynamic> getStageStats(String key, String mode) {
    final data = stageData[key];
    if (data is AdventureStageData) {
      return {
        'personalBest': mode.toLowerCase() == 'normal' 
            ? data.scoreNormal 
            : data.scoreHard,
        'maxScore': data.maxScore,
        'stars': mode.toLowerCase() == 'normal'
            ? normalStageStars[_getStageIndex(key)]
            : hardStageStars[_getStageIndex(key)],
      };
    } else if (data is ArcadeStageData) {
      return {
        'bestRecord': data.bestRecord,
        'crntRecord': data.crntRecord,
      };
    }
    return {};
  }

  // Helper to extract stage number from key
  int _getStageIndex(String key) {
    final match = RegExp(r'\d+$').firstMatch(key);
    return match != null ? int.parse(match.group(0)!) - 1 : 0;
  }

  // Check if stage is unlocked
  bool isStageUnlocked(int stageIndex, String mode) {
    final list = mode.toLowerCase() == 'normal' 
        ? unlockedNormalStages 
        : unlockedHardStages;
    return stageIndex >= 0 && stageIndex < list.length && list[stageIndex];
  }

  // Check if prerequisite is seen
  bool hasSeenStagePrerequisite(int stageIndex) {
    return stageIndex >= 0 && 
           stageIndex < hasSeenPrerequisite.length && 
           hasSeenPrerequisite[stageIndex];
  }

  // Create a copy with updates
  GameSaveData copyWith({
    Map<String, StageDataEntry>? stageData,
    List<int>? normalStageStars,
    List<int>? hardStageStars,
    List<bool>? unlockedNormalStages,
    List<bool>? unlockedHardStages,
    List<bool>? hasSeenPrerequisite,
  }) {
    return GameSaveData(
      stageData: stageData ?? Map.from(this.stageData),
      normalStageStars: normalStageStars ?? List.from(this.normalStageStars),
      hardStageStars: hardStageStars ?? List.from(this.hardStageStars),
      unlockedNormalStages: unlockedNormalStages ?? List.from(this.unlockedNormalStages),
      unlockedHardStages: unlockedHardStages ?? List.from(this.unlockedHardStages),
      hasSeenPrerequisite: hasSeenPrerequisite ?? List.from(this.hasSeenPrerequisite),
    );
  }

  // Add validation methods
  /// Checks if a stage index is valid for this save data
  bool isValidStageIndex(int index) {
    if (index < 0 || index >= normalStageStars.length) {
      throw GameSaveDataException('Invalid stage index: $index');
    }
    return true;
  }

  /// Checks if a stage can be unlocked based on previous stage completion
  bool canUnlockStage(int index, String mode) {
    try {
      // Don't try to unlock beyond total stages
      if (index >= unlockedNormalStages.length) return false;
      
      if (!isValidStageIndex(index)) return false;
      if (index == 0) return true;
      
      // For arcade stage (last index), check if all previous stages are unlocked
      if (index == unlockedNormalStages.length - 1) {
        final previousStages = mode.toLowerCase() == 'normal'
            ? unlockedNormalStages.sublist(0, index)
            : unlockedHardStages.sublist(0, index);
        return !previousStages.contains(false);
      }
      
      // For regular stages, just check the previous stage
      final previousUnlocked = mode.toLowerCase() == 'normal'
          ? unlockedNormalStages[index - 1]
          : unlockedHardStages[index - 1];
      return previousUnlocked;
    } catch (e) {
      throw GameSaveDataException('Error checking stage unlock: $e');
    }
  }
}