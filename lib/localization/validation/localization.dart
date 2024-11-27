class ValidationLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'required_email': 'Please enter your email',
      'invalid_email': 'Please enter a valid email address',
      'required_password': 'Please enter your password',
      'invalid_password': 'Password does not meet the requirements',
      'password_requirements_not_met': 'Password does not meet all requirements',
      'required_username': 'Please enter your username',
      'invalid_username': 'Username must be between 4 and 16 characters',
      'required_birthday': 'Please enter your birthday',
      'invalid_date': 'Invalid date format',
      'too_young': 'You must be at least 11 years old',
      'too_old': 'You must be at most 16 years old',
    },
    'fil': {
      'required_email': 'Ilagay ang email address.',
      'invalid_email': 'Maglagay ng wastong email address.',
      'required_password': 'Pumili ng password.',
      'invalid_password': 'Hindi natutugunan ng password ang mga kinakailangan.',
      'password_requirements_not_met': 'Hindi natutugunan ng password ang lahat ng kinakailangan.',
      'required_username': 'Pumili ng username.',
      'invalid_username': 'Ang username ay dapat mayroong 4 hanggang 16 na mga karakter',
      'required_birthday': 'Ilagay ang iyong kaarawan.',
      'invalid_date': 'Hindi wastong format ng petsa',
      'too_young': 'Dapat ay hindi bababa sa 11 taong gulang',
      'too_old': 'Dapat ay hindi hihigit sa 16 na taong gulang',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }
} 