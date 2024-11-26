class CharacterPageLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'characters': 'Characters',
      'saveChanges': 'Save Changes',
      'avatar': 'Avatar',
      'errorLoadingAvatars': 'Error loading avatars: ',
      'failedToUpdateAvatar': 'Failed to update avatar: ',
    },
    'fil': {
      'characters': 'Mga Characters',
      'saveChanges': 'I-save ang mga Pagbabago',
      'avatar': 'Avatar',
      'errorLoadingAvatars': 'May error sa pag-load ng mga avatar: ',
      'failedToUpdateAvatar': 'Hindi ma-update ang avatar: ',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 