import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'play_page.dart'; // Ensure PlayPage is imported
import '../helpers/validation_helpers.dart'; // Import the validation helpers
import '../helpers/widget_helpers.dart'; // Import the widget helpers

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

      final user = await _authService.registerWithEmailAndPassword(
        username: username,
        email: email,
        birthday: birthday,
        password: password,
      );

      if (user != null) {
        // Navigate to play_page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlayPage(title: '',)), // Ensure PlayPage is imported
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.toLocal()}".split(' ')[0];
      });
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
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
                onTap: () => _selectDate(context),
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
              if (_showPrivacyPolicyError)
                const Text(
                  'You must accept the privacy policy to register.',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Join'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Have an account? Login instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}