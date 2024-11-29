import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/admin/security/admin_session.dart';
import 'package:handabatamae/admin/admin_home_page.dart';

class AdminLoginDialog extends StatefulWidget {
  final Function(String, String) onLogin;

  const AdminLoginDialog({
    super.key,
    required this.onLogin,
  });

  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAuthenticating = false;
  final AuthService _authService = AuthService();

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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSecurityAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Alert'),
        content: const Text('Multiple failed login attempts detected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAdminLoginError(dynamic error) {
    setState(() => _isAuthenticating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login error: $error')),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isAuthenticating = true);
      
      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final user = await _authService.signInWithUsernameAndPassword(username, password);

        if (!mounted) return;

        if (user != null) {
          final role = await _authService.getUserRole(user.uid);
          
          if (role == 'admin') {
            try {
              await AdminSession().startSession();
              
              if (!mounted) return;
              await _animationController.reverse();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminHomePage()),
              );
            } catch (sessionError) {
              throw sessionError;
            }
          } else {
            setState(() => _isAuthenticating = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You do not have admin privileges.')),
            );
          }
        } else {
          setState(() => _isAuthenticating = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        _handleAdminLoginError(e);
      }
    }
  }

  void _forgotPassword() {
    // Handle forgot password
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
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
                child: Stack(
                  children: [
                    Container(
                      width: dialogWidth,
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
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
                                      'ADMIN LOG IN',
                                      style: GoogleFonts.vt323(
                                        fontSize: titleFontSize,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: contentPadding),
                                  Text(
                                    'USERNAME',
                                    style: GoogleFonts.vt323(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _usernameController,
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFF241242),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'PASSWORD',
                                    style: GoogleFonts.vt323(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFF241242),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(color: Colors.white, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
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
                                      'CANCEL',
                                      style: GoogleFonts.vt323(
                                        color: Colors.white,
                                        fontSize: buttonTextSize,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: contentPadding * 0.75),
                                  Button3D(
                                    backgroundColor: const Color(0xFFF1B33A),
                                    borderColor: const Color(0xFF8B5A00),
                                    onPressed: _handleLogin,
                                    child: Text(
                                      'Login',
                                      style: GoogleFonts.vt323(
                                        color: Colors.black,
                                        fontSize: buttonTextSize,
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
                    if (_isAuthenticating)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 