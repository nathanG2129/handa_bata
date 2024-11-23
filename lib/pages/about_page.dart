import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
                                      const SizedBox(height: 10),
                                      AboutProjectSection(sizingInformation: sizingInformation),
                                      const SizedBox(height: 60),
                                      TeamSection(sizingInformation: sizingInformation),
                                      const SizedBox(height: 60),
                                      ContactSection(sizingInformation: sizingInformation),
                                      const SizedBox(height: 80),
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

class AboutProjectSection extends StatelessWidget {
  final SizingInformation sizingInformation;

  const AboutProjectSection({
    super.key,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          TextWithShadow(
            text: 'About',
            fontSize: titleFontSize,
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: TextWithShadow(
              text: 'The Project',
              fontSize: titleFontSize,
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
                    fontSize: descriptionFontSize,
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
  final SizingInformation sizingInformation;

  const TeamMemberCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
    final nameFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    final imageSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 80.0,
      tablet: 100.0,
      desktop: 120.0,
    );

    return Container(
      padding: const EdgeInsets.all(12),
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
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: imagePath.isEmpty
                ? Icon(
                    Icons.person,
                    size: imageSize * 0.6,
                    color: Colors.white.withOpacity(0.5),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.rubik(
              fontSize: nameFontSize,
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
  final SizingInformation sizingInformation;

  const TeamSection({
    super.key,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 48.0,
      tablet: 60.0,
      desktop: 70.0,
    );

    final sectionTitleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 28.0,
      tablet: 32.0,
      desktop: 36.0,
    );

    // Create team data
    final mobileTeam = [
      const TeamMemberData('Ariel Camry Serrano', 'assets/members/Camry.png'),
      const TeamMemberData('Leonard Balang', 'assets/members/Leonard.png'),
      const TeamMemberData('Nathan Paul Gaya', 'assets/members/Nathan.png'),
      const TeamMemberData('John Christopher See', 'assets/members/See.png'),
    ];

    final webTeam = [
      const TeamMemberData('Charles Dave Reyes', 'assets/members/Charles.png'),
      const TeamMemberData('Margaret Bernice Carreon', 'assets/members/Margaret.png'),
      const TeamMemberData('Andrea Jasmine Fontanilla', 'assets/members/Andrea.png'),
      const TeamMemberData('John William Dalican', 'assets/members/John.png'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextWithShadow(
            text: 'Meet the Team',
            fontSize: titleFontSize,
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: sizingInformation.deviceScreenType == DeviceScreenType.tablet
                // Tablet Layout - Side by side teams
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              'Handa Bata Mobile',
                              style: GoogleFonts.rubik(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTeamGrid(context, mobileTeam, sizingInformation),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              'Handa Bata Web',
                              style: GoogleFonts.rubik(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTeamGrid(context, webTeam, sizingInformation),
                          ],
                        ),
                      ),
                    ],
                  )
                // Mobile and Desktop Layout - Stacked teams
                : Column(
                    children: [
                      // Handa Bata Mobile Team
                      const SizedBox(height: 40),
                      Text(
                        'Handa Bata Mobile',
                        style: GoogleFonts.rubik(
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTeamGrid(context, mobileTeam, sizingInformation),
                      const SizedBox(height: 60),
                      // Handa Bata Web Team
                      Text(
                        'Handa Bata Web',
                        style: GoogleFonts.rubik(
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTeamGrid(context, webTeam, sizingInformation),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamGrid(BuildContext context, List<TeamMemberData> members, SizingInformation sizingInformation) {
    final crossAxisCount = ResponsiveUtils.valueByDevice<int>(
      context: context,
      mobile: 2,
      tablet: 2,
      desktop: 4,
    );

    final gridSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 12.0,
      tablet: 10.0,
      desktop: 20.0,
    );

    final gridMaxWidth = sizingInformation.deviceScreenType == DeviceScreenType.tablet
        ? 450.0
        : double.infinity;

    return Center(
      child: SizedBox(
        width: gridMaxWidth,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: gridSpacing,
            crossAxisSpacing: gridSpacing,
            childAspectRatio: 0.8,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return TeamMemberCard(
              name: members[index].name,
              imagePath: members[index].imagePath,
              sizingInformation: sizingInformation,
            );
          },
        ),
      ),
    );
  }
}

class TeamMemberData {
  final String name;
  final String imagePath;

  const TeamMemberData(this.name, this.imagePath);
}

class ContactSection extends StatelessWidget {
  final SizingInformation sizingInformation;

  const ContactSection({
    super.key,
    required this.sizingInformation,
  });

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextWithShadow(
            text: 'Contact Us',
            fontSize: titleFontSize,
          ),
          Transform.translate(
            offset: const Offset(0, 0),
            child: Text(
              'For any questions or concerns about Handa Bata, you can email us at handabata.official@gmail.com.',
              style: GoogleFonts.rubik(
                fontSize: descriptionFontSize,
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