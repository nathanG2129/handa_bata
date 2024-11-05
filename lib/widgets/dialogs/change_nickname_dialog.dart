import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../../localization/play/localization.dart';

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
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    PlayLocalization.translate('changeNickname', widget.selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: PlayLocalization.translate('newNickname', widget.selectedLanguage),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 75,
                        child: Button3D(
                          backgroundColor: const Color(0xFFc32929),
                          borderColor: widget.darkenColor(const Color(0xFFc32929), 0.2),
                          onPressed: _handleClose,
                          child: Text(
                            PlayLocalization.translate('cancel', widget.selectedLanguage),
                            style: GoogleFonts.vt323(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 75,
                        child: Button3D(
                          backgroundColor: const Color(0xFF4d278f),
                          borderColor: widget.darkenColor(const Color(0xFF4d278f), 0.2),
                          onPressed: _handleSave,
                          child: Text(
                            PlayLocalization.translate('save', widget.selectedLanguage),
                            style: GoogleFonts.vt323(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 