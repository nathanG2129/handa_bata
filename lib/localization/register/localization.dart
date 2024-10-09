class RegisterLocalization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Register',
      'username': 'Username',
      'email': 'Email',
      'birthday': 'Birthday',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'privacy_policy': 'I have read and understood the Privacy Policy and agree to the Terms of Service',
      'register_button': 'Register',
      'login_instead': 'Have an Account? Login instead',
      'password_requirement_1': 'At least 8 characters',
      'password_requirement_2': 'Includes an uppercase letter',
      'password_requirement_3': 'Includes a number',
      'password_requirement_4': 'Includes a symbol',
    },
    'fil': {
      'title': 'Gumawa ng Account',
      'username': 'Username',
      'email': 'Email',
      'birthday': 'Kaarawan',
      'password': 'Password',
      'confirm_password': 'Kumpirmahin ang Password',
      'privacy_policy': 'Nabasa at naintindihan ko ang Patakaran sa Privacy at sumasang-ayon sa Mga Tuntunin ng Serbisyo',
      'register_button': 'Magrehistro',
      'login_instead': 'May Account? Mag-login na lang',
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