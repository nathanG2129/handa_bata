import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../../localization/play/localization.dart';
import '../../utils/responsive_utils.dart';

class ChangeNicknameDialog extends StatefulWidget {
  final String currentNickname;
  final String selectedLanguage;
  final Function(String) onNicknameChanged;
  final Color Function(Color, [double]) darkenColor;

  const ChangeNicknameDialog({
    super.key,
    required this.currentNickname,
    required this.selectedLanguage,
    required this.onNicknameChanged,
    required this.darkenColor,
  });

  @override
  State<ChangeNicknameDialog> createState() => _ChangeNicknameDialogState();
}

class _ChangeNicknameDialogState extends State<ChangeNicknameDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onNicknameChanged(_controller.text);
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
          mobile: 18,
          tablet: 20,
          desktop: 22,
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
                                PlayLocalization.translate('changeNickname', widget.selectedLanguage),
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
                            TextField(
                              controller: _controller,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobileSmall ? 14 :
                                         isMobileLarge ? 15 :
                                         isMobileExtraLarge ? 16 : 18,
                              ),
                              decoration: InputDecoration(
                                labelText: PlayLocalization.translate('', widget.selectedLanguage),
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
                              onPressed: _handleClose,
                              child: Text(
                                PlayLocalization.translate('cancel', widget.selectedLanguage),
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: buttonTextSize,
                                ),
                              ),
                            ),
                            SizedBox(width: contentPadding * 0.75),
                            SizedBox(
                              child: Button3D(
                                backgroundColor: const Color(0xFFF1B33A),
                                borderColor: const Color(0xFF8B5A00),
                                onPressed: _handleSave,
                                child: Text(
                                  PlayLocalization.translate('save', widget.selectedLanguage),
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
        );
      },
    );
  }
} 