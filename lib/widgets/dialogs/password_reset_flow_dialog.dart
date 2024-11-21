import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../widgets/buttons/button_3d.dart';
import '../../localization/password_reset_flow/localization.dart';
import '../../services/auth_service.dart';

class PasswordResetFlowDialog extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback onClose;
  final String email;

  const PasswordResetFlowDialog({
    super.key,
    required this.email,
    required this.selectedLanguage,
    required this.onClose,
  });

  @override
  PasswordResetFlowDialogState createState() => PasswordResetFlowDialogState();
}

class PasswordResetFlowDialogState extends State<PasswordResetFlowDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  int _timeLeft = 300;
  bool _isLoading = false;
  bool _otpVerified = false;
  bool _resetComplete = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _startTimer();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    try {
      setState(() => _isLoading = true);
      await _authService.sendPasswordResetOTP(widget.email);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showError(PasswordResetFlowLocalization.translate('pleaseEnterOTP', widget.selectedLanguage));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPasswordResetOTP(widget.email, _otpController.text);
      setState(() => _otpVerified = true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      _showError(PasswordResetFlowLocalization.translate('pleaseEnterNewPassword', widget.selectedLanguage));
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(PasswordResetFlowLocalization.translate('passwordsDoNotMatch', widget.selectedLanguage));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(widget.email, _newPasswordController.text);
      setState(() => _resetComplete = true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildOTPVerification() {
    return Column(
      children: [
        TextWithShadow(
          text: PasswordResetFlowLocalization.translate('title', widget.selectedLanguage),
          fontSize: 48,
        ),
        const SizedBox(height: 12),
        Text(
          PasswordResetFlowLocalization.translate('enter_otp', widget.selectedLanguage),
          style: GoogleFonts.rubik(
            fontSize: 18,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.email,
          style: GoogleFonts.rubik(
            fontSize: 16,
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
          '${PasswordResetFlowLocalization.translate('code_expires', widget.selectedLanguage)} ${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
          style: GoogleFonts.rubik(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Button3D(
          onPressed: _verifyOTP,
          backgroundColor: const Color(0xFFF1B33A),
          borderColor: const Color(0xFF916D23),
          height: 45,
          child: Text(
            PasswordResetFlowLocalization.translate('verify_button', widget.selectedLanguage),
            style: GoogleFonts.vt323(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPassword() {
    return Column(
      children: [
        TextWithShadow(
          text: PasswordResetFlowLocalization.translate('title', widget.selectedLanguage),
          fontSize: 48,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          style: GoogleFonts.rubik(
            fontSize: 16,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            labelText: PasswordResetFlowLocalization.translate('new_password', widget.selectedLanguage),
            labelStyle: const TextStyle(color: Colors.black87),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF3A1A5F), width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: GoogleFonts.rubik(
            fontSize: 16,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            labelText: PasswordResetFlowLocalization.translate('confirm_password', widget.selectedLanguage),
            labelStyle: const TextStyle(color: Colors.black87),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Color(0xFF3A1A5F), width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.black54,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Button3D(
          onPressed: _resetPassword,
          backgroundColor: const Color(0xFFF1B33A),
          borderColor: const Color(0xFF916D23),
          height: 45,
          child: Text(
            PasswordResetFlowLocalization.translate('reset_button', widget.selectedLanguage),
            style: GoogleFonts.vt323(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Text(
          PasswordResetFlowLocalization.translate('success_message', widget.selectedLanguage),
          style: GoogleFonts.vt323(
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Button3D(
          onPressed: widget.onClose,
          backgroundColor: const Color(0xFFF1B33A),
          borderColor: const Color(0xFF916D23),
          width: 120,
          height: 40,
          child: Text(
            PasswordResetFlowLocalization.translate('login_button', widget.selectedLanguage),
            style: GoogleFonts.vt323(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return true;
      },
      child: GestureDetector(
        onTap: widget.onClose,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: GestureDetector(
              onTap: () {},
              child: Center(
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_otpVerified && !_resetComplete)
                                  _buildOTPVerification()
                                else if (_otpVerified && !_resetComplete)
                                  _buildNewPassword()
                                else
                                  _buildSuccess(),
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
      ),
    );
  }
} 