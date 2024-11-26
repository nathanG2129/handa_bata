class BadgePageLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'badges': 'Badges',
      'saveChanges': 'Save Changes',
      'badge': 'Badge',
      'all': 'All',
      'myCollection': 'My Collection',
      'quakeBadges': 'Quake Badges',
      'stormBadges': 'Storm Badges',
      'volcanoBadges': 'Volcano Badges',
      'droughtBadges': 'Drought Badges',
      'tsunamiBadges': 'Tsunami Badges',
      'floodBadges': 'Flood Badges',
      'arcadeBadges': 'Arcade Badges',
      'noBadgesFound': 'No badges found.',
      'errorUpdatingBadge': 'Error updating badge: ',
    },
    'fil': {
      'badges': 'Mga Badge',
      'saveChanges': 'I-save ang mga Pagbabago',
      'badge': 'Badge',
      'all': 'Lahat',
      'myCollection': 'Aking Koleksyon',
      'quakeBadges': 'Mga Badge sa Quake',
      'stormBadges': 'Mga Badge sa Storm',
      'volcanoBadges': 'Mga Badge sa Volcano',
      'droughtBadges': 'Mga Badge sa Drought',
      'tsunamiBadges': 'Mga Badge sa Tsunami',
      'floodBadges': 'Mga Badge sa Flood',
      'arcadeBadges': 'Mga Badge sa Arcade',
      'noBadgesFound': 'Walang nakitang badge.',
      'errorUpdatingBadge': 'May error sa pag-update ng badge: ',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 