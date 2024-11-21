import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/privacy_policy_page.dart';
import 'package:handabatamae/pages/terms_of_service_page.dart';

class FooterWidget extends StatelessWidget {
  final String? selectedLanguage;

  const FooterWidget({
    super.key,
    this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF351B61),
        border: Border(
          top: BorderSide(color: Colors.white, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Handa Bata © 2024',
            style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacyPolicyPage(
                        selectedLanguage: selectedLanguage ?? 'en',
                      ),
                    ),
                  );
                },
                child: Text(
                  selectedLanguage == 'fil' ? 'Patakaran sa Privacy' : 'Privacy Policy',
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsOfServicePage(
                          selectedLanguage: selectedLanguage ?? 'en',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    selectedLanguage == 'fil' ? 'Mga Tuntunin ng Serbisyo' : 'Terms of Service',
                    style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}