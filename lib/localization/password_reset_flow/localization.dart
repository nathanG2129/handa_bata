class PasswordResetFlowLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Reset Password',
      'enter_otp': 'Enter the verification code sent to your email:',
      'code_expires': 'Code expires in',
      'verify_button': 'Verify',
      'new_password': 'New Password',
      'confirm_password': 'Confirm New Password',
      'reset_button': 'Reset Password',
      'success_message': 'Password reset successful! You can now log in with your new password.',
      'login_button': 'Log In',
      // Validation messages
      'please_enter_otp': 'Please enter the verification code',
      'invalid_otp': 'Invalid verification code',
      'please_enter_password': 'Please enter a new password',
      'passwords_not_match': 'Passwords do not match',
      'password_requirements': 'Password must be at least 8 characters long and include uppercase, lowercase, number, and symbol',
      'resend_code': "Didn't receive the code? Request a new one",
    },
    'fil': {
      'title': 'I-reset ang Password',
      'enter_otp': 'Ilagay ang verification code na ipinadala sa iyong email:',
      'code_expires': 'Mag-e-expire ang code sa loob ng',
      'verify_button': 'I-verify',
      'new_password': 'Bagong Password',
      'confirm_password': 'Kumpirmahin ang Bagong Password',
      'reset_button': 'I-reset ang Password',
      'success_message': 'Matagumpay na na-reset ang password! Maaari ka nang mag-log in gamit ang iyong bagong password.',
      'login_button': 'Mag-log In',
      // Validation messages
      'please_enter_otp': 'Mangyaring ilagay ang verification code',
      'invalid_otp': 'Hindi wastong verification code',
      'please_enter_password': 'Mangyaring maglagay ng bagong password',
      'passwords_not_match': 'Hindi magkatugma ang mga password',
      'password_requirements': 'Ang password ay dapat hindi bababa sa 8 character at may malaking titik, maliit na titik, numero, at simbolo',
      'resend_code': 'Hindi natanggap ang code? Humiling ng panibago',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 