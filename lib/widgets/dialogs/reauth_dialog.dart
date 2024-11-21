import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../localization/reauth/localization.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';

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
      print('❌ Reauthentication error: $e');
      setState(() {
        _errorMessage = ReauthLocalization.translate('invalid_password', widget.selectedLanguage);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: 20.0,
                      left: 20.0,
                      right: 20.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 20.0 : 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            ReauthLocalization.translate('title', widget.selectedLanguage),
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
                                  ReauthLocalization.translate('warning', widget.selectedLanguage),
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
                        Text(
                          ReauthLocalization.translate('password_label', widget.selectedLanguage),
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            errorText: _errorMessage,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off : Icons.visibility,
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
                            fontSize: 16,
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
                            ReauthLocalization.translate('cancel_button', widget.selectedLanguage),
                            style: GoogleFonts.vt323(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Button3D(
                          onPressed: _isLoading 
                            ? () {}
                            : () => _reauthenticate(),
                          backgroundColor: const Color(0xFFF1B33A),
                          borderColor: const Color(0xFF916D23),
                          width: 150,
                          height: 40,
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
    );
  }
} 