class ForgotPasswordLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Forgot Password',
      'email_label': 'Email',
      'email_hint': 'Enter your email address',
      'continue_button': 'Continue',
      'back_button': 'Back',
      // Validation messages
      'please_enter_email': 'Please enter your email.',
      'invalid_email': 'Please enter a valid email.',
      'email_not_found': 'No account found with this email.',
      'email_sent': 'Password reset email sent.',
      'email_send_error': 'Failed to send password reset email.',
    },
    'fil': {
      'title': 'Forgot Password',
      'email_label': 'Email',
      'email_hint': 'Ilagay ang iyong email address',
      'continue_button': 'Magpatuloy',
      'back_button': 'Bumalik',
      // Validation messages
      'please_enter_email': 'Maglagay ng email sa loob ng kahon.',
      'invalid_email': 'Maglagay ng wastong email sa loob ng kahon.',
      'email_not_found': 'Walang account na nahanap sa email na ito.',
      'email_sent': 'Naipadala na ang password reset email.',
      'email_send_error': 'Hindi maipadala ang password reset email.',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 