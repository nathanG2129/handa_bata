import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_framework/responsive_framework.dart';

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
        body: ResponsiveBreakpoints(
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 800, name: TABLET),
            Breakpoint(start: 801, end: 1920, name: DESKTOP),
            Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
          child: MaxWidthBox(
            maxWidth: 1200,
            child: ResponsiveScaledBox(
              width: ResponsiveValue<double>(context, conditionalValues: [
                const Condition.equals(name: MOBILE, value: 450),
                const Condition.between(start: 800, end: 1100, value: 800),
                const Condition.between(start: 1000, end: 1200, value: 1000),
              ]).value,
              child: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/backgrounds/background.svg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Column(
                    children: [
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
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate(
                                [
                                  const SizedBox(height: 40),
                                  Transform.translate(
                                    offset: const Offset(0, -20),
                                    child: Column(
                                      children: [
                                        const TextWithShadow(
                                          text: 'EMERGENCY',
                                          fontSize: 70,
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0, -30),
                                          child: const TextWithShadow(
                                            text: 'HOTLINES',
                                            fontSize: 70,
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
                                                fontSize: 24,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0, -30),
                                          child: const HotlinesList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  const Spacer(),
                                  FooterWidget(selectedLanguage: selectedLanguage),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HotlinesList extends StatelessWidget {
  const HotlinesList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // National Emergency Hotline
          EmergencyHotlineCard(
            isNational: true,
            name: 'NATIONAL EMERGENCY HOTLINE',
            hotline: '911',
          ),
          SizedBox(height: 30),
          // Other department cards
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              DepartmentCard(
                acronym: 'NDRRMC',
                name: 'National Disaster Risk Reduction and Management Council',
                hotlines: ['8911 5061 to 65 Local 100'],
                imagePath: 'assets/hotlines/NDRRMC.png',
              ),
              DepartmentCard(
                acronym: 'PRC',
                name: 'Philippine Red Cross',
                hotlines: ['143', '(02) 8527-8385 to 95'],
                imagePath: 'assets/hotlines/PRC.png',
              ),
              DepartmentCard(
                acronym: 'PHIVOLCS',
                name: 'Philippine Institute of Volcanology and Seismology',
                hotlines: ['8929-8958', '8426-1469-79'],
                imagePath: 'assets/hotlines/PHIVOLCS.png',
              ),
              DepartmentCard(
                acronym: 'PAGASA',
                name: 'Philippine Atmospheric, Geophysical and Astronomical Services Administration',
                hotlines: ['(02) 8284-0800'],
                imagePath: 'assets/hotlines/PAGASA.png',
              ),
              DepartmentCard(
                acronym: 'PCG',
                name: 'Philippine Coast Guard',
                hotlines: ['(02) 8527-8482', '(02) 8527-3880 to 85'],
                imagePath: 'assets/hotlines/PCG.png',
              ),
              DepartmentCard(
                acronym: 'DOH',
                name: 'Department of Health',
                hotlines: ['(632) 8651-7800', 'Local 5003-5004'],
                imagePath: 'assets/hotlines/DOH.png',
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

  const EmergencyHotlineCard({
    super.key,
    required this.isNational,
    required this.name,
    required this.hotline,
  });

  @override
  Widget build(BuildContext context) {
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
              fontSize: 32,
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
                fontSize: 32,
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

  const DepartmentCard({
    super.key,
    required this.acronym,
    required this.name,
    required this.hotlines,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: ResponsiveValue<double>(
          context,
          conditionalValues: [
            const Condition.smallerThan(name: TABLET, value: double.infinity),
            const Condition.equals(name: TABLET, value: 600),
            const Condition.equals(name: DESKTOP, value: 500),
          ],
          defaultValue: double.infinity,
        ).value,
      ),
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
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
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
                          fontSize: 16,
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
