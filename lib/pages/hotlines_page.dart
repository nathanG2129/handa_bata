import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HotlinesPage extends StatelessWidget {
  final String selectedLanguage;

  const HotlinesPage({
    super.key,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(selectedLanguage: selectedLanguage),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2C1B47),
        body: Stack(
          children: [
            // Background
            SvgPicture.asset(
              'assets/backgrounds/background.svg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Content
            ResponsiveBuilder(
              builder: (context, sizingInformation) {
                final maxWidth = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: double.infinity,
                  tablet: MediaQuery.of(context).size.width * 0.9,
                  desktop: 1200,
                );

                final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 48.0,
                );

                final titleFontSize = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: 48.0,
                  tablet: 60.0,
                  desktop: 70.0,
                );

                final descriptionFontSize = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: 16.0,
                  tablet: 20.0,
                  desktop: 24.0,
                );

                return Column(
                  children: [
                    // Header
                    HeaderWidget(
                      selectedLanguage: selectedLanguage,
                      onBack: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(selectedLanguage: selectedLanguage),
                          ),
                        );
                      },
                      onChangeLanguage: (String newLanguage) {
                        // Handle language change
                      },
                    ),
                    // Main content with constrained width
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Constrained content
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 40),
                                      Transform.translate(
                                        offset: const Offset(0, -20),
                                        child: Column(
                                          children: [
                                            TextWithShadow(
                                              text: 'EMERGENCY',
                                              fontSize: titleFontSize,
                                            ),
                                            Transform.translate(
                                              offset: const Offset(0, -30),
                                              child: TextWithShadow(
                                                text: 'HOTLINES',
                                                fontSize: titleFontSize,
                                              ),
                                            ),
                                            Transform.translate(
                                              offset: const Offset(0, -40),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 20,
                                                ),
                                                child: Text(
                                                  'Earthquakes, typhoons and volcanic eruptions of the most common and destructive natural disasters in the Philippines. Here are some important emergency numbers you should keep in mind in case of an earthquake or typhoon.',
                                                  style: GoogleFonts.rubik(
                                                    fontSize: descriptionFontSize,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            Transform.translate(
                                              offset: const Offset(0, -30),
                                              child: HotlinesList(sizingInformation: sizingInformation),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Footer outside of constraints
                            FooterWidget(selectedLanguage: selectedLanguage),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HotlinesList extends StatelessWidget {
  final SizingInformation sizingInformation;

  const HotlinesList({
    super.key,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
    final cardSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // National Emergency Hotline
          EmergencyHotlineCard(
            isNational: true,
            name: 'NATIONAL EMERGENCY HOTLINE',
            hotline: '911',
            sizingInformation: sizingInformation,
          ),
          SizedBox(height: cardSpacing),
          // Other department cards
          Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            children: [
              DepartmentCard(
                acronym: 'NDRRMC',
                name: 'National Disaster Risk Reduction and Management Council',
                hotlines: ['8911 5061 to 65 Local 100'],
                imagePath: 'assets/hotlines/NDRRMC.png',
                sizingInformation: sizingInformation,
              ),
              DepartmentCard(
                acronym: 'PRC',
                name: 'Philippine Red Cross',
                hotlines: ['143', '(02) 8527-8385 to 95'],
                imagePath: 'assets/hotlines/PRC.png',
                sizingInformation: sizingInformation,
              ),
              DepartmentCard(
                acronym: 'PHIVOLCS',
                name: 'Philippine Institute of Volcanology and Seismology',
                hotlines: ['8929-8958', '8426-1469-79'],
                imagePath: 'assets/hotlines/PHIVOLCS.png',
                sizingInformation: sizingInformation,
              ),
              DepartmentCard(
                acronym: 'PAGASA',
                name: 'Philippine Atmospheric, Geophysical and Astronomical Services Administration',
                hotlines: ['(02) 8284-0800'],
                imagePath: 'assets/hotlines/PAGASA.png',
                sizingInformation: sizingInformation,
              ),
              DepartmentCard(
                acronym: 'PCG',
                name: 'Philippine Coast Guard',
                hotlines: ['(02) 8527-8482', '(02) 8527-3880 to 85'],
                imagePath: 'assets/hotlines/PCG.png',
                sizingInformation: sizingInformation,
              ),
              DepartmentCard(
                acronym: 'DOH',
                name: 'Department of Health',
                hotlines: ['(632) 8651-7800', 'Local 5003-5004'],
                imagePath: 'assets/hotlines/DOH.png',
                sizingInformation: sizingInformation,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmergencyHotlineCard extends StatelessWidget {
  final bool isNational;
  final String name;
  final String hotline;
  final SizingInformation sizingInformation;

  const EmergencyHotlineCard({
    super.key,
    required this.isNational,
    required this.name,
    required this.hotline,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: GoogleFonts.vt323(
              fontSize: fontSize,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF241242),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              hotline,
              style: GoogleFonts.rubik(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DepartmentCard extends StatelessWidget {
  final String acronym;
  final String name;
  final List<String> hotlines;
  final String imagePath;
  final SizingInformation sizingInformation;

  const DepartmentCard({
    super.key,
    required this.acronym,
    required this.name,
    required this.hotlines,
    required this.imagePath,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: double.infinity,
      tablet: 400,
      desktop: 500,
    );

    final acronymFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 24.0,
      tablet: 26.0,
      desktop: 28.0,
    );

    final nameFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    return Container(
      constraints: BoxConstraints(maxWidth: cardWidth),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            width: 100,
            height: 100,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acronym,
                  style: GoogleFonts.vt323(
                    fontSize: acronymFontSize,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: GoogleFonts.rubik(
                    fontSize: nameFontSize,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: hotlines.map((hotline) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF241242),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hotline,
                        style: GoogleFonts.rubik(
                          fontSize: nameFontSize,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
