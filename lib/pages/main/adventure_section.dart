import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/learn/carousel_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Calculate responsive sizes
        final titleFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 60,
          tablet: 65,
          desktop: 70,
        );

        final descriptionFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20,
          tablet: 22,
          desktop: 24,
        );

        final carouselHeight = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 200.0,
          tablet: 300.0,
          desktop: 350.0,
        );

        final buttonWidth = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 200.0,
          tablet: 215.0,
          desktop: 225.0,
        );

        final buttonHeight = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 55.0,
          tablet: 60.0,
          desktop: 65.0,
        );

        final buttonFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20,
          tablet: 22,
          desktop: 24,
        );

        // Mobile layout (vertical)
        if (sizingInformation.deviceScreenType == DeviceScreenType.mobile) {
          return Center(
            child: Column(
              children: [
                if (selectedLanguage == 'en') 
                  TextWithShadow(
                    text: MainPageLocalization.translate('playAdventure', selectedLanguage),
                    fontSize: titleFontSize.toDouble(),
                  )
                else if (selectedLanguage == 'fil') ...[
                  TextWithShadow(
                    text: MainPageLocalization.translate('playAdventure', selectedLanguage),
                    fontSize: titleFontSize.toDouble(),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: TextWithShadow(
                      text: MainPageLocalization.translate('playAdventureMode', selectedLanguage),
                      fontSize: titleFontSize.toDouble(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    MainPageLocalization.translate('adventureDescription', selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: descriptionFontSize.toDouble(),
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                CarouselWidget(
                  height: carouselHeight,
                  contents: _buildCarouselContents(),
                ),
                const SizedBox(height: 50),
                Button3D(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdventurePage(selectedLanguage: selectedLanguage),
                      ),
                    );
                  },
                  width: buttonWidth,
                  height: buttonHeight,
                  child: Text(
                    MainPageLocalization.translate('playAdventureButton', selectedLanguage),
                    style: GoogleFonts.vt323(
                      fontSize: buttonFontSize.toDouble(),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Tablet and Desktop layout (side by side)
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 20,
              tablet: 40,
              desktop: 150,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Text content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (selectedLanguage == 'en') 
                      TextWithShadow(
                        text: MainPageLocalization.translate('playAdventure', selectedLanguage),
                        fontSize: titleFontSize.toDouble(),
                      )
                    else if (selectedLanguage == 'fil') ...[
                      TextWithShadow(
                        text: MainPageLocalization.translate('playAdventure', selectedLanguage),
                        fontSize: titleFontSize.toDouble(),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: TextWithShadow(
                          text: MainPageLocalization.translate('playAdventureMode', selectedLanguage),
                          fontSize: titleFontSize.toDouble(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        MainPageLocalization.translate('adventureDescription', selectedLanguage),
                        style: GoogleFonts.rubik(
                          fontSize: descriptionFontSize.toDouble(),
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Button3D(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdventurePage(selectedLanguage: selectedLanguage),
                          ),
                        );
                      },
                      width: buttonWidth,
                      height: buttonHeight,
                      child: Text(
                        MainPageLocalization.translate('playAdventureButton', selectedLanguage),
                        style: GoogleFonts.vt323(
                          fontSize: buttonFontSize.toDouble(),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side - Carousel
              Expanded(
                child: CarouselWidget(
                  height: carouselHeight,
                  contents: _buildCarouselContents(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}