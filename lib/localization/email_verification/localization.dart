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
      'invalid_code': 'Invalid verification code. Please try again.',
      'verification_failed': 'Verification failed. Please try again.',
      'send_code_error': 'Failed to send verification code. Please try again.',
      'username_taken': 'This username is no longer available. Please choose another.',
      'conversion_failed': 'Account conversion failed. Please try again.',
      'email_change_failed': 'Failed to change email. Please try again.',
      'email_verification_failed': 'Email verification failed. Please try again.',
      'email_already_in_use': 'This email is already in use. Please use a different email.',
    },
    'fil': {
      'title': 'I-verify ang Email',
      'title_change_email': 'I-verify ang Bagong Email',
      'enter_code': 'Ilagay ang code na aming ipinadala sa iyong email.',
      'code_expires': 'Ang code ay mawawalan ng bisa sa loob ng',
      'verify_button': 'I-verify',
      'signup_button': 'Mag-sign up',
      'resend_code': 'Hindi natanggap ang code? Humiling ng panibago',
      'invalid_code': 'Hindi wasto ang verification code. Pakisubukang muli.',
      'verification_failed': 'Hindi nagtagumpay ang pag-verify. Pakisubukang muli.',
      'send_code_error': 'Hindi maipadala ang verification code. Pakisubukang muli.',
      'username_taken': 'Hindi na available ang username na ito. Pumili ng iba.',
      'conversion_failed': 'Hindi nagtagumpay ang conversion ng account. Pakisubukang muli.',
      'email_change_failed': 'Hindi nagtagumpay ang pagpapalit ng email. Pakisubukang muli.',
      'email_verification_failed': 'Hindi nagtagumpay ang pag-verify ng email. Pakisubukang muli.',
      'email_already_in_use': 'Ginagamit na ang email na ito. Gumamit ng ibang email.',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 