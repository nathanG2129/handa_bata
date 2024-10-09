import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/validation_helpers.dart'; // Import the validation helpers
import '../helpers/widget_helpers.dart'; // Import the widget helpers
import '../helpers/dialog_helpers.dart'; // Import the dialog helpers
import '../helpers/date_helpers.dart'; // Import the date helpers
import '../widgets/privacy_policy_error.dart'; // Import the privacy policy error widget
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; // Import the AuthService
import '../styles/input_styles.dart'; // Import the InputStyles
import '../widgets/custom_button.dart'; // Import the CustomButton
import '../widgets/text_with_shadow.dart'; // Import the TextWithShadow
import 'package:responsive_framework/responsive_framework.dart';
import '../localization/register/localization.dart'; // Import the localization file

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPrivacyPolicyAccepted = false;
  bool _showPrivacyPolicyError = false;
  bool _isPasswordLengthValid = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _isPasswordFieldTouched = false;

  final AuthService _authService = AuthService();
  String _selectedLanguage = 'en'; // Add language selection

  void _register() async {
    setState(() {
      _showPrivacyPolicyError = !_isPrivacyPolicyAccepted;
    });

    if (_formKey.currentState!.validate() && _isPrivacyPolicyAccepted) {
      final username = _usernameController.text;
      final email = _emailController.text;
      final birthday = _birthdayController.text;
      final password = _passwordController.text;

      try {
        User? user = await _authService.registerWithEmailAndPassword(
          email,
          password,
          username,
          username, // Pass username as nickname
          birthday,
          role: 'user', // Pass the role parameter
        );

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          if (!mounted) return;
          showEmailVerificationDialog(context);
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    double handaBataFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 75,
      conditionalValues: [
        const Condition.smallerThan(name: MOBILE, value: 65),
        const Condition.largerThan(name: MOBILE, value: 100),
      ],
    ).value;

    double mobileFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 65,
      conditionalValues: [
        const Condition.smallerThan(name: MOBILE, value: 55),
        const Condition.largerThan(name: MOBILE, value: 90),
      ],
    ).value;

    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/backgrounds/background.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TextWithShadow(text: 'Handa Bata', fontSize: handaBataFontSize),
                          Transform.translate(
                            offset: const Offset(0, -20.0),
                            child: Column(
                              children: [
                                TextWithShadow(text: 'Mobile', fontSize: mobileFontSize),
                                const SizedBox(height: 0), // Reduced height
                                Text(
                                  RegisterLocalization.translate('title', _selectedLanguage),
                                  style: GoogleFonts.vt323(
                                    fontSize: 30,
                                    color: Colors.white,
                                    shadows: [
                                      const Shadow(
                                        offset: Offset(0, 3.0),
                                        blurRadius: 0.0,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10), // Reduced height
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputStyles.inputDecoration(RegisterLocalization.translate('username', _selectedLanguage)),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            validator: validateUsername, // Use the new validateUsername function
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputStyles.inputDecoration(RegisterLocalization.translate('email', _selectedLanguage)),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _birthdayController,
                            decoration: InputStyles.inputDecoration(RegisterLocalization.translate('birthday', _selectedLanguage)),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            readOnly: true,
                            onTap: () => selectDate(context, _birthdayController), // Use selectDate from date_helpers.dart
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your birthday';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputStyles.inputDecoration(RegisterLocalization.translate('password', _selectedLanguage)),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            obscureText: true,
                            validator: (value) => passwordValidator(value, _isPasswordLengthValid, _hasUppercase, _hasNumber, _hasSymbol),
                            onChanged: (value) {
                              setState(() {
                                _isPasswordFieldTouched = true;
                              });
                              validatePassword(value, (isPasswordLengthValid, hasUppercase, hasNumber, hasSymbol) {
                                setState(() {
                                  _isPasswordLengthValid = isPasswordLengthValid;
                                  _hasUppercase = hasUppercase;
                                  _hasNumber = hasNumber;
                                  _hasSymbol = hasSymbol;
                                });
                              });
                            },
                          ),
                          if (_isPasswordFieldTouched) ...[
                            const SizedBox(height: 10),
                            buildPasswordRequirement(
                              text: RegisterLocalization.translate('password_requirement_1', _selectedLanguage),
                              isValid: _isPasswordLengthValid,
                            ),
                            buildPasswordRequirement(
                              text: RegisterLocalization.translate('password_requirement_2', _selectedLanguage),
                              isValid: _hasUppercase,
                            ),
                            buildPasswordRequirement(
                              text: RegisterLocalization.translate('password_requirement_3', _selectedLanguage),
                              isValid: _hasNumber,
                            ),
                            buildPasswordRequirement(
                              text: RegisterLocalization.translate('password_requirement_4', _selectedLanguage),
                              isValid: _hasSymbol,
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputStyles.inputDecoration(RegisterLocalization.translate('confirm_password', _selectedLanguage)),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _isPrivacyPolicyAccepted,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPrivacyPolicyAccepted = value!;
                                  });
                                },
                              ),
                              Flexible(
                                child: Text(
                                  RegisterLocalization.translate('privacy_policy', _selectedLanguage),
                                  style: const TextStyle(color: Colors.white), // Changed text color to white
                                ),
                              ),
                            ],
                          ),
                          if (_showPrivacyPolicyError)
                            PrivacyPolicyError(showError: _showPrivacyPolicyError),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: RegisterLocalization.translate('register_button', _selectedLanguage),
                            color: const Color(0xFF351B61),
                            textColor: Colors.white,
                            onTap: _register,
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: RegisterLocalization.translate('login_instead', _selectedLanguage),
                            color: Colors.white,
                            textColor: Colors.black,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 35,
            child: DropdownButton<String>(
              icon: const Icon(Icons.language, color: Colors.white, size: 40), // Larger icon
              underline: Container(), // Remove underline
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'fil',
                  child: Text('Filipino'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeLanguage(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}