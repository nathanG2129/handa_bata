import 'package:flutter/material.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/buttons/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '../styles/input_styles.dart';
import '../localization/login/localization.dart'; // Import the localization file

class LoginPage extends StatefulWidget {
  final String selectedLanguage;

  const LoginPage({super.key, required this.selectedLanguage});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _selectedLanguage = 'en'; // Add language selection

    @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
    print('Selected language: $_selectedLanguage');

  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final user = await _authService.signInWithUsernameAndPassword(username, password);

        if (user != null) {
          _navigateToMainPage();
        } else {
          _showSnackBar('Login failed. Please try again.');
        }
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  void _navigateToMainPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
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
      body: ResponsiveBreakpoints(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: MaxWidthBox(
          maxWidth: 1200,
          child: ResponsiveScaledBox(
            width: ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 450),
              const Condition.between(start: 800, end: 1100, value: 800),
              const Condition.between(start: 1000, end: 1200, value: 1000),
            ]).value,
            child: Stack(
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
                                const SizedBox(height: 120),
                                TextWithShadow(text: 'Handa Bata', fontSize: handaBataFontSize),
                                Transform.translate(
                                  offset: const Offset(0, -20.0),
                                  child: Column(
                                    children: [
                                      TextWithShadow(text: 'Mobile', fontSize: mobileFontSize),
                                      const SizedBox(height: 30),
                                      Text(
                                        LoginLocalization.translate('welcome', _selectedLanguage),
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
                                  decoration: InputStyles.inputDecoration(LoginLocalization.translate('email', _selectedLanguage)),
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
                                  decoration: InputStyles.inputDecoration(LoginLocalization.translate('password', _selectedLanguage)),
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
                                      child: Text(
                                        LoginLocalization.translate('forgot_password', _selectedLanguage),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                CustomButton(
                                  text: LoginLocalization.translate('login_button', _selectedLanguage),
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
                                      const Condition.smallerThan(name: MOBILE, value: 45),
                                      const Condition.largerThan(name: MOBILE, value: 65),
                                    ],
                                  ).value,
                                ),
                                const SizedBox(height: 20),
                                CustomButton(
                                  text: LoginLocalization.translate('sign_up', _selectedLanguage),
                                  color: const Color(0xFFF1B33A),
                                  textColor: Colors.black,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RegistrationPage(selectedLanguage: _selectedLanguage)),
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
                                      const Condition.smallerThan(name: MOBILE, value: 45),
                                      const Condition.largerThan(name: MOBILE, value: 65),
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
          ),
        ),
      ),
    );
  }
}