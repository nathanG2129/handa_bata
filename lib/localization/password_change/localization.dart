class PasswordChangeLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm New Password',
      'save_button': 'Save',
      'cancel_button': 'Cancel',
      // Validation messages
      'password_required': 'Password is required.',
      'passwords_not_match': 'Passwords do not match.',
      'same_password': 'New password must be different.',
      // Success/Error messages
      'password_change_success': 'Password changed successfully.',
      'password_change_error': 'Failed to change password.',
      // Password requirements
      'password_requirement_1': 'At least 8 characters',
      'password_requirement_2': 'Includes an uppercase letter',
      'password_requirement_3': 'Includes a number',
      'password_requirement_4': 'Includes a symbol',
    },
    'fil': {
      'title': 'Baguhin ang Password',
      'current_password': 'Kasalukuyang Password',
      'new_password': 'Bagong Password',
      'confirm_password': 'Kumpirmahin ang Bagong Password',
      'save_button': 'I-save',
      'cancel_button': 'I-cancel',
      // Validation messages
      'password_required': 'Kinakailangan ang password',
      'passwords_not_match': 'Hindi magkatugma ang mga bagong password',
      'same_password': 'Ang bagong password ay dapat iba',
      // Success/Error messages
      'password_change_success': 'Matagumpay na nabago ang password.',
      'password_change_error': 'Hindi nabago ang password.',
      // Password requirements
      'password_requirement_1': 'Hindi bababa sa 8 character',
      'password_requirement_2': 'May kasamang malaking titik',
      'password_requirement_3': 'May kasamang numero',
      'password_requirement_4': 'May kasamang simbolo',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
} 