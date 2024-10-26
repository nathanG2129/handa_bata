import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/dialog_boxes/arcade_stage_dialog.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget

// ignore: must_be_immutable
class ArcadeStagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category;
  String selectedLanguage;

  ArcadeStagesPage({
    super.key, 
    required this.questName, 
    required this.category, 
    required this.selectedLanguage});

  @override
  ArcadeStagesPageState createState() => ArcadeStagesPageState();
}

class ArcadeStagesPageState extends State<ArcadeStagesPage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(widget.selectedLanguage, widget.category['id']!);
    stages = stages.where((stage) => stage['stageName'].contains('Arcade')).toList();
    setState(() {
      _stages = stages;
      print(stages);
    });
  }

  Future<Map<String, dynamic>> _fetchStageStats(int stageIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'personalBest': 0, 'crntRecord': 0};
  
    final docRef = FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('GameSaveData')
        .doc(widget.category['id']);
  
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return {'personalBest': 0, 'crntRecord': 0};
  
    final data = docSnapshot.data() as Map<String, dynamic>;
    final stageData = data['stageData'] as Map<String, dynamic>;
  
    // Find the stage key that contains "Arcade"
    String? arcadeStageKey;
    stageData.forEach((key, value) {
      if (key.contains('Arcade')) {
        arcadeStageKey = key;
      }
    });
  
    if (arcadeStageKey == null) {
      return {'personalBest': 0, 'crntRecord': 0};
    }
  
    final personalBest = stageData[arcadeStageKey]['bestRecord'] as int? ?? 0;
    final crntRecord = stageData[arcadeStageKey]['crntRecord'] as int? ?? 0;
  
    return {
      'personalBest': personalBest,
      'crntRecord': crntRecord,
    };
  }

  Color _getStageColor(String? category) {
    if (category == null) return Colors.grey;
    if (category.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (category.contains('Storm') || category.contains('Flood')) {
      return const Color(0xFF2C62DE);
    } else if (category.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (category.contains('Drought') || category.contains('Tsunami')) {
      return const Color(0xFF31111D);
    } else {
      return Colors.grey;
    }
  }

  Color darken(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  String _getModifiedSvg(Color color1) {
    Color color2 = darken(color1);
    return '''
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="100%"
      height="100%"
      viewBox="0 0 12 11"
      fill="none"
    >
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M8 0H4V1H2V2H1V4H0V7H1V9H2V10H4V11H8V10H10V9H11V7H12V4H11V2H10V1H8V0ZM8 1V2H10V4H11V7H10V9H8V10H4V9H2V7H1V4H2V2H4V1H8Z"
        fill="${color2.toHex()}"
      />
      <path
        d="M4 1H8V2H10V4H11V7H10V9H8V10H4V9H2V7H1V4H2V2H4V1Z"
        fill="${color1.toHex()}"
      />
    </svg>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ArcadePage(selectedLanguage: widget.selectedLanguage),
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
                        selectedLanguage: widget.selectedLanguage,
                        onBack: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArcadePage(selectedLanguage: widget.selectedLanguage),
                            ),
                          );
                        },
                        onChangeLanguage: (String newValue) {
                          setState(() {
                            widget.selectedLanguage = newValue;
                            _fetchStages(); // Fetch stages again with the new language
                          });
                        }, 
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate(
                                [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20), // Adjust the top padding as needed
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            TextWithShadow(
                                              text: widget.questName.split(' ')[0], // First word
                                              fontSize: 85,
                                            ),
                                            Transform.translate(
                                              offset: const Offset(0, -30), // Adjust the vertical offset as needed
                                              child: TextWithShadow(
                                                text: widget.questName.split(' ')[1], // Second word
                                                fontSize: 85,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10), // Reduce the space between the stage name and stage buttons
                                ],
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final stageIndex = index;
                                  final stageNumber = stageIndex + 1;
                                  final stageCategory = widget.category['name'];
                                  final stageColor = _getStageColor(stageCategory);
  
                                  return FutureBuilder<Map<String, dynamic>>(
                                    future: _fetchStageStats(stageIndex),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (!snapshot.hasData) {
                                        return const Center(child: Text('Error loading stage stats'));
                                      }
                                      final stageStats = snapshot.data!;
  
                                      return GestureDetector(
                                        onTap: () async {
                                          Map<String, dynamic> stageData = _stages[stageIndex];
                                          if (!mounted) return;
                                          showArcadeStageDialog(
                                            context,
                                            stageNumber,
                                            {
                                              'id': widget.category['id']!,
                                              'name': widget.category['name']!,
                                            },
                                            stageData,
                                            'normal', // Pass the mode as 'normal'
                                            stageStats['personalBest'],
                                            stageStats['crntRecord'], // Corrected to pass currentRecord
                                            0, // Arcade stages do not have stars
                                            widget.selectedLanguage,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SvgPicture.string(
                                                _getModifiedSvg(stageColor),
                                                width: 100,
                                                height: 100,
                                              ),
                                              Text(
                                                '$stageNumber',
                                                style: GoogleFonts.rubik(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _stages.length,
                              ),
                            ),
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  Spacer(), // Push the footer to the bottom
                                  FooterWidget(), // Add the footer here
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

extension ColorExtension on Color {
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}