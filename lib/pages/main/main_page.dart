import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'header_section.dart';
import 'welcome_section.dart';
import 'adventure_section.dart';
import 'arcade_section.dart';
import 'learnmore_section.dart';

class MainPage extends StatefulWidget {
  final String selectedLanguage;

  const MainPage({super.key, required this.selectedLanguage});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
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
                      HeaderSection(
                        selectedLanguage: _selectedLanguage,
                        onChangeLanguage: _changeLanguage,
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate(
                                [
                                  const SizedBox(height: 0),
                                  WelcomeSection(selectedLanguage: _selectedLanguage),
                                  const SizedBox(height: 200),
                                  AdventureSection(selectedLanguage: _selectedLanguage),
                                  const SizedBox(height: 200),
                                  ArcadeSection(selectedLanguage: _selectedLanguage),
                                  const SizedBox(height: 200),
                                  LearnMoreSection(selectedLanguage: _selectedLanguage),
                                  const SizedBox(height: 200),
                                  const SizedBox(height: 20),
                                ],
                              ),
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