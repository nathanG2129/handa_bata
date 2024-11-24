import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/privacy_policy_page.dart';
import 'package:handabatamae/pages/terms_of_service_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

class FooterWidget extends StatelessWidget {
  final String? selectedLanguage;

  const FooterWidget({
    super.key,
    this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final bool isMobileLargeOrSmaller = sizingInformation.deviceScreenType == DeviceScreenType.mobile &&
            MediaQuery.of(context).size.width <= 414;  // mobileLarge breakpoint

        return Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 6,  // Reduced padding for mobile
              tablet: 10,
              desktop: 12,
            ),
          ),
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
                style: GoogleFonts.vt323(
                  fontSize: isMobileLargeOrSmaller ? 16 : ResponsiveUtils.valueByDevice(
                    context: context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                  color: Colors.white,
                ),
              ),
              SizedBox(
                height: ResponsiveUtils.valueByDevice(
                  context: context,
                  mobile: 2,  // Reduced spacing for mobile
                  tablet: 5,
                  desktop: 6,
                ),
              ),
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
                      style: GoogleFonts.vt323(
                        fontSize: isMobileLargeOrSmaller ? 18 : 24,  // Smaller text for mobile
                        color: Colors.white
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: isMobileLargeOrSmaller ? 6 : 10),  // Reduced spacing
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
                        style: GoogleFonts.vt323(
                          fontSize: isMobileLargeOrSmaller ? 18 : 24,  // Smaller text for mobile
                          color: Colors.white
                        ),
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
    );
  }
}