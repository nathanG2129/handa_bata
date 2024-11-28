import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/splash_page.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/services/stage_service.dart';
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
    _printStoredStages();
  }

  Future<void> _printStoredStages() async {
    final stageService = StageService();
    final stages = await stageService.getStagesFromLocal('all', useRawCache: true);
    
    print('=== Stored Arcade Stages with All Questions ===');
    
    // Counter to track duplicates
    final Map<String, int> stageCount = {};
    
    for (var stage in stages) {
      final stageName = stage['stageName'] as String;
      final language = stage['language'] ?? 'unknown';
      
      // Only process arcade stages
      if (stageName.toLowerCase().contains('arcade')) {
        // Count occurrences of this stage
        stageCount[stageName] = (stageCount[stageName] ?? 0) + 1;
        
        print('\nStage: $stageName [Lang: $language]');
        
        if (stage['questions'] != null && (stage['questions'] as List).isNotEmpty) {
          final questions = stage['questions'] as List;
          print('Total Questions: ${questions.length}');
          for (var i = 0; i < questions.length; i++) {
            final question = questions[i];
            print('Question ${i + 1}: ${question['question']}');
          }
        } else {
          print('No questions found for this stage');
        }
        print('-------------------');
      }
    }
    
    print('\nDuplicate Summary:');
    stageCount.forEach((stage, count) {
      if (count > 1) {
        print('$stage appears $count times');
      }
    });
    
    print('\n=== End of Stored Stages ===');
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SplashPage(selectedLanguage: _selectedLanguage),
          ),
        );
        return false;
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            // Calculate screen width
            final screenWidth = MediaQuery.of(context).size.width;
            
            // Calculate content width based on device type
            final contentWidth = sizingInformation.deviceScreenType == DeviceScreenType.mobile
                ? screenWidth  // Full width for mobile
                : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                    ? screenWidth  // Full width for tablet
                    : 1200.0;     // Max width for desktop
            
            // Calculate horizontal padding
            final horizontalPadding = sizingInformation.deviceScreenType == DeviceScreenType.mobile
                ? 0.0
                : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                    ? 0.0
                    : 0.0;

            return Stack(
              children: [
                // Background
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                
                // Main Content
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          // Header
                          HeaderSection(
                            selectedLanguage: _selectedLanguage,
                            onChangeLanguage: _changeLanguage,
                          ),
                          
                          // Scrollable Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                        ? 25  // Smaller spacing for mobile
                                        : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                                            ? 100  // Medium spacing for tablet
                                            : 150, // Larger spacing for desktop
                                  ),
                                  WelcomeSection(selectedLanguage: _selectedLanguage),
                                  SizedBox(
                                    height: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                        ? 150
                                        : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                                            ? 175
                                            : 200,
                                  ),
                                  AdventureSection(selectedLanguage: _selectedLanguage),
                                  SizedBox(
                                    height: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                        ? 100
                                        : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                                            ? 120
                                            : 150,
                                  ),
                                  ArcadeSection(selectedLanguage: _selectedLanguage),
                                  SizedBox(
                                    height: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                        ? 100
                                        : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                                            ? 120
                                            : 150,
                                  ),
                                  LearnMoreSection(selectedLanguage: _selectedLanguage),
                                  SizedBox(
                                    height: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                        ? 100
                                        : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                                            ? 120
                                            : 150,
                                  ),
                                  // Footer
                                  FooterWidget(selectedLanguage: _selectedLanguage),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}