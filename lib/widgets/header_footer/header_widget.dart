import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderWidget extends StatelessWidget {
  final String selectedLanguage;
  final VoidCallback onBack;
  final VoidCallback onToggleUserProfile;
  final ValueChanged<String> onChangeLanguage;
  final VoidCallback onAccountSettings; // Add this line

  const HeaderWidget({
    super.key,
    required this.selectedLanguage,
    required this.onBack,
    required this.onToggleUserProfile,
    required this.onChangeLanguage,
    required this.onAccountSettings, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2, // Add padding to avoid the status bar
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF351B61),
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 2.0), // Add white border to the bottom
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white),
            onPressed: onBack,
          ),
          Align(
            alignment: Alignment.center,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.person, size: 33, color: Colors.white),
              color: const Color(0xFF241242), // Set the popup menu background color
              offset: const Offset(0, 64), // Position the popup menu a bit lower
              onSelected: (String result) {
                switch (result) {
                  case 'My Profile':
                    onToggleUserProfile();
                    break;
                  case 'Account Settings':
                    onAccountSettings();
                    break;
                  // Add cases for other menu items if needed
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'My Profile',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'My Profile',
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Characters',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Characters',
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Badges',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Badges',
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Banners',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Banners',
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Account Settings',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Account Settings',
                        style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white, size: 40),
            color: const Color(0xFF241242), // Set the popup menu background color
            offset: const Offset(0, 68), // Position the popup menu a bit lower
            onSelected: (String newValue) {
              onChangeLanguage(newValue);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedLanguage == 'en' ? 'English' : 'Ingles',
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                    ),
                    const SizedBox(width: 8), // Add some space between text and icon
                    if (selectedLanguage == 'en') const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'fil',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filipino',
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                    ),
                    const SizedBox(width: 8), // Add some space between text and icon
                    if (selectedLanguage == 'fil') const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}