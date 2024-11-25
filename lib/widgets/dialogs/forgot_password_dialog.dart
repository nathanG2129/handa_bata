import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../widgets/buttons/button_3d.dart';
import '../../localization/forgot_password/localization.dart';
import '../../utils/responsive_utils.dart';
import '../../constants/breakpoints.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String selectedLanguage;
  final Function(String) onEmailSubmitted;
  final Color Function(Color, [double]) darkenColor;

  const ForgotPasswordDialog({
    super.key,
    required this.selectedLanguage,
    required this.onEmailSubmitted,
    required this.darkenColor,
  });

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleContinue() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ForgotPasswordLocalization.translate('pleaseEnterEmail', widget.selectedLanguage),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ForgotPasswordLocalization.translate('invalidEmail', widget.selectedLanguage),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onEmailSubmitted(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      breakpoints: AppBreakpoints.screenBreakpoints,
      builder: (context, sizingInformation) {
        // Get responsive dimensions
        final dialogWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: MediaQuery.of(context).size.width * 0.9,
          tablet: 450,
          desktop: 500,
        );

        final titleFontSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 28,
          tablet: 32,
          desktop: 36,
        );

        final buttonTextSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 18,
          tablet: 20,
          desktop: 22,
        );

        final contentPadding = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 20,
          tablet: 30,
          desktop: 40,
        );

        return WillPopScope(
          onWillPop: () async {
            await _handleClose();
            return true;
          },
          child: GestureDetector(
            onTap: _handleClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Dialog(
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    backgroundColor: const Color(0xFF351b61),
                    child: Container(
                      width: dialogWidth,
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(contentPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    ForgotPasswordLocalization.translate(
                                      'title',
                                      widget.selectedLanguage,
                                    ),
                                    style: GoogleFonts.vt323(
                                      fontSize: titleFontSize,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: contentPadding),
                                _buildEmailField(),
                              ],
                            ),
                          ),
                          _buildActionButtons(buttonTextSize),
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

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: ForgotPasswordLocalization.translate(
          'email_label',
          widget.selectedLanguage,
        ),
        hintText: ForgotPasswordLocalization.translate(
          'email_hint',
          widget.selectedLanguage,
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButtons(double fontSize) {
    final buttonHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 55,
      tablet: 60,
      desktop: 50,
    );

    final buttonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 120,
      tablet: 140,
      desktop: 160,
    );

    return Container(
      color: const Color(0xFF241242),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _handleClose,
            child: Text(
              ForgotPasswordLocalization.translate(
                'back_button',
                widget.selectedLanguage,
              ),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: fontSize,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Button3D(
            onPressed: _handleContinue,
            backgroundColor: const Color(0xFFF1B33A),
            borderColor: const Color(0xFF916D23),
            width: buttonWidth,
            height: buttonHeight,
            child: Text(
              ForgotPasswordLocalization.translate(
                'continue_button',
                widget.selectedLanguage,
              ),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 