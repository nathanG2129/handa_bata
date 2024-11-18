import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../../localization/play/localization.dart';

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
            PlayLocalization.translate('passwordsDoNotMatch', widget.selectedLanguage),
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
                          PlayLocalization.translate('changePassword', widget.selectedLanguage),
                          style: GoogleFonts.vt323(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        _currentPasswordController,
                        'currentPassword',
                        _obscureCurrentPassword,
                        () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        _newPasswordController,
                        'newPassword',
                        _obscureNewPassword,
                        () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        _confirmPasswordController,
                        'confirmNewPassword',
                        _obscureConfirmPassword,
                        () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
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
                          PlayLocalization.translate('cancel', widget.selectedLanguage),
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Button3D(
                        onPressed: _handleSave,
                        backgroundColor: const Color(0xFFF1B33A),
                        borderColor: const Color(0xFF916D23),
                        width: 120,
                        height: 40,
                        child: Text(
                          PlayLocalization.translate('save', widget.selectedLanguage),
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
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String labelKey,
    bool obscureText,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: PlayLocalization.translate(labelKey, widget.selectedLanguage),
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