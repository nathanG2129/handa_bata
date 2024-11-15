class GameState {
  final String categoryId;
  final String stageId;
  final String mode;
  final String gamemode;
  final int currentQuestionIndex;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> answeredQuestions;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int currentStreak;
  final int highestStreak;
  final double hp;
  final bool isGameOver;
  // Arcade specific fields
  final String? stopwatchTime;
  final double? averageTimePerQuestion;
  final int? questionsAnswered;
  final bool completed;
  final DateTime? lastSaved;

  const GameState({
    required this.categoryId,
    required this.stageId,
    required this.mode,
    required this.gamemode,
    required this.currentQuestionIndex,
    required this.questions,
    required this.answeredQuestions,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.currentStreak,
    required this.highestStreak,
    required this.hp,
    required this.isGameOver,
    this.stopwatchTime,
    this.averageTimePerQuestion,
    this.questionsAnswered,
    this.completed = false,
    this.lastSaved,
  });

  bool get isArcadeMode => gamemode == 'arcade';
  
  double get accuracy => 
      (correctAnswers + wrongAnswers) > 0 
          ? correctAnswers / (correctAnswers + wrongAnswers) 
          : 0.0;

  bool get shouldAutoSave => 
      !completed && 
      currentQuestionIndex > 0 && 
      !isGameOver;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'stageId': stageId,
    'mode': mode,
    'gamemode': gamemode,
    'currentQuestionIndex': currentQuestionIndex,
    'questions': questions,
    'answeredQuestions': answeredQuestions.map((q) => 
      Map<String, dynamic>.from(q)  // Ensure proper type conversion
    ).toList(),
    'score': score,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'currentStreak': currentStreak,
    'highestStreak': highestStreak,
    'hp': hp,
    'isGameOver': isGameOver,
    'stopwatchTime': stopwatchTime,
    'averageTimePerQuestion': averageTimePerQuestion,
    'questionsAnswered': questionsAnswered,
    'completed': completed,
    'lastSaved': lastSaved?.toIso8601String(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    categoryId: json['categoryId'] as String,
    stageId: json['stageId'] as String,
    mode: json['mode'] as String,
    gamemode: json['gamemode'] as String,
    currentQuestionIndex: json['currentQuestionIndex'] as int,
    questions: List<Map<String, dynamic>>.from(json['questions'] as List),
    answeredQuestions: List<Map<String, dynamic>>.from(
      (json['answeredQuestions'] as List? ?? []).map((q) => 
        Map<String, dynamic>.from(q as Map)  // Ensure proper type conversion
      )
    ),
    score: json['score'] as int,
    correctAnswers: json['correctAnswers'] as int,
    wrongAnswers: json['wrongAnswers'] as int,
    currentStreak: json['currentStreak'] as int,
    highestStreak: json['highestStreak'] as int,
    hp: json['hp'] as double,
    isGameOver: json['isGameOver'] as bool,
    stopwatchTime: json['stopwatchTime'] as String?,
    averageTimePerQuestion: json['averageTimePerQuestion'] as double?,
    questionsAnswered: json['questionsAnswered'] as int?,
    completed: json['completed'] as bool? ?? false,
    lastSaved: json['lastSaved'] != null 
        ? DateTime.parse(json['lastSaved'] as String)
        : null,
  );

  GameState copyWith({
    String? categoryId,
    String? stageId,
    String? mode,
    String? gamemode,
    int? currentQuestionIndex,
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? answeredQuestions,
    int? score,
    int? correctAnswers,
    int? wrongAnswers,
    int? currentStreak,
    int? highestStreak,
    double? hp,
    bool? isGameOver,
    String? stopwatchTime,
    double? averageTimePerQuestion,
    int? questionsAnswered,
    bool? completed,
    DateTime? lastSaved,
  }) => GameState(
    categoryId: categoryId ?? this.categoryId,
    stageId: stageId ?? this.stageId,
    mode: mode ?? this.mode,
    gamemode: gamemode ?? this.gamemode,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    questions: questions ?? this.questions,
    answeredQuestions: answeredQuestions ?? this.answeredQuestions,
    score: score ?? this.score,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    wrongAnswers: wrongAnswers ?? this.wrongAnswers,
    currentStreak: currentStreak ?? this.currentStreak,
    highestStreak: highestStreak ?? this.highestStreak,
    hp: hp ?? this.hp,
    isGameOver: isGameOver ?? this.isGameOver,
    stopwatchTime: stopwatchTime ?? this.stopwatchTime,
    averageTimePerQuestion: averageTimePerQuestion ?? this.averageTimePerQuestion,
    questionsAnswered: questionsAnswered ?? this.questionsAnswered,
    completed: completed ?? this.completed,
    lastSaved: lastSaved ?? this.lastSaved,
  );
} 