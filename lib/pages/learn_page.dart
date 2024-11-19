import 'package:flutter/material.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/learn/disaster_content.dart';
import 'package:handabatamae/widgets/learn/introduction_content.dart';
import 'package:handabatamae/widgets/learn/preparedness_content.dart';
import 'package:handabatamae/widgets/learn/emergency_kit_content.dart';
import 'package:handabatamae/widgets/learn/intensity_scale_content.dart';
import 'package:handabatamae/widgets/learn/typhoon_warning_content.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/learn_content_service.dart';

class LearnPage extends StatelessWidget {
  final String selectedLanguage;
  final String category;
  final String title;

  const LearnPage({
    super.key,
    required this.selectedLanguage,
    required this.category,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onBack: () => Navigator.pop(context),
                      onChangeLanguage: (String newLanguage) {
                        // Handle language change
                      },
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: 40),
                              LearnContent(
                                category: category,
                                title: title,
                                selectedLanguage: selectedLanguage,
                              ),
                              const SizedBox(height: 40),
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
    );
  }
}

class LearnContent extends StatelessWidget {
  final String category;
  final String title;
  final String selectedLanguage;
  final LearnContentService _contentService = LearnContentService();

  LearnContent({
    super.key,
    required this.category,
    required this.title,
    required this.selectedLanguage,
  });

  Future<Map<String, dynamic>> _getContent() async {
    return await _contentService.getContent(category, title, selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final content = snapshot.data!;
          
          return Column(
            children: [
              TextWithShadow(
                text: content['title'] ?? title,
                fontSize: 40,
              ),
              const SizedBox(height: 20),
              ...List<Widget>.from(
                (content['content'] as List).asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['heading'] != null) ...[
                        Text(
                          item['heading'],
                          style: GoogleFonts.rubik(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF351B61),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (item['description'] != null) ...[
                        Text(
                          item['description'],
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (item['list'] != null)
                        _buildContentSection(item, index),
                      const SizedBox(height: 20),
                    ],
                  );
                }),
              ),
              if (content['references'] != null) ...[
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'References',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF351B61),
                  ),
                ),
                const SizedBox(height: 10),
                ...List<Widget>.from(
                  (content['references'] as List).map((ref) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      ref,
                      style: GoogleFonts.rubik(fontSize: 14),
                    ),
                  )),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildContentSection(Map<String, dynamic> item, int index) {
    if (item['list'] == null) return const SizedBox.shrink();

    switch (title) {
      case 'About Earthquakes':
      case 'About Typhoons':
        return IntroductionContent(contents: item);

      case 'Disastrous Earthquakes in the Philippines':
      case 'Disastrous Typhoons in the Philippines':
        return DisasterContent(contents: item);

      case 'Preparing for Earthquakes':
      case 'Preparing for Typhoons':
        return PreparednessContent(contents: item);

      case 'Emergency Go Bag':
        return EmergencyKitContent(contents: item);

      case 'Earthquake Intensity Scale':
        return IntensityScaleContent(contents: item);

      case 'Tropical Cyclone Warning Systems':
      case 'Rainfall Warning System':
        return TyphoonWarningContent(
          contents: item,
          order: index,
        );

      default:
        return const SizedBox.shrink();
    }
  }
} 