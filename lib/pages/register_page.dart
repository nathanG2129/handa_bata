import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/email_verification_dialog.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../helpers/validation_helpers.dart';
import '../helpers/widget_helpers.dart';
import '../helpers/date_helpers.dart';
import '../widgets/privacy_policy_error.dart';
import '../styles/input_styles.dart';
import '../widgets/buttons/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '../localization/register/localization.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../constants/breakpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationPage extends StatefulWidget {
  final String selectedLanguage; // Add this line
  const RegistrationPage({super.key, required this.selectedLanguage});

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

  String _selectedLanguage = 'en'; // Add language selection

  bool _isRegistering = false; // Add state variable

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String? role = await AuthService().getUserRole(currentUser.uid);
        
        // If user is already registered (not a guest), redirect to main page
        if (role != 'guest') {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainPage(selectedLanguage: _selectedLanguage),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _register() async {
    setState(() {
      _showPrivacyPolicyError = !_isPrivacyPolicyAccepted;
      _isRegistering = true;
    });

    if (_formKey.currentState!.validate() && _isPrivacyPolicyAccepted) {
      try {
        // Check if username is taken first
        bool isUsernameTaken = await AuthService().isUsernameTaken(_usernameController.text);
        
        if (isUsernameTaken) {
          setState(() => _isRegistering = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  RegisterLocalization.translate('username_taken', _selectedLanguage),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _isRegistering = false);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => EmailVerificationDialog(
              email: _emailController.text,
              selectedLanguage: _selectedLanguage,
              username: _usernameController.text,
              password: _passwordController.text,
              birthday: _birthdayController.text,
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        }
      } catch (e) {
        setState(() => _isRegistering = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isRegistering = false);
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<bool> _validateRegistrationData() async {
    if (!_formKey.currentState!.validate()) return false;
    if (!_isPrivacyPolicyAccepted) {
      setState(() => _showPrivacyPolicyError = true);
      return false;
    }
    return true;
  }

  Future<bool> _checkRateLimit() async {
    // Implement rate limiting logic
    return true;
  }

  void _handleRegistrationError(dynamic error) {
    setState(() => _isRegistering = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration error: $error')),
    );
  }

  void _cleanupFailedRegistration() {
    setState(() => _isRegistering = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBuilder(
        breakpoints: AppBreakpoints.screenBreakpoints,
        builder: (context, sizingInformation) {
          // Get responsive dimensions
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

          final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
            context: context,
            mobile: 40,
            tablet: 60,
          );

          return Stack(
            children: [
              // Background
              SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              
              // Main Content
              Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 40,
                      ),
                      child: Column(
                        children: [
                          // Title Section
                          _buildTitleSection(handaBataFontSize, mobileFontSize),
                          
                          // Form Section
                          _buildForm(sizingInformation),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Language Selector
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

              // Loading Overlay
              if (_isRegistering)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(double handaBataFontSize, double mobileFontSize) {
    return Column(
      children: [
        TextWithShadow(text: 'Handa Bata', fontSize: handaBataFontSize),
        Transform.translate(
          offset: const Offset(0, -20.0),
          child: Column(
            children: [
              TextWithShadow(text: 'Mobile', fontSize: mobileFontSize),
              const SizedBox(height: 0),
              Text(
                RegisterLocalization.translate('title', _selectedLanguage),
                style: GoogleFonts.vt323(
                  fontSize: 30,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
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
      ],
    );
  }

  Widget _buildForm(SizingInformation sizingInformation) {
    final buttonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.8,
      tablet: 400,
    );

    final buttonHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 45,
      tablet: 55,
    );

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          _buildInputFields(),
          const SizedBox(height: 20),
          _buildButtons(buttonWidth, buttonHeight),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: InputStyles.inputDecoration(
            RegisterLocalization.translate('username', _selectedLanguage),
          ),
          style: const TextStyle(color: Colors.white),
          validator: validateUsername,
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
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final iconSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 32.0,
          tablet: 36.0,
          desktop: 40.0,
        );
        
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

  Widget _buildButtons(double buttonWidth, double buttonHeight) {
    return Column(
      children: [
        CustomButton(
          text: RegisterLocalization.translate('register_button', _selectedLanguage),
          color: const Color(0xFF351B61),
          textColor: Colors.white,
          onTap: _register,
          width: buttonWidth,
          height: buttonHeight,
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: RegisterLocalization.translate('login_instead', _selectedLanguage),
          color: Colors.white,
          textColor: Colors.black,
          onTap: () {
            Navigator.pop(context);
          },
          width: buttonWidth,
          height: buttonHeight,
        ),
      ],
    );
  }
}