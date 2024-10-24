import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class ArcadeSection extends StatelessWidget {
  final String selectedLanguage;

  const ArcadeSection({
    super.key,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
            if (selectedLanguage == 'en') 
            TextWithShadow(
              text: MainPageLocalization.translate('playArcade', selectedLanguage),
              fontSize: 70,
            )
            else if (selectedLanguage == 'fil') ...[
            TextWithShadow(
              text: MainPageLocalization.translate('playArcade', selectedLanguage),
              fontSize: 70,
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: TextWithShadow(
              text: MainPageLocalization.translate('playArcadeMode', selectedLanguage),
              fontSize: 70,
              ),
            ),
            ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              MainPageLocalization.translate('arcadeDescription', selectedLanguage),
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              enlargeCenterPage: true,
              autoPlay: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.8,
            ),
            items: [1, 2, 3, 4, 5].map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                    ),
                    child: Text('Arcade image $i', style: const TextStyle(fontSize: 16.0)),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 50),
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
                  MaterialPageRoute(builder: (context) => ArcadePage(selectedLanguage: selectedLanguage)),
                );
              },
              child: Text(
                MainPageLocalization.translate('playArcadeButton', selectedLanguage),
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