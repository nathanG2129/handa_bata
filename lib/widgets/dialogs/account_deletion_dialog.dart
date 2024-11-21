import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
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
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: GestureDetector(
        onTap: () => _handleClose(),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              AccountDeletionLocalization.translate('title', widget.selectedLanguage),
                              style: GoogleFonts.vt323(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                    widget.userRole == 'guest'
                                      ? AccountDeletionLocalization.translate('guest_warning', widget.selectedLanguage)
                                      : AccountDeletionLocalization.translate('user_warning', widget.selectedLanguage),
                                    style: GoogleFonts.vt323(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Container(
                      color: const Color(0xFF241242),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _handleClose,
                            child: Text(
                              AccountDeletionLocalization.translate('cancel_button', widget.selectedLanguage),
                              style: GoogleFonts.vt323(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Button3D(
                            onPressed: _handleDelete,
                            backgroundColor: const Color(0xFFF1B33A),
                            borderColor: const Color(0xFF916D23),
                            width: 120,
                            height: 40,
                            child: Text(
                              AccountDeletionLocalization.translate('delete_button', widget.selectedLanguage),
                              style: GoogleFonts.vt323(
                                color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
} 