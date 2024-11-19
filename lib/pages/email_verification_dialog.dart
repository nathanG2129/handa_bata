import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/auth_service.dart';
import '../pages/main/main_page.dart';
import '../widgets/buttons/button_3d.dart';
import '../widgets/loading_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    setState(() => _isLoading = true);

    try {
      if (widget.isEmailChange) {
        // Handle email change verification
        if (widget.onVerify != null) {
          await widget.onVerify!(_otpController.text);
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        // Handle registration verification
        final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
        final result = await functions
            .httpsCallable('verifyOTP')
            .call({
              'email': widget.email,
              'otp': _otpController.text
            });

        if (result.data['success']) {
          try {
            // Check if this is a guest conversion
            User? currentUser = FirebaseAuth.instance.currentUser;
            
            if (currentUser != null) {
              String? role = await _authService.getUserRole(currentUser.uid);
              
              if (role == 'guest') {
                print('🔄 Completing guest conversion...');
                // Complete the conversion process
                await _authService.completeGuestConversion();
                print('✅ Guest conversion completed');
              } else {
                // Create new user account
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
              }
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
            // Handle specific errors
            if (e.toString().contains('Username is already taken')) {
              throw Exception('This username is no longer available. Please go back and choose another.');
            }
            rethrow;
          }
        } else {
          throw Exception('Invalid verification code');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _sendOTP() async {
    try {
      setState(() => _canResend = false); // Disable resend button immediately
      
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      await functions
          .httpsCallable(widget.isEmailChange ? 'sendEmailChangeOTP' : 'sendVerificationOTP')
          .call({'email': widget.email});
      
      // Reset timer after successful resend
      setState(() {
        _timeLeft = 300;
        _startTimer();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
      // Re-enable resend button on error
      setState(() => _canResend = true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            width: ResponsiveValue<double>(
                              context,
                              defaultValue: 400,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 300),
                                const Condition.largerThan(name: TABLET, value: 400),
                              ],
                            ).value,
                            margin: const EdgeInsets.all(20),
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
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextWithShadow(
                                      text: widget.isEmailChange ? 'Verify New Email' : 'Verify Email',
                                      fontSize: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Enter the code we sent to your email.',
                                      style: GoogleFonts.rubik(
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 200,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 150),
                                          const Condition.largerThan(name: TABLET, value: 250),
                                        ],
                                      ).value,
                                      child: TextField(
                                        controller: _otpController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.vt323(
                                          fontSize: 32,
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
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Code expires in ${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                                      style: GoogleFonts.rubik(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Button3D(
                                      onPressed: _verifyOTP,
                                      height: 45,
                                      child: Text(
                                        widget.isEmailChange ? 'Verify' : 'Sign Up',
                                        style: GoogleFonts.vt323(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _canResend ? _sendOTP : null,
                                      child: Text(
                                        "Didn't receive the code? Request a new one",
                                        style: GoogleFonts.rubik(
                                          fontSize: 16,
                                          color: _canResend ? const Color(0xFF3A1A5F) : Colors.grey,
                                          decoration: TextDecoration.underline,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
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
  }
} 