import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/pages/play_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class WelcomeSection extends StatelessWidget {
  final String selectedLanguage;

  const WelcomeSection({
    super.key,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          TextWithShadow(
            text: MainPageLocalization.translate('handaBata', selectedLanguage),
            fontSize: 85,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: TextWithShadow(
              text: MainPageLocalization.translate('mobile', selectedLanguage),
              fontSize: 85,
            ),
          ),
          const SizedBox(height: 20),
          Transform.translate(
            offset: const Offset(0, -20), // Adjust this offset as needed
            child: SvgPicture.asset(
              'assets/characters/KladisandKloud.svg',
              width: 250,
              height: 250,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              MainPageLocalization.translate('joinKladisAndKloud', selectedLanguage),
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF351b61),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PlayPage(selectedLanguage: selectedLanguage, title: 'Adventure')),
                );
              },
              child: Text(
                MainPageLocalization.translate('playNow', selectedLanguage),
                style: GoogleFonts.vt323(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}