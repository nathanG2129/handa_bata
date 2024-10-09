class LoginLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Login',
      'email': 'Email',
      'password': 'Password',
      'login_button': 'Login',
      'forgot_password': 'Forgot Password?',
      'welcome': 'Welcome Back',
      'sign_up': 'Sign Up',
    },
    'fil': {
      'title': 'Mag-login',
      'email': 'Email',
      'password': 'Password',
      'login_button': 'Mag-login',
      'forgot_password': 'Nakalimutan ang Password?',
      'welcome': 'Maligayang Pagbabalik',
      'sign_up': 'Gumawa ng account',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}