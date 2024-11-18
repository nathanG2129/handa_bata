import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/email_verification_dialog.dart';
import 'package:handabatamae/pages/register_page.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/dialogs/change_password_dialog.dart';
import '../localization/play/localization.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/widgets/dialogs/change_email_dialog.dart';

class AccountSettingsContent extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onShowChangeNicknameDialog;
  final VoidCallback onLogout;
  final VoidCallback onShowDeleteAccountDialog;
  final String selectedLanguage;
  final Color Function(Color, [double]) darkenColor;
  final String Function(String) redactEmail;
  final String userRole;

  const AccountSettingsContent({
    super.key,
    required this.userProfile,
    required this.onShowChangeNicknameDialog,
    required this.onLogout,
    required this.onShowDeleteAccountDialog,
    required this.selectedLanguage,
    required this.darkenColor,
    required this.redactEmail,
    required this.userRole,
  });

  Future<void> _handleEmailChange(BuildContext context) async {
    try {
      print('\n🔄 INITIATING EMAIL CHANGE');
      final authService = AuthService();
      
      // Show initial dialog for new email and current password
      if (!context.mounted) return;
      await showDialog<Map<String, String>>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) {
          return ChangeEmailDialog(
            currentEmail: userProfile.email,
            selectedLanguage: selectedLanguage,
            onEmailChanged: (newEmail, currentPassword) async {
              try {
                // Initiate email change and send OTP
                await authService.changeEmail(newEmail, currentPassword);
                
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(); // Close email dialog only after successful OTP send
                
                if (!context.mounted) return;
                
                // Show OTP verification dialog
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext verifyContext) => EmailVerificationDialog(
                    email: newEmail,
                    selectedLanguage: selectedLanguage,
                    isEmailChange: true,
                    onVerify: (otp) async {
                      try {
                        await authService.verifyAndUpdateEmail(newEmail, otp);
                        if (!verifyContext.mounted) return;
                        Navigator.of(verifyContext).pop(); // Close verification dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              PlayLocalization.translate('emailChangeSuccess', selectedLanguage)
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!verifyContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${PlayLocalization.translate('errorVerifyingEmail', selectedLanguage)} $e'
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${PlayLocalization.translate('errorChangingEmail', selectedLanguage)} $e'
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            darkenColor: darkenColor,
          );
        },
      );
      
      print('✅ Email change process completed\n');
    } catch (e) {
      print('❌ Error in email change process: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${PlayLocalization.translate('errorChangingEmail', selectedLanguage)} $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePasswordChange(BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ChangePasswordDialog(
          selectedLanguage: selectedLanguage,
          onPasswordChanged: (currentPassword, newPassword) => 
              _updatePassword(context, currentPassword, newPassword),
          darkenColor: darkenColor,
        );
      },
    );
  }

  Future<void> _updatePassword(BuildContext context, String currentPassword, String newPassword) async {
    try {
      print('\n🔄 UPDATING PASSWORD');
      AuthService authService = AuthService();
      await authService.changePassword(currentPassword, newPassword);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PlayLocalization.translate('passwordChangeSuccess', selectedLanguage)
          ),
          backgroundColor: Colors.green,
        ),
      );
      print('✅ Password update completed\n');
    } catch (e) {
      print('❌ Error updating password: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${PlayLocalization.translate('errorChangingPassword', selectedLanguage)} $e'
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSection(
            title: PlayLocalization.translate('nickname', selectedLanguage),
            content: userProfile.nickname,
            buttonLabel: PlayLocalization.translate('change', selectedLanguage),
            buttonColor: const Color(0xFF4d278f),
            onPressed: onShowChangeNicknameDialog,
          ),
          if (userRole != 'guest') ...[
            _buildSection(
              title: PlayLocalization.translate('birthday', selectedLanguage),
              content: userProfile.birthday,
            ),
            _buildSection(
              title: PlayLocalization.translate('email', selectedLanguage),
              content: redactEmail(userProfile.email),
              buttonLabel: PlayLocalization.translate('change', selectedLanguage),
              buttonColor: const Color(0xFF4d278f),
              onPressed: () => _handleEmailChange(context),
            ),
            _buildSection(
              title: PlayLocalization.translate('password', selectedLanguage),
              content: '********',
              buttonLabel: PlayLocalization.translate('change', selectedLanguage),
              buttonColor: const Color(0xFF4d278f),
              onPressed: () => _handlePasswordChange(context),
            ),
          ],
          _buildSection(
            title: userRole == 'guest' 
              ? PlayLocalization.translate('register', selectedLanguage)
              : PlayLocalization.translate('logout', selectedLanguage),
            buttonLabel: userRole == 'guest'
              ? PlayLocalization.translate('registerButton', selectedLanguage)
              : PlayLocalization.translate('logoutButton', selectedLanguage),
            buttonColor: userRole == 'guest' ? const Color(0xFF4d278f) : Colors.red,
            onPressed: userRole == 'guest'
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationPage(selectedLanguage: selectedLanguage),
                  ),
                )
              : onLogout,
            content: '',
          ),
          const Divider(
            color: Colors.black,
            thickness: 1,
            indent: 10,
            endIndent: 10,
          ),
          _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            PlayLocalization.translate('accountRemoval', selectedLanguage),
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            PlayLocalization.translate('accountRemovalDescription', selectedLanguage),
            style: GoogleFonts.rubik(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Button3D(
              onPressed: onShowDeleteAccountDialog,
              backgroundColor: const Color(0xFFc32929),
              borderColor: darkenColor(const Color(0xFFc32929)),
              width: 150,
              height: 40,
              child: Text(
                PlayLocalization.translate('delete', selectedLanguage),
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    String? buttonLabel,
    Color? buttonColor,
    VoidCallback? onPressed,
    Color buttonTextColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (buttonLabel != null && buttonColor != null && onPressed != null)
            Button3D(
              onPressed: onPressed,
              backgroundColor: buttonColor,
              borderColor: darkenColor(buttonColor),
              width: 80 * 1.05,
              height: 35 * 1.05,
              child: Text(
                buttonLabel,
                style: GoogleFonts.vt323(color: buttonTextColor, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}