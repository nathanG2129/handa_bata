import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class LearnMoreSection extends StatelessWidget {
  final String selectedLanguage;

  const LearnMoreSection({
    super.key,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          TextWithShadow(
            text: MainPageLocalization.translate('learnAbout', selectedLanguage),
            fontSize: 70,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: TextWithShadow(
              text: MainPageLocalization.translate('preparedness', selectedLanguage),
              fontSize: 70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/characters/KloudLearn.svg',
                width: 200,
                height: 200,
              ),
              const SizedBox(width: 20),
              SvgPicture.asset(
                'assets/characters/KladisLearn.svg',
                width: 200,
                height: 200,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              MainPageLocalization.translate('learnMoreDescription', selectedLanguage),
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
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
                // Add navigation to Learn About Preparedness page
              },
              child: Text(
                MainPageLocalization.translate('learnMore', selectedLanguage),
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