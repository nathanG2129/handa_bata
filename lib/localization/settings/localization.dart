class SettingsLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'musicVolume': 'Music Volume',
      'sfxVolume': 'SFX Volume',
      'language': 'Language',
      'speed': 'Speed',
      'volume': 'Volume',
      'back': 'Back',
      'quitGame': 'Quit Game',
      'quitMessage': 'Are you sure you want to quit the game? You may lose your progress.',
      'textToSpeech': 'Text-to-Speech',
      'ttsVolume': 'TTS Volume',
    },
    'fil': {
      'settings': 'Mga Setting',
      'musicVolume': 'Lakas ng Musika',
      'sfxVolume': 'Lakas ng SFX',
      'language': 'Wika',
      'speed': 'Bilis',
      'volume': 'Lakas',
      'back': 'Bumalik',
      'quitGame': 'Mag-quit sa Laro',
      'quitMessage': 'Sigurado ka bang gusto mong mag-quit sa laro? Maaring mawala ang iyong progress.',
      'textToSpeech': 'Text-to-Speech',
      'ttsVolume': 'Lakas ng TTS',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 