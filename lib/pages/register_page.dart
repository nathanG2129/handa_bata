import 'package:flutter/material.dart';
import '../helpers/validation_helpers.dart'; // Import the validation helpers
import '../helpers/widget_helpers.dart'; // Import the widget helpers
import '../helpers/dialog_helpers.dart'; // Import the dialog helpers
import '../helpers/date_helpers.dart'; // Import the date helpers
import '../widgets/privacy_policy_error.dart'; // Import the privacy policy error widget
import '../widgets/register_buttons.dart'; // Import the register buttons widget
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart'; // Import the AuthService

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
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
        User? user = await _authService.registerWithEmailAndPassword(email, password, username, birthday);

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          showEmailVerificationDialog(context);
        }
      } on FirebaseAuthException catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Handa Bata',
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Text(
                'Mobile App Edition',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text(
                'Register',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: _usernameController,
                labelText: 'Username',
                validator: validateUsername, // Use the new validateUsername function
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                validator: validateEmail,
              ),
              const SizedBox(height: 20),
              buildTextFormField(
                controller: _birthdayController,
                labelText: 'Birthday',
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
              buildTextFormField(
                controller: _passwordController,
                labelText: 'Password',
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
                  text: 'At least 8 characters',
                  isValid: _isPasswordLengthValid,
                ),
                buildPasswordRequirement(
                  text: 'Includes an uppercase letter',
                  isValid: _hasUppercase,
                ),
                buildPasswordRequirement(
                  text: 'Includes a number',
                  isValid: _hasNumber,
                ),
                buildPasswordRequirement(
                  text: 'Includes a symbol',
                  isValid: _hasSymbol,
                ),
              ],
              const SizedBox(height: 20),
              buildTextFormField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
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
                        _isPrivacyPolicyAccepted = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I have read the Privacy Policy and agree to the Terms of Service',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              PrivacyPolicyError(showError: _showPrivacyPolicyError),
              RegisterButtons(onRegister: _register),
            ],
          ),
        ),
      ),
    );
  }
}