import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../localization/reauth/localization.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../../widgets/loading_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReauthenticationDialog extends StatefulWidget {
  final String selectedLanguage;

  const ReauthenticationDialog({
    required this.selectedLanguage,
    super.key,
  });

  @override
  State<ReauthenticationDialog> createState() => _ReauthenticationDialogState();
}

class _ReauthenticationDialogState extends State<ReauthenticationDialog> with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _reauthenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception(ReauthLocalization.translate('no_user', widget.selectedLanguage));
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.reload();
      
      if (mounted) {
        await _animationController.reverse();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ReauthLocalization.translate('invalid_password', widget.selectedLanguage);
        _isLoading = false;
      });
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
            if (!_isLoading) {
              await _handleClose();
            }
            return false;
          },
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
                    child: SingleChildScrollView(
                      child: Container(
                        width: dialogWidth,
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: contentPadding,
                                left: contentPadding,
                                right: contentPadding,
                                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? contentPadding : contentPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      ReauthLocalization.translate('title', widget.selectedLanguage),
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
                                  Container(
                                    padding: EdgeInsets.all(contentPadding * 0.75),
                                    color: const Color(0xFFFFB74D),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: Colors.black,
                                          size: isMobileSmall ? 20 :
                                                isMobileLarge ? 22 :
                                                isMobileExtraLarge ? 24 : 26,
                                        ),
                                        SizedBox(width: contentPadding * 0.5),
                                        Expanded(
                                          child: Text(
                                            ReauthLocalization.translate('warning', widget.selectedLanguage),
                                            style: GoogleFonts.vt323(
                                              color: Colors.black,
                                              fontSize: isMobileSmall ? 14 :
                                                       isMobileLarge ? 15 :
                                                       isMobileExtraLarge ? 16 : 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: contentPadding),
                                  Text(
                                    ReauthLocalization.translate('password_label', widget.selectedLanguage),
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: isMobileSmall ? 14 :
                                               isMobileLarge ? 15 :
                                               isMobileExtraLarge ? 16 : 18,
                                    ),
                                  ),
                                  SizedBox(height: contentPadding * 0.5),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      errorText: _errorMessage,
                                      suffixIcon: IconButton(
                                        icon: SvgPicture.string(
                                          !_showPassword ? '''
                                            <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                                              <path d="M8 6h8v2H8V6zm-4 4V8h4v2H4zm-2 2v-2h2v2H2zm0 2v-2H0v2h2zm2 2H2v-2h2v2zm4 2H4v-2h4v2zm8 0v2H8v-2h8zm4-2v2h-4v-2h4zm2-2v2h-2v-2h2zm0-2h2v2h-2v-2zm-2-2h2v2h-2v-2zm0 0V8h-4v2h4zm-10 1h4v4h-4v-4z" fill="currentColor"/>
                                            </svg>
                                          ''' : '''
                                            <svg width="24" height="24" fill="white" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                                              <path d="M0 7h2v2H0V7zm4 4H2V9h2v2zm4 2v-2H4v2H2v2h2v-2h4zm8 0H8v2H6v2h2v-2h8v2h2v-2h-2v-2zm4-2h-4v2h4v2h2v-2h-2v-2zm2-2v2h-2V9h2zm0 0V7h2v2h-2z" fill="currentColor"/>
                                            </svg>
                                          ''',
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      border: const OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: GoogleFonts.vt323(
                                      color: Colors.black,
                                      fontSize: isMobileSmall ? 14 :
                                               isMobileLarge ? 15 :
                                               isMobileExtraLarge ? 16 : 18,
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
                                      ReauthLocalization.translate('cancel_button', widget.selectedLanguage),
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
                                      mobile: isMobileSmall ? 120 : 150,
                                      tablet: 160,
                                      desktop: 170,
                                    ),
                                    height: ResponsiveUtils.valueByDevice(
                                      context: context,
                                      mobile: isMobileSmall ? 55 : 55,
                                      tablet: 80,
                                      desktop: 55,
                                    ),
                                    child: Button3D(
                                      onPressed: _isLoading ? () {} : _reauthenticate,
                                      backgroundColor: const Color(0xFFF1B33A),
                                      borderColor: const Color(0xFF916D23),
                                      child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            ReauthLocalization.translate('delete_button', widget.selectedLanguage),
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
        );
      },
    );
  }
} 