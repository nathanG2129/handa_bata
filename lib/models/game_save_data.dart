class GameSaveData {
  final Map<String, Map<String, dynamic>> stageData;
  final List<int> normalStageStars;
  final List<int> hardStageStars;
  final List<bool> unlockedNormalStages;
  final List<bool> unlockedHardStages;
  final List<bool> hasSeenPrerequisite;

  GameSaveData({
    required this.stageData,
    required this.normalStageStars,
    required this.hardStageStars,
    required this.unlockedNormalStages,
    required this.unlockedHardStages,
    required this.hasSeenPrerequisite,
  });

  Map<String, dynamic> toMap() {
    return {
      'stageData': stageData,
      'normalStageStars': normalStageStars,
      'hardStageStars': hardStageStars,
      'unlockedNormalStages': unlockedNormalStages,
      'unlockedHardStages': unlockedHardStages,
      'hasSeenPrerequisite': hasSeenPrerequisite,
    };
  }

  factory GameSaveData.fromMap(Map<String, dynamic> map) {
    return GameSaveData(
      stageData: Map<String, Map<String, dynamic>>.from(map['stageData']),
      normalStageStars: List<int>.from(map['normalStageStars']),
      hardStageStars: List<int>.from(map['hardStageStars']),
      unlockedNormalStages: List<bool>.from(map['unlockedNormalStages']),
      unlockedHardStages: List<bool>.from(map['unlockedHardStages']),
      hasSeenPrerequisite: List<bool>.from(map['hasSeenPrerequisite']),
    );
  }
}