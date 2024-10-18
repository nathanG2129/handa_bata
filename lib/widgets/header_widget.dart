import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String selectedLanguage;
  final VoidCallback onBack;
  final VoidCallback onToggleUserProfile;
  final ValueChanged<String> onChangeLanguage;

  const HeaderWidget({
    super.key,
    required this.selectedLanguage,
    required this.onBack,
    required this.onToggleUserProfile,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top, // Add padding to avoid the status bar
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
            child: Padding(
              padding: const EdgeInsets.only(left: 44.0), // Adjust this value to fine-tune the position
              child: IconButton(
                icon: const Icon(Icons.person, size: 33, color: Colors.white),
                onPressed: onToggleUserProfile,
              ),
            ),
          ),
          DropdownButton<String>(
            icon: const Icon(Icons.language, color: Colors.white, size: 40),
            underline: Container(),
            items: const [
              DropdownMenuItem(
                value: 'en',
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: 'fil',
                child: Text('Filipino'),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChangeLanguage(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}