class SplashLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Handa Bata',
      'subtitle': 'Mobile',
      'login': 'Login',
      'play_now': 'Play Now',
      'copyright': '© 2023 Handa Bata. All rights reserved.',
    },
    'fil': {
      'title': 'Handa Bata',
      'subtitle': 'Mobile',
      'login': 'Mag-login',
      'play_now': 'Maglaro Na',
      'copyright': '© 2023 Handa Bata. All rights reserved.',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}