class EmailChangeLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Change Email',
      'current_email': 'Current Email',
      'new_email': 'New Email',
      'current_password': 'Password',
      'change_button': 'Continue',
      'cancel_button': 'Cancel',
      // Validation messages
      'invalid_email': 'Please enter a valid email.',
      'same_email': 'New email must be different from current email.',
      'password_required': 'Your current password is required.',
      // Success/Error messages
      'email_change_success': 'Email changed successfully.',
      'email_change_error': 'Failed to change email.',
      'verification_sent': 'Verification code sent to your new email.',
      'verification_error': 'Failed to send verification code.',
    },
    'fil': {
      'title': 'Baguhin ang Email',
      'current_email': 'Kasalukuyang Email',
      'new_email': 'Bagong Email',
      'current_password': 'Password',
      'change_button': 'Magpatuloy',
      'cancel_button': 'I-cancel',
      // Validation messages
      'invalid_email': 'Maglagay ng wastong email sa loob ng kahon.',
      'same_email': 'Ang bagong email ay dapat iba sa kasalukuyang email.',
      'password_required': 'Kinakailangan ilagay ang password sa loob ng kahon.',
      // Success/Error messages
      'email_change_success': 'Matagumpay na napalitan ang email.',
      'email_change_error': 'Hindi napalitan ang email.',
      'verification_sent': 'Ang verification code ay ipinadala sa iyong bagong email.',
      'verification_error': 'Hindi maipadala ang verification code.',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 