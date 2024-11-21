import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  VoidCallback get handleContinue => () {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          EmailChangeLocalization.translate('pleaseCompleteFields', widget.selectedLanguage)
        )),
      );
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
          setState(() => _isLoading = false);
        }
      });
  };

  @override
  Widget build(BuildContext context) {
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
                  child: AbsorbPointer(
                    absorbing: _isLoading,
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
                                  EmailChangeLocalization.translate('title', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(
                                    fontSize: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
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
                              const SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isLoading ? null : _handleClose,
                                child: Text(
                                  EmailChangeLocalization.translate('cancel_button', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 100,
                                child: Button3D(
                                  backgroundColor: const Color(0xFFF1B33A),
                                  borderColor: const Color(0xFF8B5A00),
                                  onPressed: _isLoading ? () {} : handleContinue,
                                  child: Text(
                                    EmailChangeLocalization.translate('change_button', widget.selectedLanguage),
                                    style: GoogleFonts.vt323(
                                      color: Colors.black,
                                      fontSize: 18,
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
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const LoadingWidget(),
              ),
          ],
        ),
      ),
    );
  }
} 