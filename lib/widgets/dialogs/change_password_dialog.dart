import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../../localization/password_change/localization.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String selectedLanguage;
  final Function(String, String) onPasswordChanged;
  final Color Function(Color, [double]) darkenColor;

  const ChangePasswordDialog({
    super.key,
    required this.selectedLanguage,
    required this.onPasswordChanged,
    required this.darkenColor,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PasswordChangeLocalization.translate('passwords_not_match', widget.selectedLanguage),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onPasswordChanged(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
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
          mobile: 24,
          tablet: 28,
          desktop: 32,
        );

        final buttonTextSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 16,
          tablet: 18,
          desktop: 20,
        );

        final contentPadding = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 16,
          tablet: 20,
          desktop: 24,
        );

        // Check for specific mobile breakpoints
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobileSmall = screenWidth <= 375;
        final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375;
        final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414;

        return WillPopScope(
          onWillPop: () async {
            await _handleClose();
            return false;
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
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
                                PasswordChangeLocalization.translate('title', widget.selectedLanguage),
                                style: GoogleFonts.vt323(
                                  fontSize: isMobileSmall ? 20 :
                                           isMobileLarge ? 22 :
                                           isMobileExtraLarge ? 24 : titleFontSize,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: contentPadding),
                            _buildPasswordField(
                              _currentPasswordController,
                              'current_password',
                              _obscureCurrentPassword,
                              () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                              isMobileSmall ? 14 :
                              isMobileLarge ? 15 :
                              isMobileExtraLarge ? 16 : 18,
                            ),
                            SizedBox(height: contentPadding * 0.75),
                            _buildPasswordField(
                              _newPasswordController,
                              'new_password',
                              _obscureNewPassword,
                              () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                              isMobileSmall ? 14 :
                              isMobileLarge ? 15 :
                              isMobileExtraLarge ? 16 : 18,
                            ),
                            SizedBox(height: contentPadding * 0.75),
                            _buildPasswordField(
                              _confirmPasswordController,
                              'confirm_password',
                              _obscureConfirmPassword,
                              () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              isMobileSmall ? 14 :
                              isMobileLarge ? 15 :
                              isMobileExtraLarge ? 16 : 18,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: const Color(0xFF241242),
                        padding: EdgeInsets.symmetric(
                          horizontal: contentPadding,
                          vertical: contentPadding * 0.75,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _handleClose,
                              child: Text(
                                PasswordChangeLocalization.translate('cancel_button', widget.selectedLanguage),
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: buttonTextSize,
                                ),
                              ),
                            ),
                            SizedBox(width: contentPadding * 0.75),
                            SizedBox(
                              width: ResponsiveUtils.valueByDevice(
                                context: context,
                                mobile: isMobileSmall ? 90 : 100,
                                tablet: 110,
                                desktop: 120,
                              ),
                              height: ResponsiveUtils.valueByDevice(
                                context: context,
                                mobile: isMobileSmall ? 45 : 50,
                                tablet: 60,
                                desktop: 55,
                              ),
                              child: Button3D(
                                backgroundColor: const Color(0xFFF1B33A),
                                borderColor: const Color(0xFF916D23),
                                onPressed: _handleSave,
                                child: Text(
                                  PasswordChangeLocalization.translate('save_button', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(
                                    color: Colors.white,
                                    fontSize: buttonTextSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String labelKey,
    bool obscureText,
    VoidCallback onToggle,
    double fontSize,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
      ),
      decoration: InputDecoration(
        labelText: PasswordChangeLocalization.translate(labelKey, widget.selectedLanguage),
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
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
} 