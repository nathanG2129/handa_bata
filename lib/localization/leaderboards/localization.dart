class LeaderboardsLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Leaderboards',
      'no_records': 'No records yet, be the first to submit one!',
      'description': 'Show the world what you\'re made of and climb the leaderboards!',
      'shake': 'Shake',
      'rumble': 'Rumble',
      'inferno': 'Inferno',
      'scorch': 'Scorch',
      'deluge': 'Deluge',
      'surge': 'Surge',
    },
    'fil': {
      'title': 'Leaderboards',
      'no_records': 'Wala pang mga record, maging ikaw ang unang makapag-submit ng isa!',
      'description': 'Ipakita sa mundo ang iyong gilas at umakyat sa leaderboards!',
      'shake': 'Shake',
      'rumble': 'Rumble',
      'inferno': 'Inferno',
      'scorch': 'Scorch',
      'deluge': 'Deluge',
      'surge': 'Surge',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }

  static String getArcadeName(String categoryName, String languageCode) {
    if (categoryName.contains('Quake')) return translate('shake', languageCode);
    if (categoryName.contains('Storm')) return translate('rumble', languageCode);
    if (categoryName.contains('Volcano')) return translate('inferno', languageCode);
    if (categoryName.contains('Drought')) return translate('scorch', languageCode);
    if (categoryName.contains('Flood')) return translate('deluge', languageCode);
    if (categoryName.contains('Tsunami')) return translate('surge', languageCode);
    return categoryName;
  }
} 