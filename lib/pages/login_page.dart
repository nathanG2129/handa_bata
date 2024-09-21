import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'play_page.dart';
import 'register_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '../styles/input_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = false;

  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final email = await _authService.getEmailByUsername(username);

        if (email != null) {
          final user = await _authService.signInWithEmailAndPassword(email, password);

          if (user != null) {
            _navigateToPlayPage();
          } else {
            _showSnackBar('Login failed. Please try again.');
          }
        } else {
          _showSnackBar('Username not found. Please try again.');
        }
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  void _navigateToPlayPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlayPage(title: 'Home Page')),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _forgotPassword() {
    // Handle forgot password
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.only(top: 120.0),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const TextWithShadow(text: 'Handa Bata', fontSize: 85),
                          Transform.translate(
                            offset: const Offset(0, -20.0),
                            child: Column(
                              children: [
                                const TextWithShadow(text: 'Mobile', fontSize: 75),
                                const SizedBox(height: 30),
                                Text(
                                  'Welcome Back',
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
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputStyles.inputDecoration('Username'),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputStyles.inputDecoration('Password'),
                            style: const TextStyle(color: Colors.white), // Changed text color to white
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Checkbox(
                                    value: _staySignedIn,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _staySignedIn = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Stay signed in',
                                    style: TextStyle(
                                      color: Colors.white, // Changed text color to white
                                      fontSize: 16, // Added fontSize variable
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Colors.white, // Changed text color to white
                                    fontSize: 16, // Added fontSize variable
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          CustomButton(
                            text: 'Login',
                            color: const Color(0xFF351B61),
                            textColor: Colors.white,
                            onTap: _login,
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Register',
                            color: const Color(0xFFF1B33A),
                            textColor: Colors.black,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegistrationPage()),
                              );
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
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36), // Increased size
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}