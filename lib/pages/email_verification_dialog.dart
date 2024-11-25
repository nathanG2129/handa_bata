import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../services/auth_service.dart';
import '../pages/main/main_page.dart';
import '../widgets/buttons/button_3d.dart';
import '../widgets/loading_widget.dart';
import '../utils/responsive_utils.dart';
import '../constants/breakpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/email_verification/localization.dart';
import '../services/user_profile_service.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String selectedLanguage;
  final VoidCallback onClose;
  
  // Optional parameters for registration
  final String? username;
  final String? password;
  final String? birthday;
  
  // Optional parameters for email change
  final bool isEmailChange;
  final Function(String)? onVerify;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.selectedLanguage,
    required this.onClose,
    // Make these optional but required for registration
    this.username,
    this.password,
    this.birthday,
    // Add email change parameters
    this.isEmailChange = false,
    this.onVerify,
  }) : assert(
    (!isEmailChange && username != null && password != null && birthday != null) ||
    (isEmailChange && onVerify != null),
    'For registration, provide username, password, and birthday. For email change, provide onVerify.'
  );

  @override
  EmailVerificationDialogState createState() => EmailVerificationDialogState();
}

class EmailVerificationDialogState extends State<EmailVerificationDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  int _timeLeft = 300;
  bool _canResend = false;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isEmailChange) {
      _sendOTP();
    }
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _startTimer();
        } else {
          _canResend = true;
        }
      });
    });
  }

  Future<void> _verifyOTP() async {
    setState(() => _errorMessage = null);

    setState(() => _isLoading = true);

    try {
      if (widget.isEmailChange) {
        // Handle email change verification
        if (widget.onVerify != null) {
          try {
            await widget.onVerify!(_otpController.text);
            if (!mounted) return;
            Navigator.of(context).pop();
          } catch (e) {
            setState(() {
              _isLoading = false;
              if (e.toString().contains('email-already-in-use')) {
                _errorMessage = EmailVerificationLocalization.translate(
                  'email_already_in_use',
                  widget.selectedLanguage,
                );
              } else {
                _errorMessage = EmailVerificationLocalization.translate(
                  'email_change_failed',
                  widget.selectedLanguage,
                );
              }
            });
          }
        }
      } else {
        // Verify OTP first
        final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
        final result = await functions
            .httpsCallable('verifyOTP')
            .call({
              'email': widget.email,
              'otp': _otpController.text
            });

        if (result.data['success']) {
          try {
            // Check if this is a guest conversion or new account
            User? currentUser = FirebaseAuth.instance.currentUser;
            
            if (currentUser != null) {
              // Guest conversion flow
              String? role = await _authService.getUserRole(currentUser.uid);
              
              if (role == 'guest') {
                print('🔄 Starting guest conversion process...');
                // First prepare the conversion
                await _authService.convertGuestToUser(
                  widget.email,
                  widget.password!,
                  widget.username!,
                  '',  // Empty nickname since we'll keep the existing one
                  widget.birthday!,
                );
                print('✅ Guest conversion prepared');

                // Now complete the conversion
                print('🔄 Completing guest conversion...');
                await _authService.completeGuestConversion();
                print('✅ Guest conversion completed');
              }
            } else {
              // Create new user account
              print('👤 Creating new user account...');
              final user = await _authService.registerWithEmailAndPassword(
                widget.email,
                widget.password!,
                widget.username!,
                '',  // Empty nickname, will be generated
                widget.birthday!,
              );
              
              if (user == null) {
                throw Exception('Failed to create account');
              }

              // Initialize profile using UserProfileService
              final userProfileService = UserProfileService();
              await userProfileService.batchUpdateProfile({
                'username': widget.username,
                'email': widget.email,
                'birthday': widget.birthday,
              });

              print('✅ New user account created successfully');
            }

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(selectedLanguage: widget.selectedLanguage),
              ),
            );
          } catch (e) {
            print('❌ Error during account creation/conversion: $e');
            if (e.toString().contains('Username is already taken')) {
              setState(() {
                _errorMessage = EmailVerificationLocalization.translate(
                  'username_taken',
                  widget.selectedLanguage,
                );
              });
              return;
            }
            if (e.toString().contains('No pending conversion')) {
              setState(() {
                _errorMessage = EmailVerificationLocalization.translate(
                  'conversion_failed',
                  widget.selectedLanguage,
                );
              });
              return;
            }
            setState(() {
              _errorMessage = EmailVerificationLocalization.translate(
                'verification_failed',
                widget.selectedLanguage,
              );
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = EmailVerificationLocalization.translate(
              'invalid_code',
              widget.selectedLanguage,
            );
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = widget.isEmailChange
          ? EmailVerificationLocalization.translate(
              'email_verification_failed',
              widget.selectedLanguage,
            )
          : EmailVerificationLocalization.translate(
              'verification_failed',
              widget.selectedLanguage,
            );
      });
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _sendOTP() async {
    try {
      setState(() => _canResend = false);
      
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      await functions
          .httpsCallable(widget.isEmailChange ? 'sendEmailChangeOTP' : 'sendVerificationOTP')
          .call({'email': widget.email});
      
      setState(() {
        _timeLeft = 300;
        _startTimer();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _canResend = true;
        _errorMessage = EmailVerificationLocalization.translate(
          'send_code_error',
          widget.selectedLanguage,
        );
      });
    }
  }

  Widget _buildErrorMessage(double contentPadding) {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(contentPadding * 0.75),
      color: const Color(0xFFFFB74D),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.black,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.vt323(
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      breakpoints: AppBreakpoints.screenBreakpoints,
      builder: (context, sizingInformation) {
        final dialogWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: MediaQuery.of(context).size.width * 0.9,
          tablet: 450,
          desktop: 500,
        );

        final titleFontSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 36,
          tablet: 48,
          desktop: 56,
        );

        final textFontSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 16,
          tablet: 18,
          desktop: 20,
        );

        final otpFieldWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 150,
          tablet: 200,
          desktop: 250,
        );

        final dialogPadding = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 20,
          tablet: 24,
          desktop: 28,
        );

        return WillPopScope(
          onWillPop: () async {
            if (!_isLoading) {
              await _closeDialog();
            }
            return false;
          },
          child: GestureDetector(
            onTap: _isLoading ? null : _closeDialog,
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent dialog from closing when clicking inside
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: AbsorbPointer(
                            absorbing: _isLoading,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: dialogWidth,
                                margin: EdgeInsets.all(dialogPadding),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.all(dialogPadding),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextWithShadow(
                                          text: widget.isEmailChange 
                                            ? EmailVerificationLocalization.translate('title_change_email', widget.selectedLanguage)
                                            : EmailVerificationLocalization.translate('title', widget.selectedLanguage),
                                          fontSize: titleFontSize,
                                        ),
                                        if (_errorMessage != null) ...[
                                          const SizedBox(height: 12),
                                          _buildErrorMessage(dialogPadding),
                                        ],
                                        const SizedBox(height: 12),
                                        Text(
                                          EmailVerificationLocalization.translate('enter_code', widget.selectedLanguage),
                                          style: GoogleFonts.rubik(
                                            fontSize: textFontSize,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildOTPField(otpFieldWidth, textFontSize),
                                        const SizedBox(height: 16),
                                        _buildTimerText(textFontSize),
                                        const SizedBox(height: 24),
                                        _buildButtons(textFontSize),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const LoadingWidget(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOTPField(double width, double fontSize) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: _otpController,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: GoogleFonts.vt323(
          fontSize: fontSize * 2,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF3A1A5F), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerText(double fontSize) {
    return Text(
      '${EmailVerificationLocalization.translate('code_expires', widget.selectedLanguage)} ${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
      style: GoogleFonts.rubik(
        fontSize: fontSize,
        color: Colors.black,
      ),
    );
  }

  Widget _buildButtons(double fontSize) {
    final buttonHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 55,
      tablet: 60,
      desktop: 65,
    );

    return Column(
      children: [
        Button3D(
          onPressed: _verifyOTP,
          backgroundColor: const Color(0xFFF1B33A),
          borderColor: const Color(0xFF916D23),
          height: buttonHeight,
          child: Text(
            widget.isEmailChange 
              ? EmailVerificationLocalization.translate('verify_button', widget.selectedLanguage)
              : EmailVerificationLocalization.translate('signup_button', widget.selectedLanguage),
            style: GoogleFonts.vt323(
              fontSize: fontSize * 1.2,
              color: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: _canResend ? _sendOTP : null,
          child: Text(
            EmailVerificationLocalization.translate('resend_code', widget.selectedLanguage),
            style: GoogleFonts.rubik(
              fontSize: fontSize,
              color: _canResend ? const Color(0xFF3A1A5F) : Colors.grey,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
} 