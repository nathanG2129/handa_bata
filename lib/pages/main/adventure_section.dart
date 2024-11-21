import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart'; // Import the new button widget
import 'package:handabatamae/widgets/learn/carousel_widget.dart'; // Add this import

class AdventureSection extends StatelessWidget {
  final String selectedLanguage;

  const AdventureSection({
    super.key,
    required this.selectedLanguage,
  });

  List<Widget> _buildCarouselContents() {
    return [
      'PlayAdventure01',
      'PlayAdventure02',
      'PlayAdventure03',
      'PlayAdventure04',
    ].map((imageName) {
      return ClipRRect(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.asset(
            'assets/images/landing/$imageName.jpg',
            fit: BoxFit.fill,
            alignment: Alignment.center,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          if (selectedLanguage == 'en') 
            TextWithShadow(
              text: MainPageLocalization.translate('playAdventure', selectedLanguage),
              fontSize: 70,
            )
          else if (selectedLanguage == 'fil') ...[
            TextWithShadow(
              text: MainPageLocalization.translate('playAdventure', selectedLanguage),
              fontSize: 70,
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: TextWithShadow(
                text: MainPageLocalization.translate('playAdventureMode', selectedLanguage),
                fontSize: 70,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              MainPageLocalization.translate('adventureDescription', selectedLanguage),
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          CarouselWidget(
            height: 200,
            contents: _buildCarouselContents(),
          ),
          const SizedBox(height: 50),
          Button3D(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdventurePage(selectedLanguage: selectedLanguage)),
              );
            },
            width: 225,
            height: 60,
            child: Text(
              MainPageLocalization.translate('playAdventureButton', selectedLanguage),
              style: GoogleFonts.vt323(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}