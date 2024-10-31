import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/register_page.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import '../localization/play/localization.dart';

class AccountSettingsContent extends StatelessWidget {
  final UserProfile userProfile;
  final bool showEmail;
  final VoidCallback onToggleEmailVisibility;
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
    required this.showEmail,
    required this.onToggleEmailVisibility,
    required this.onShowChangeNicknameDialog,
    required this.onLogout,
    required this.onShowDeleteAccountDialog,
    required this.selectedLanguage,
    required this.darkenColor,
    required this.redactEmail,
    required this.userRole,
  });

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
              content: showEmail ? userProfile.email : redactEmail(userProfile.email),
              buttonLabel: showEmail ? PlayLocalization.translate('hide', selectedLanguage) : PlayLocalization.translate('show', selectedLanguage),
              buttonColor: const Color(0xFF4d278f),
              onPressed: onToggleEmailVisibility,
              buttonTextColor: Colors.white,
            ),
            _buildSection(
              title: PlayLocalization.translate('password', selectedLanguage),
              content: '********',
              buttonLabel: PlayLocalization.translate('change', selectedLanguage),
              buttonColor: const Color(0xFF4d278f),
              onPressed: () {
                // Handle password change
              },
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
            Padding(
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