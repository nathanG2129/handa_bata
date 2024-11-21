class AccountDeletionLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Delete Account',
      'guest_warning': 'Are you sure you want to delete your guest account? All your progress will be lost and cannot be recovered.',
      'user_warning': 'Are you sure you want to leave Kladis and Kloud? Deleting your account cannot be undone, so please be sure you want to do this before proceeding.',
      'delete_button': 'Delete',
      'cancel_button': 'Cancel',
    },
    'fil': {
      'title': 'Tanggalin ang Account',
      'guest_warning': 'Sigurado ka bang gusto mong tanggalin ang iyong guest account? Mawawala ang lahat ng iyong progress at hindi na maibabalik.',
      'user_warning': 'Sigurado ka bang gusto mong iwan sina Kladis at Kloud? Ang pag-delete ng iyong account ay hindi na maaring bawiin, pakitiyak na gusto mong gawin ito bago magpatuloy.',
      'delete_button': 'Tanggalin',
      'cancel_button': 'I-cancel',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 