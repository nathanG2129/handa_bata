// localization/play/localization.dart
class PlayLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'userProfile': 'My Profile',
      'adventure': 'Adventure',
      'arcade': 'Arcade',
    },
    'fil': {
      'userProfile': 'Aking Profile',
      'adventure': 'Pakikipagsapalaran',
      'arcade': 'Arkada',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
}