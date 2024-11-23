import 'package:flutter/material.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/resources/resource_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ResourcesPage extends StatefulWidget {
  final String selectedLanguage;
  final String category;

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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(selectedLanguage: widget.selectedLanguage),
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

                return Column(
                  children: [
                    // Header
                    HeaderWidget(
                      selectedLanguage: widget.selectedLanguage,
                      onBack: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainPage(selectedLanguage: widget.selectedLanguage),
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
                                      const SizedBox(height: 20),
                                      TextWithShadow(
                                        text: widget.category,
                                        fontSize: titleFontSize,
                                      ),
                                      const SizedBox(height: 20),
                                      ResourceGrid(
                                        category: widget.category,
                                        selectedLanguage: widget.selectedLanguage,
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Footer outside of constraints
                            FooterWidget(selectedLanguage: widget.selectedLanguage),
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