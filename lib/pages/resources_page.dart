import 'package:flutter/material.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/resources/resource_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResourcesPage extends StatefulWidget {
  final String selectedLanguage;
  final String category; // 'Videos' or 'Infographics'

  const ResourcesPage({
    super.key,
    required this.selectedLanguage,
    required this.category,
  });

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
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
                // Background
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Content
                Column(
                  children: [
                    // Header
                    HeaderWidget(
                      selectedLanguage: widget.selectedLanguage,
                      onBack: () => Navigator.pop(context),
                      onChangeLanguage: (String newLanguage) {
                        // Handle language change
                      },
                    ),
                    // Main Content
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: 20),
                              Center(
                                child: TextWithShadow(
                                  text: widget.category,
                                  fontSize: 70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ResourceGrid(
                                category: widget.category,
                                selectedLanguage: widget.selectedLanguage,
                              ),
                              const SizedBox(height: 40),
                            ]),
                          ),
                          // Footer
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