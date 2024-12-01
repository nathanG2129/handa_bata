import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/main/localization.dart';
import 'package:handabatamae/pages/play_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/dialogs/faq_dialog.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

class WelcomeSection extends StatelessWidget {
  final String selectedLanguage;

  const WelcomeSection({
    super.key,
    required this.selectedLanguage,
  });

  Color _darken(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => FAQDialog(selectedLanguage: selectedLanguage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Calculate responsive sizes
        final titleFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 65,
          tablet: 75,
          desktop: 85,
        );

        final subtitleFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 60,
          tablet: 70,
          desktop: 85,
        );

        final characterSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 200.0,
          tablet: 300.0,
          desktop: 250.0,
        );

        final descriptionFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20,
          tablet: 22,
          desktop: 24,
        );

        final buttonFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 24,
          tablet: 26,
          desktop: 28,
        );

        final buttonSpacing = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 8.0,
          tablet: 16.0,
          desktop: 24.0,
        );

        const faqButtonColor = Color(0xFF32c067);

        // Mobile layout (vertical)
        if (sizingInformation.deviceScreenType == DeviceScreenType.mobile) {
          return Center(
            child: Column(
              children: [
                TextWithShadow(
                  text: MainPageLocalization.translate('handaBata', selectedLanguage),
                  fontSize: titleFontSize.toDouble(),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: TextWithShadow(
                    text: MainPageLocalization.translate('mobile', selectedLanguage),
                    fontSize: subtitleFontSize.toDouble(),
                  ),
                ),
                const SizedBox(height: 20),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: SvgPicture.asset(
                    'assets/characters/KladisandKloud.svg',
                    width: characterSize,
                    height: characterSize,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    MainPageLocalization.translate('joinKladisAndKloud', selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: descriptionFontSize.toDouble(),
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Button3D(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayPage(
                              selectedLanguage: selectedLanguage,
                              title: 'Adventure',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        MainPageLocalization.translate('playNow', selectedLanguage),
                        style: GoogleFonts.vt323(
                          fontSize: buttonFontSize.toDouble(),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    Button3D(
                      onPressed: () => _showFAQDialog(context),
                      backgroundColor: faqButtonColor,
                      borderColor: _darken(faqButtonColor),
                      child: Text(
                        selectedLanguage == 'en' ? 'FAQ' : 'Mga FAQ',
                        style: GoogleFonts.vt323(
                          fontSize: buttonFontSize.toDouble(),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Tablet and Desktop layout (side by side)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 150),
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
                      text: MainPageLocalization.translate('handaBata', selectedLanguage),
                      fontSize: titleFontSize.toDouble(),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: TextWithShadow(
                        text: MainPageLocalization.translate('mobile', selectedLanguage),
                        fontSize: subtitleFontSize.toDouble(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        MainPageLocalization.translate('joinKladisAndKloud', selectedLanguage),
                        style: GoogleFonts.rubik(
                          fontSize: descriptionFontSize.toDouble(),
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Button3D(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayPage(
                                  selectedLanguage: selectedLanguage,
                                  title: 'Adventure',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            MainPageLocalization.translate('playNow', selectedLanguage),
                            style: GoogleFonts.vt323(
                              fontSize: buttonFontSize.toDouble(),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: buttonSpacing),
                        Button3D(
                          onPressed: () => _showFAQDialog(context),
                          backgroundColor: faqButtonColor,
                          borderColor: _darken(faqButtonColor),
                          child: Text(
                            selectedLanguage == 'en' ? 'FAQs' : 'Mga FAQ',
                            style: GoogleFonts.vt323(
                              fontSize: buttonFontSize.toDouble(),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right side - Character image
              SvgPicture.asset(
                'assets/characters/KladisandKloud.svg',
                width: characterSize,
                height: characterSize,
              ),
            ],
          ),
        );
      },
    );
  }
}