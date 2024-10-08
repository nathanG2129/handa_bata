import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final user = await _authService.signInWithUsernameAndPassword(username, password);

        if (user != null) {
          _navigateToPlayPage();
        } else {
          _showSnackBar('Login failed. Please try again.');
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
    double handaBataFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 75,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 65),
        Condition.largerThan(name: MOBILE, value: 100),
      ],
    ).value!;

    double mobileFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 65,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: 55),
        Condition.largerThan(name: MOBILE, value: 90),
      ],
    ).value!;

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
                padding: const EdgeInsets.only(top: 10.0),
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

                              TextButton(
                                onPressed: _forgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Login',
                            color: const Color(0xFF351B61),
                            textColor: Colors.white,
                            onTap: _login,
                            width: ResponsiveValue<double>(
                              context,
                              defaultValue: MediaQuery.of(context).size.width * 0.8,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.7),
                                Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                              ],
                            ).value,
                            height: ResponsiveValue<double>(
                              context,
                              defaultValue: 55,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 45),
                                Condition.largerThan(name: MOBILE, value: 65),
                              ],
                            ).value,
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
                            width: ResponsiveValue<double>(
                              context,
                              defaultValue: MediaQuery.of(context).size.width * 0.8,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.7),
                                Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                              ],
                            ).value,
                            height: ResponsiveValue<double>(
                              context,
                              defaultValue: 55,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 45),
                                Condition.largerThan(name: MOBILE, value: 65),
                              ],
                            ).value,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}