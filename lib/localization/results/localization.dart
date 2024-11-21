class ResultsLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'niceTry': 'Nice Try!',
      'goodJob': 'Good Job!',
      'impressive': 'Impressive!',
      'outstanding': 'Outstanding!',
      'score': 'Score',
      'accuracy': 'Accuracy',
      'streak': 'Streak',
      'record': 'Record',
      'myPerformance': 'My Performance',
      'stageQuestions': 'Stage Questions',
      'back': 'Back',
      'playAgain': 'Play Again',
      'correctAnswer': 'Correct Answer:',
      'correctPairs': 'Correct Pairs:',
    },
    'fil': {
      'niceTry': 'Ayos lang yan!',
      'goodJob': 'Magaling!',
      'impressive': 'Kahanga-hanga!',
      'outstanding': 'Napakahusay!',
      'score': 'Puntos',
      'accuracy': 'Kawastuhan',
      'streak': 'Streak',
      'record': 'Rekord',
      'myPerformance': 'Aking Performance',
      'stageQuestions': 'Mga Tanong sa Stage',
      'back': 'Bumalik',
      'playAgain': 'Maglaro Muli',
      'correctAnswer': 'Tamang Sagot:',
      'correctPairs': 'Tamang Pares:',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 