class ResourcesLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'from': 'From',
      'the': 'the ',
    },
    'fil': {
      'from': 'Mula sa',
      'the': '',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
}