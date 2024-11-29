class StageLockLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Stage Locked',
      'message': 'To unlock this stage and continue your adventure with Kladis and Kloud, please register an account first!',
      'register_button': 'Register',
      'cancel_button': 'Cancel',
    },
    'fil': {
      'title': 'Naka-lock ang Stage',
      'message': 'Upang ma-unlock ang stage na ito at magpatuloy sa adventure kasama sina Kladis at Kloud, maaring mag-register muna ng account!',
      'register_button': 'Mag-register',
      'cancel_button': 'I-cancel',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 