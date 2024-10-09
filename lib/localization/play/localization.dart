class PlayLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'userProfile': 'My Profile',
      'adventure': 'Adventure',
      'arcade': 'Arcade',
      'favoriteBadges': 'Favorite Badges',
      'totalBadges': 'Total\nBadges',
      'stagesCleared': 'Stages\nCleared',
      'level': 'Level',
    },
    'fil': {
      'userProfile': 'Aking Profile',
      'adventure': 'Pakikipagsapalaran',
      'arcade': 'Arkada',
      'favoriteBadges': 'Paboritong Mga Badge',
      'totalBadges': 'Kabuuang\nBadge',
      'stagesCleared': 'Mga\nna-Clear\nna Stage',
      'level': 'Level',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
}