import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AboutPage extends StatelessWidget {
  final String selectedLanguage;

  const AboutPage({
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
                              delegate: SliverChildListDelegate([
                                const SizedBox(height: 10),
                                // About Project Section
                                const AboutProjectSection(),
                                const SizedBox(height: 60),
                                // Team Section
                                const TeamSection(),
                                const SizedBox(height: 60),
                                // Contact Section
                                const ContactSection(),
                                const SizedBox(height: 80),
                              ]),
                            ),
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  Spacer(),
                                  FooterWidget(),
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

class AboutProjectSection extends StatelessWidget {
  const AboutProjectSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          const TextWithShadow(
            text: 'About',
            fontSize: 70,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: const TextWithShadow(
              text: 'The Project',
              fontSize: 70,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  height: 150,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SvgPicture.asset(
                      'assets/characters/KladisandKloud.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Handa Bata is a game-based learning website and mobile application that aims to empower Filipino children in junior high school with the knowledge they need to prepare for, respond to, and recover from earthquakes and typhoons. It was developed in 2023 by four Information Technology students from the University of Santo Tomas in Manila, Philippines. In 2024, the mobile application was developed by a new team of students from the same university.\n\nWe believe that every child should have the opportunity to be safe and resilient during times of disaster, and that technology can be a powerful tool to make this happen. That\'s why we created Handa Bata.',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const TeamMemberCard({
    super.key,
    required this.name,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
            ),
            child: imagePath.isEmpty
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white.withOpacity(0.5),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class TeamSection extends StatelessWidget {
  const TeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const TextWithShadow(
            text: 'Meet the Team',
            fontSize: 70,
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Column(
              children: [
                // Handa Bata Mobile Team
                const SizedBox(height: 40),
                Text(
                  'Handa Bata Mobile',
                  style: GoogleFonts.rubik(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                  children: const [
                    TeamMemberCard(
                      name: 'Ariel Camry Serrano',
                      imagePath: '', // Placeholder for now
                    ),
                    TeamMemberCard(
                      name: 'Leonard Balang',
                      imagePath: '', // Placeholder for now
                    ),
                    TeamMemberCard(
                      name: 'Nathan Paul Gaya',
                      imagePath: '', // Placeholder for now
                    ),
                    TeamMemberCard(
                      name: 'John Christopher See',
                      imagePath: '', // Placeholder for now
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                // Handa Bata Web Team
                Text(
                  'Handa Bata Web',
                  style: GoogleFonts.rubik(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                  children: const [
                    TeamMemberCard(
                      name: 'Charles Dave Reyes',
                      imagePath: 'assets/members/Charles.png',
                    ),
                    TeamMemberCard(
                      name: 'Margaret Bernice Carreon',
                      imagePath: 'assets/members/Margaret.png',
                    ),
                    TeamMemberCard(
                      name: 'Andrea Jasmine Fontanilla',
                      imagePath: 'assets/members/Andrea.png',
                    ),
                    TeamMemberCard(
                      name: 'John William Dalican',
                      imagePath: 'assets/members/John.png',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const TextWithShadow(
            text: 'Contact Us',
            fontSize: 70,
          ),
          Transform.translate(
            offset: const Offset(0, 0),
            child: Text(
              'For any questions or concerns about Handa Bata, you can email us at handabata.official@gmail.com.',
              style: GoogleFonts.rubik(
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 