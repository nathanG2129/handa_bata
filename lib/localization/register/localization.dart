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
      'privacy_policy_start': 'I have read and understood the ',
      'privacy_policy_link': 'Privacy Policy',
      'privacy_policy_middle': ' and agree to the ',
      'terms_of_service_link': 'Terms of Service',
      'privacy_policy_title': 'Privacy Policy',
      'terms_of_service_title': 'Terms of Service',
      'privacy_policy_content': '''
Our Privacy Policy outlines how we collect, use, and protect your personal information.

Key points:
• We collect basic account information and gameplay data
• Your data is securely stored and never shared with third parties
• You can request deletion of your account and data at any time
      ''',
      'terms_of_service_content': '''
By using Handa Bata Mobile, you agree to:

• Be at least 13 years old
• Provide accurate registration information
• Not share your account credentials
• Use the app for educational purposes only
• Respect other users and our content guidelines
      ''',
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
      'login_instead': 'Mayroon nang Account? Mag-login dito.',
      'password_requirement_1': 'Hindi bababa sa 8 character',
      'password_requirement_2': 'May kasamang malaking titik',
      'password_requirement_3': 'May kasamang numero',
      'password_requirement_4': 'May kasamang simbolo',
      'privacy_policy_start': 'Nabasa at naintindihan ko ang ',
      'privacy_policy_link': 'Patakaran sa Privacy',
      'privacy_policy_middle': ' at sumasang-ayon sa ',
      'terms_of_service_link': 'Mga Tuntunin ng Serbisyo',
      'privacy_policy_title': 'Patakaran sa Privacy',
      'terms_of_service_title': 'Mga Tuntunin ng Serbisyo',
      'privacy_policy_content': '''
Ang aming Patakaran sa Privacy ay nagbabalangkas kung paano namin kinokolekta, ginagamit, at pinoprotektahan ang iyong personal na impormasyon.

Mahahalagang punto:
• Kinokolekta namin ang pangunahing impormasyon ng account at data ng gameplay
• Ang iyong data ay ligtas na naka-store at hindi ibinabahagi sa mga third party
• Maaari kang humiling ng pagbura ng iyong account at data anumang oras
      ''',
      'terms_of_service_content': '''
Sa paggamit ng Handa Bata Mobile, sumasang-ayon ka na:

• Hindi bababa sa 13 taong gulang
• Magbigay ng totoong impormasyon sa pagpaparehistro
• Hindi ibahagi ang iyong mga kredensyal ng account
• Gamitin ang app para sa layuning pang-edukasyon lamang
• Igalang ang ibang mga user at ang aming mga alituntunin sa content
      ''',
    },
  };

  static String translate(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ?? key;
  }
}