class FAQLocalization {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'faq_title': 'Frequently Asked Questions',
      'how_to_login_question': 'How to log in?',
      'how_to_login_answer': 'Once registered, you may log in by tapping the Log in button, then go enter your Username and Password.',
      'how_to_change_language_question': 'How to change the language?',
      'how_to_change_language_answer': 'You may change the language by tapping the globe button located at the top right corner of the screen. Available languages are English and Filipino.',
      'how_to_register_question': 'How do I register for an account?',
      'how_to_register_answer': 'Click the Register button, then fill in your details including email, username, and password. Make sure to use a valid email address as you\'ll need to verify it.',
      'email_verification_question': 'Why do I need to verify my email?',
      'email_verification_answer': 'Email verification helps secure your account and ensures we can contact you if needed. Check your email after registration and click the verification link.',
      'forgot_password_question': 'I forgot my password. What should I do?',
      'forgot_password_answer': 'Click the "Forgot Password" link on the login page. Enter your email address, and we\'ll send you instructions to reset your password.',
      'profile_customization_question': 'How can I customize my profile?',
      'profile_customization_answer': 'Go to your Profile page to update your banner, badges, and other information. You can earn new badges by completing stages and achievements in the game.',
    },
    'fil': {
      'faq_title': 'Mga Madalas Itanong',
      'how_to_login_question': 'Paano mag-log in?',
      'how_to_login_answer': 'Kapag nakapag-register na, pindutin ang Log in, tapos ilagay ang Username at Password.',
      'how_to_change_language_question': 'Paano palitan ang wika?',
      'how_to_change_language_answer': 'Maaaring palitan ang wika sa pamamagitan ng pagpindot ng logong globo na matatagpuan sa kanang ibabaw na bahagi ng screen. Ang mga maaring magamit na wika ay Ingles at Filipino.',
      'how_to_register_question': 'Paano mag-register ng account?',
      'how_to_register_answer': 'I-click ang Register button, pagkatapos ay punan ang mga detalye tulad ng email, username, at password. Siguraduhing gumamit ng wastong email address dahil kailangan mo itong i-verify.',
      'email_verification_question': 'Bakit kailangan i-verify ang email ko?',
      'email_verification_answer': 'Ang pag-verify ng email ay nakakatulong na masiguro ang seguridad ng iyong account at tinitiyak na maaari kaming makipag-ugnayan sa iyo kung kinakailangan. Tingnan ang iyong email pagkatapos mag-register at i-click ang verification link.',
      'forgot_password_question': 'Nakalimutan ko ang aking password. Ano ang dapat kong gawin?',
      'forgot_password_answer': 'I-click ang "Nakalimutan ang Password" na link sa login page. Ilagay ang iyong email address, at magpapadala kami ng mga tagubilin para ma-reset ang iyong password.',
      'profile_customization_question': 'Paano ko ma-customize ang aking profile?',
      'profile_customization_answer': 'Pumunta sa iyong Profile page para i-update ang iyong banner, badges, at iba pang impormasyon. Maaari kang makakuha ng mga bagong badge sa pamamagitan ng pagkumpleto ng mga stage at achievements sa game.',
    },
  };

  static String translate(String key, String language) {
    return _localizedValues[language]?[key] ?? key;
  }

  static List<Map<String, String>> getFAQs(String language) {
    return [
      {
        'question': translate('how_to_login_question', language),
        'answer': translate('how_to_login_answer', language),
      },
      {
        'question': translate('how_to_register_question', language),
        'answer': translate('how_to_register_answer', language),
      },
      {
        'question': translate('email_verification_question', language),
        'answer': translate('email_verification_answer', language),
      },
      {
        'question': translate('forgot_password_question', language),
        'answer': translate('forgot_password_answer', language),
      },
      {
        'question': translate('how_to_change_language_question', language),
        'answer': translate('how_to_change_language_answer', language),
      },
      {
        'question': translate('profile_customization_question', language),
        'answer': translate('profile_customization_answer', language),
      },
    ];
  }
} 