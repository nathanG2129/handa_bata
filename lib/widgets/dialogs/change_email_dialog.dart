import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/loading_widget.dart';
import '../../localization/email_change/localization.dart';

class ChangeEmailDialog extends StatefulWidget {
  final String currentEmail;
  final String selectedLanguage;
  final Function(String, String) onEmailChanged;
  final Color Function(Color, [double]) darkenColor;

  const ChangeEmailDialog({
    super.key,
    required this.currentEmail,
    required this.selectedLanguage,
    required this.onEmailChanged,
    required this.darkenColor,
  });

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
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
                fontSize: 18
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback get handleContinue => () {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Check for empty fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = EmailChangeLocalization.translate(
          'password_required',
          widget.selectedLanguage,
        );
      });
      return;
    }

    // Check email format
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = EmailChangeLocalization.translate(
          'invalid_email',
          widget.selectedLanguage,
        );
      });
      return;
    }

    // Check if new email is same as current
    if (_emailController.text == widget.currentEmail) {
      setState(() {
        _errorMessage = EmailChangeLocalization.translate(
          'same_email',
          widget.selectedLanguage,
        );
      });
      return;
    }

    setState(() => _isLoading = true);

    widget.onEmailChanged(_emailController.text, _passwordController.text)
      .then((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      })
      .catchError((error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error.toString();
          });
        }
      });
  };

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
            if (!_isLoading) {
              await _handleClose();
            }
            return false;
          },
          child: GestureDetector(
            onTap: _isLoading ? null : _handleClose,
            child: Stack(
              children: [
                BackdropFilter(
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
                        child: AbsorbPointer(
                          absorbing: _isLoading,
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
                                        EmailChangeLocalization.translate('title', widget.selectedLanguage),
                                        style: GoogleFonts.vt323(
                                          fontSize: isMobileSmall ? 20 :
                                                   isMobileLarge ? 22 :
                                                   isMobileExtraLarge ? 24 : titleFontSize,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (_errorMessage != null) ...[
                                      SizedBox(height: contentPadding),
                                      _buildErrorMessage(contentPadding),
                                    ],
                                    SizedBox(height: contentPadding),
                                    TextField(
                                      controller: _emailController,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobileSmall ? 14 :
                                                 isMobileLarge ? 15 :
                                                 isMobileExtraLarge ? 16 : 18,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: EmailChangeLocalization.translate('new_email', widget.selectedLanguage),
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
                                    ),
                                    SizedBox(height: contentPadding),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isMobileSmall ? 14 :
                                                 isMobileLarge ? 15 :
                                                 isMobileExtraLarge ? 16 : 18,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: EmailChangeLocalization.translate('current_password', widget.selectedLanguage),
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
                                      onPressed: _isLoading ? null : _handleClose,
                                      child: Text(
                                        EmailChangeLocalization.translate('cancel_button', widget.selectedLanguage),
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
                                        tablet: 150,
                                        desktop: 120,
                                      ),
                                      height: ResponsiveUtils.valueByDevice(
                                        context: context,
                                        mobile: isMobileSmall ? 45 : 50,
                                        tablet: 60,
                                        desktop: 50,
                                      ),
                                      child: Button3D(
                                        backgroundColor: const Color(0xFFF1B33A),
                                        borderColor: const Color(0xFF8B5A00),
                                        onPressed: _isLoading ? () {} : handleContinue,
                                        child: Text(
                                          EmailChangeLocalization.translate('change_button', widget.selectedLanguage),
                                          style: GoogleFonts.vt323(
                                            color: Colors.black,
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
} 