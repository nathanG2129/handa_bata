import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/auth_service.dart';
import '../pages/main/main_page.dart';
import 'dart:ui';
import '../widgets/buttons/button_3d.dart';
import '../widgets/loading_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String selectedLanguage;
  final String username;
  final String password;
  final String birthday;
  final VoidCallback onClose;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.selectedLanguage,
    required this.username,
    required this.password,
    required this.birthday,
    required this.onClose,
  });

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
    _sendOTP();
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

  Future<void> _sendOTP() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      await functions
          .httpsCallable('sendVerificationOTP')
          .call({'email': widget.email});
    } catch (e) {
      if (!mounted) return;
      // Add logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
    }
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
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
      final result = await functions
          .httpsCallable('verifyOTP')
          .call({
            'email': widget.email,
            'otp': _otpController.text
          });

      if (result.data['success']) {
        User? user;
        
        // Check if this is a guest conversion
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isGuestConversion = prefs.containsKey('pending_conversion');

        if (isGuestConversion) {
          user = await _authService.completeGuestConversion();
        } else {
          user = await _authService.registerWithEmailAndPassword(
            widget.email,
            widget.password,
            widget.username,
            '',
            widget.birthday,
            role: 'user',
          );
        }

        if (user != null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(selectedLanguage: widget.selectedLanguage),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
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
                                    const TextWithShadow(
                                      text: 'Verify Email',
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
                                        'Sign Up',
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