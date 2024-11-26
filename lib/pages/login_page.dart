import 'package:flutter/material.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/buttons/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '../styles/input_styles.dart';
import '../localization/login/localization.dart'; // Import the localization file
import '../widgets/loading_widget.dart';
import '../widgets/dialogs/forgot_password_dialog.dart';
import '../widgets/dialogs/password_reset_flow_dialog.dart';
import '../constants/breakpoints.dart';
import '../utils/responsive_utils.dart';
import 'splash_page.dart';

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
  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  bool _isLoading = false;

    @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language

  }

  bool _isRateLimited() {
    if (_loginAttempts >= 5) {
      final now = DateTime.now();
      if (_lastLoginAttempt != null && 
          now.difference(_lastLoginAttempt!) < const Duration(minutes: 15)) {
        return true;
      }
      _loginAttempts = 0;
    }
    return false;
  }

  Future<void> _login() async {
    if (_isLoading) return; // Prevent multiple login attempts
    
    if (_isRateLimited()) {
      _showRateLimitError();
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginAttempts++;
      });
      _lastLoginAttempt = DateTime.now();

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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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

  void _forgotPassword() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ForgotPasswordDialog(
        selectedLanguage: _selectedLanguage,
        darkenColor: darkenColor,
        onEmailSubmitted: (email) async {
          Navigator.of(dialogContext).pop(); // Close email input dialog
          
          // Show the password reset flow dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PasswordResetFlowDialog(
              email: email,
              selectedLanguage: _selectedLanguage,
              onClose: () {
                Navigator.of(context).pop(); // Close the reset flow dialog
                
                // Ensure we're on LoginPage
                if (mounted) {
                  // If we're not already on LoginPage, navigate to it
                  if (ModalRoute.of(context)?.settings.name != '/login') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(selectedLanguage: _selectedLanguage),
                        settings: const RouteSettings(name: '/login'),
                      ),
                    );
                  }
                }
                
                // Clear the form fields
                _usernameController.clear();
                _passwordController.clear();
              },
            ),
          );
        },
      ),
    );
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _showRateLimitError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Too many login attempts. Please try again in 15 minutes.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color darkenColor(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SplashPage(selectedLanguage: _selectedLanguage),
          ),
        );
        return false;
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          breakpoints: AppBreakpoints.screenBreakpoints,
          builder: (context, sizingInformation) {
            // Get responsive font sizes using our utility
            final handaBataFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 65,
              tablet: 85,
              desktop: 100,
            );

            final mobileFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 55,
              tablet: 75,
              desktop: 90,
            );

            // Get responsive padding
            final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 40,
              tablet: 60,
            );

            return Stack(
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600), // Limit width on tablets
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 80),
                            TextWithShadow(
                              text: 'Handa Bata',
                              fontSize: handaBataFontSize,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -20.0),
                              child: Column(
                                children: [
                                  TextWithShadow(
                                    text: 'Mobile',
                                    fontSize: mobileFontSize,
                                  ),
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
                            // Form section
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
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
                                  _buildButtons(sizingInformation),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Language selector
                Positioned(
                  top: ResponsiveUtils.valueByDevice(
                    context: context,
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                  right: ResponsiveUtils.valueByDevice(
                    context: context,
                    mobile: 25.0,
                    tablet: 30.0,
                    desktop: 35.0,
                  ),
                  child: _buildLanguageSelector(),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const LoadingWidget(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtons(SizingInformation sizingInformation) {
    final buttonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.8,
      tablet: 400, // Fixed width on tablet
    );

    final buttonHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 45,
      tablet: 55,
    );

    return Column(
      children: [
        CustomButton(
          text: LoginLocalization.translate('login_button', _selectedLanguage),
          color: const Color(0xFF351B61),
          textColor: Colors.white,
          onTap: _login,
          width: buttonWidth,
          height: buttonHeight,
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: LoginLocalization.translate('sign_up', _selectedLanguage),
          color: const Color(0xFFF1B33A),
          textColor: Colors.black,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationPage(
                  selectedLanguage: _selectedLanguage,
                ),
              ),
            );
          },
          width: buttonWidth,
          height: buttonHeight,
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        
        // Calculate icon size based on device type
        final iconSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 32.0,
          tablet: 36.0,
          desktop: 40.0,
        );
        
        // Calculate menu text size
        final menuTextSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 14.0,
          tablet: 16.0,
          desktop: 18.0,
        );

        return PopupMenuButton<String>(
          icon: SvgPicture.asset(
            'assets/icons/language_switcher.svg',
            width: iconSize,
            height: iconSize,
            color: Colors.white,
          ),
          padding: EdgeInsets.zero,
          offset: const Offset(0, 30),
          color: const Color(0xFF241242),
          onSelected: (String newValue) {
            _changeLanguage(newValue);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedLanguage == 'en' ? 'English' : 'Ingles',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'en') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'fil',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filipino',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'fil') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}