class EmailVerificationLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Verify Email',
      'title_change_email': 'Verify New Email',
      'enter_code': 'Enter the code we sent to your email.',
      'code_expires': 'Code expires in',
      'verify_button': 'Verify',
      'signup_button': 'Sign Up',
      'resend_code': 'Didn\'t receive the code? Request a new one',
    },
    'fil': {
      'title': 'I-verify ang Email',
      'title_change_email': 'I-verify ang Bagong Email',
      'enter_code': 'Ilagay ang code na aming ipinadala sa iyong email.',
      'code_expires': 'Ang code ay mawawalan ng bisa sa loob ng',
      'verify_button': 'I-verify',
      'signup_button': 'Mag-sign up',
      'resend_code': 'Hindi natanggap ang code? Humiling ng panibago',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 