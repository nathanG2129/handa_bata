class BannerPageLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'banners': 'Banners',
      'saveChanges': 'Save Changes',
      'banner': 'Banner',
      'all': 'All',
      'myCollection': 'My Collection',
      'unlocksAtLevel': 'Unlocks at Level',
      'noBannersFound': 'No banners found.',
      'errorUpdatingBanner': 'Error updating banner: ',
    },
    'fil': {
      'banners': 'Mga Banner',
      'saveChanges': 'I-save ang mga Pagbabago',
      'banner': 'Banner',
      'all': 'Lahat',
      'myCollection': 'Aking Koleksyon',
      'unlocksAtLevel': 'Mag-unlock sa Level',
      'noBannersFound': 'Walang nakitang banner.',
      'errorUpdatingBanner': 'May error sa pag-update ng banner: ',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 