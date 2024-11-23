import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/pages/learn_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

class LearnMoreSection extends StatelessWidget {
  final String selectedLanguage;

  const LearnMoreSection({
    super.key,
    required this.selectedLanguage,
  });

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

        final characterSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 150.0,
          tablet: 200.0,
          desktop: 250.0,
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
                TextWithShadow(
                  text: MainPageLocalization.translate('learnAbout', selectedLanguage),
                  fontSize: titleFontSize.toDouble(),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: TextWithShadow(
                    text: MainPageLocalization.translate('preparedness', selectedLanguage),
                    fontSize: titleFontSize.toDouble(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/characters/KloudLearn.svg',
                      width: characterSize,
                      height: characterSize,
                    ),
                    const SizedBox(width: 20),
                    SvgPicture.asset(
                      'assets/characters/KladisLearn.svg',
                      width: characterSize,
                      height: characterSize,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    MainPageLocalization.translate('learnMoreDescription', selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: descriptionFontSize.toDouble(),
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 50),
                Button3D(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LearnPage(
                          selectedLanguage: selectedLanguage,
                          category: 'Earthquakes',
                          title: 'About Earthquakes',
                          onBack: () => Navigator.pop(context),
                          onLanguageChange: (String newLanguage) {},
                        ),
                      ),
                    );
                  },
                  width: buttonWidth,
                  height: buttonHeight,
                  child: Text(
                    MainPageLocalization.translate('learnMore', selectedLanguage),
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
              tablet: 150,
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
                    TextWithShadow(
                      text: MainPageLocalization.translate('learnAbout', selectedLanguage),
                      fontSize: titleFontSize.toDouble(),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: TextWithShadow(
                        text: MainPageLocalization.translate('preparedness', selectedLanguage),
                        fontSize: titleFontSize.toDouble(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        MainPageLocalization.translate('learnMoreDescription', selectedLanguage),
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
                            builder: (context) => LearnPage(
                              selectedLanguage: selectedLanguage,
                              category: 'Earthquakes',
                              title: 'About Earthquakes',
                              onBack: () => Navigator.pop(context),
                              onLanguageChange: (String newLanguage) {},
                            ),
                          ),
                        );
                      },
                      width: buttonWidth,
                      height: buttonHeight,
                      child: Text(
                        MainPageLocalization.translate('learnMore', selectedLanguage),
                        style: GoogleFonts.vt323(
                          fontSize: buttonFontSize.toDouble(),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side - Characters
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/characters/KloudLearn.svg',
                    width: characterSize,
                    height: characterSize,
                  ),
                  const SizedBox(width: 20),
                  SvgPicture.asset(
                    'assets/characters/KladisLearn.svg',
                    width: characterSize,
                    height: characterSize,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}