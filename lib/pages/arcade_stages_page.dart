import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/arcade_stage_dialog.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_widget.dart'; // Import HeaderWidget
import '../widgets/footer_widget.dart'; // Import FooterWidget

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
  bool _isLoading = true;
  String _selectedMode = 'normal';

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
      _isLoading = false;
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
                        onToggleUserProfile: () {
                          // Define the action for toggling user profile if needed
                        },
                        onChangeLanguage: (String newValue) {
                          setState(() {
                            widget.selectedLanguage = newValue;
                            _fetchStages(); // Fetch stages again with the new language
                          });
                        },
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start, // Align to the start
                                children: [
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
                                        const SizedBox(width: 20), // Add spacing between text and buttons
                                        Column(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMode = 'normal';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: _selectedMode == 'normal' ? Colors.white : Colors.black, // Text color
                                                backgroundColor: _selectedMode == 'normal' ? const Color(0xFF32c067) : const Color(0xFFD9D9D9), // Background color
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                                ),
                                                side: BorderSide(
                                                  color: _selectedMode == 'normal' ? darken(const Color(0xFF32c067), 0.2) : const Color(0xFF1A0D30), // Darker border color
                                                  width: 4, // Thicker border width for bottom
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                              ),
                                              child: Text(
                                                'Normal',
                                                style: GoogleFonts.rubik(
                                                  color: _selectedMode == 'normal' ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10), // Reduce the space between the stage name and stage buttons
                                  Transform.translate(
                                    offset: const Offset(0, -30), // Move the stage buttons closer to the stage name and mode buttons
                                    child: _isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : GridView.builder(
                                            padding: const EdgeInsets.all(20),
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 80,
                                            ),
                                            itemCount: _stages.length,
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              final rowIndex = index ~/ 3;
                                              final columnIndex = index % 3;
                                              final isEvenRow = rowIndex % 2 == 0;
                                              final stageIndex = isEvenRow
                                                  ? index
                                                  : (rowIndex + 1) * 3 - columnIndex - 1;
                                              final stageNumber = stageIndex + 1;
                                              final stageCategory = widget.category['name'];
                                              final stageColor = _getStageColor(stageCategory);

                                              return GestureDetector(
                                                onTap: () async {
                                                  Map<String, dynamic> stageData = _stages[stageIndex];
                                                  Map<String, dynamic> stageStats = await _fetchStageStats(stageIndex);
                                                  if (!mounted) return;
                                                  showArcadeStageDialog(
                                                    context,
                                                    stageNumber,
                                                    {
                                                      'id': widget.category['id']!,
                                                      'name': widget.category['name']!,
                                                    },
                                                    stageData,
                                                    _selectedMode,
                                                    stageStats['personalBest'],
                                                    stageStats['crntRecord'], // Corrected to pass currentRecord
                                                    0, // Arcade stages do not have stars
                                                    widget.selectedLanguage,
                                                  );
                                                },
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
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const FooterWidget(), // Stick the footer to the bottom
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