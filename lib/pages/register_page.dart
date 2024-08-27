import 'package:flutter/material.dart';
import '/auth_service.dart';
import 'login_page.dart';
import 'play_page.dart'; // Ensure PlayPage is imported

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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0), // Oblong shape
        ),
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      onChanged: (value) {
        if (controller == _passwordController) {
          setState(() {
            _isPasswordFieldTouched = true;
          });
          _validatePassword(value);
        }
      },
    );
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordLengthValid = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'\d'));
      _hasSymbol = value.contains(RegExp(r'[!@#\$&*~]'));
    });
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (!_isPasswordLengthValid || !_hasUppercase || !_hasNumber || !_hasSymbol) {
      return 'Password does not meet the requirements';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Widget _buildPasswordRequirement({required String text, required bool isValid}) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check : Icons.close,
          color: isValid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
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
              _buildTextFormField(
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
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
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
              _buildTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: _passwordValidator,
              ),
              if (_isPasswordFieldTouched) ...[
                const SizedBox(height: 10),
                _buildPasswordRequirement(
                  text: 'At least 8 characters',
                  isValid: _isPasswordLengthValid,
                ),
                _buildPasswordRequirement(
                  text: 'Includes an uppercase letter',
                  isValid: _hasUppercase,
                ),
                _buildPasswordRequirement(
                  text: 'Includes a number',
                  isValid: _hasNumber,
                ),
                _buildPasswordRequirement(
                  text: 'Includes a symbol',
                  isValid: _hasSymbol,
                ),
              ],
              const SizedBox(height: 20),
              _buildTextFormField(
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