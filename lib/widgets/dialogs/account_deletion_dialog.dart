import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/loading_widget.dart';
import '../../localization/account_deletion/localization.dart';

class AccountDeletionDialog extends StatefulWidget {
  final String selectedLanguage;
  final String userRole;

  const AccountDeletionDialog({
    required this.selectedLanguage,
    required this.userRole,
    super.key,
  });

  static Future<bool> show(BuildContext context, String selectedLanguage, String userRole) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AccountDeletionDialog(
          selectedLanguage: selectedLanguage,
          userRole: userRole,
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

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
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _handleDelete() async {
    try {
      await _animationController.reverse();
      if (mounted) {
        // Just return true to let parent handle deletion
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              GestureDetector(
                onTap: _isLoading ? null : _handleClose,
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
                                        AccountDeletionLocalization.translate('title', widget.selectedLanguage),
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
                                              widget.userRole == 'guest'
                                                ? AccountDeletionLocalization.translate('guest_warning', widget.selectedLanguage)
                                                : AccountDeletionLocalization.translate('user_warning', widget.selectedLanguage),
                                              style: GoogleFonts.vt323(
                                                color: Colors.black,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                      onPressed: _handleClose,
                                      child: Text(
                                        AccountDeletionLocalization.translate('cancel_button', widget.selectedLanguage),
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
                                        mobile: isMobileSmall ? 55 : 55,
                                        tablet: 60,
                                        desktop: 52,
                                      ),
                                      child: Button3D(
                                        onPressed: _handleDelete,
                                        backgroundColor: const Color(0xFFF1B33A),
                                        borderColor: const Color(0xFF916D23),
                                        child: Text(
                                          AccountDeletionLocalization.translate('delete_button', widget.selectedLanguage),
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