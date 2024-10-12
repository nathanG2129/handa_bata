class StageDialogLocalization {
  static String translate(String key, String language) {
    Map<String, Map<String, String>> localizedValues = {
      'play_now': {
        'en': 'Play Now',
        'fil': 'Simulan Na',
      },
    };

    return localizedValues[key]?[language] ?? key;
  }
}