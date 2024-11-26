import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../widgets/buttons/button_3d.dart';
import '../../localization/password_reset_flow/localization.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/breakpoints.dart';
import '../../widgets/loading_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  String? _errorMessage;

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
    // Clear previous error
    setState(() => _errorMessage = null);

    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = PasswordResetFlowLocalization.translate(
          'please_enter_otp',
          widget.selectedLanguage,
        );
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPasswordResetOTP(widget.email, _otpController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpVerified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = PasswordResetFlowLocalization.translate(
            'invalid_otp',
            widget.selectedLanguage,
          );
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = PasswordResetFlowLocalization.translate(
          'please_enter_password',
          widget.selectedLanguage,
        );
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = PasswordResetFlowLocalization.translate(
          'passwords_not_match',
          widget.selectedLanguage,
        );
      });
      return;
    }

    // Check password requirements
    String password = _newPasswordController.text;
    if (password.length < 8 || 
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() {
        _errorMessage = PasswordResetFlowLocalization.translate(
          'password_requirements',
          widget.selectedLanguage,
        );
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(widget.email, _newPasswordController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetComplete = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
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

  Widget _buildOTPVerification(double contentPadding) {
    final otpFieldWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 150,
      tablet: 200,
      desktop: 250,
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

    return Column(
      children: [
        TextWithShadow(
          text: PasswordResetFlowLocalization.translate('title', widget.selectedLanguage),
          fontSize: titleFontSize,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(contentPadding),
        ],
        const SizedBox(height: 12),
        Text(
          PasswordResetFlowLocalization.translate('enter_otp', widget.selectedLanguage),
          style: GoogleFonts.rubik(
            fontSize: textFontSize,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.email,
          style: GoogleFonts.rubik(
            fontSize: textFontSize - 2,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: otpFieldWidth,
          child: TextField(
            controller: _otpController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: GoogleFonts.vt323(
              fontSize: textFontSize * 2,
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
            fontSize: textFontSize,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          onPressed: _verifyOTP,
          text: PasswordResetFlowLocalization.translate('verify_button', widget.selectedLanguage),
        ),
      ],
    );
  }

  Widget _buildNewPassword() {
    final textFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );

    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 36,
      tablet: 48,
      desktop: 56,
    );

    return Column(
      children: [
        TextWithShadow(
          text: PasswordResetFlowLocalization.translate('title', widget.selectedLanguage),
          fontSize: titleFontSize,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 24),
          _buildErrorMessage(24),
        ],
        const SizedBox(height: 24),
        _buildPasswordField(
          controller: _newPasswordController,
          obscure: _obscureNewPassword,
          onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          label: 'new_password',
          fontSize: textFontSize,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          obscure: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          label: 'confirm_password',
          fontSize: textFontSize,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          onPressed: _resetPassword,
          text: PasswordResetFlowLocalization.translate('reset_button', widget.selectedLanguage),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleVisibility,
    required String label,
    required double fontSize,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.rubik(
        fontSize: fontSize,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: PasswordResetFlowLocalization.translate(label, widget.selectedLanguage),
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
          icon: SvgPicture.string(
            obscure ? '''
              <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <path d="M8 6h8v2H8V6zm-4 4V8h4v2H4zm-2 2v-2h2v2H2zm0 2v-2H0v2h2zm2 2H2v-2h2v2zm4 2H4v-2h4v2zm8 0v2H8v-2h8zm4-2v2h-4v-2h4zm2-2v2h-2v-2h2zm0-2h2v2h-2v-2zm-2-2h2v2h-2v-2zm0 0V8h-4v2h4zm-10 1h4v4h-4v-4z" fill="currentColor"/>
              </svg>
            ''' : '''
              <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <path d="M0 7h2v2H0V7zm4 4H2V9h2v2zm4 2v-2H4v2H2v2h2v-2h4zm8 0H8v2H6v2h2v-2h8v2h2v-2h-2v-2zm4-2h-4v2h4v2h2v-2h-2v-2zm2-2v2h-2V9h2zm0 0V7h2v2h-2z" fill="currentColor"/>
              </svg>
            ''',
            color: Colors.black54,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    // final buttonHeight = ResponsiveUtils.valueByDevice<double>(
    //   context: context,
    //   mobile: 55,
    //   tablet: 60,
    //   desktop: 65,
    // );

    final buttonFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );

    return Button3D(
      onPressed: onPressed,
      backgroundColor: const Color(0xFFF1B33A),
      borderColor: const Color(0xFF916D23),
      child: Text(
        text,
        style: GoogleFonts.vt323(
          fontSize: buttonFontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    final textFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );

    return Column(
      children: [
        Text(
          PasswordResetFlowLocalization.translate('success_message', widget.selectedLanguage),
          style: GoogleFonts.vt323(
            fontSize: textFontSize,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          onPressed: widget.onClose,
          text: PasswordResetFlowLocalization.translate('login_button', widget.selectedLanguage),
        ),
      ],
    );
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

        final dialogPadding = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 20,
          tablet: 24,
          desktop: 28,
        );

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
                      child: Stack(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Container(
                              width: dialogWidth,
                              margin: EdgeInsets.all(dialogPadding),
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
                                  padding: EdgeInsets.all(dialogPadding),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_otpVerified && !_resetComplete)
                                        _buildOTPVerification(dialogPadding)
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
                          if (_isLoading)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const LoadingWidget(),
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
        );
      },
    );
  }
} 