class ReauthLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Delete Account',
      'warning': 'Are you sure you want to leave Kladis and Kloud? Deleting your account cannot be undone, so please be sure you want to do this before proceeding.',
      'password_label': 'Password',
      'delete_button': 'Delete Account',
      'cancel_button': 'Cancel',
      'invalid_password': 'Invalid password',
      'no_user': 'No user found',
    },
    'fil': {
      'title': 'Tanggalin ang Account',
      'warning': 'Sigurado ka bang gusto mong iwan sina Kladis at Kloud? Ang pag-delete ng iyong account ay hindi na maaring bawiin, pakitiyak na gusto mong gawin ito bago magpatuloy.',
      'password_label': 'Password',
      'delete_button': 'I-delete ang Account',
      'cancel_button': 'I-cancel',
      'invalid_password': 'Hindi tamang password',
      'no_user': 'Walang nahanap na user',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 