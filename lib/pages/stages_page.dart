import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/stage_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

// ignore: must_be_immutable
class StagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category;
  String selectedLanguage;

  StagesPage({super.key, required this.questName, required this.category, required this.selectedLanguage});

  @override
  StagesPageState createState() => StagesPageState();
}

class StagesPageState extends State<StagesPage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;
  String _selectedMode = 'Normal';

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages(widget.selectedLanguage, widget.category['id']!); // Use the selected language
    if (!mounted) return;
    setState(() {
      _stages = stages;
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>> _fetchStageStats(int stageIndex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'personalBest': 0, 'stars': 0, 'maxScore': 0};

    final docRef = FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('GameSaveData')
        .doc(widget.category['id']);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return {'personalBest': 0, 'stars': 0, 'maxScore': 0};

    final data = docSnapshot.data() as Map<String, dynamic>;
    final stageData = data['stageData'] as Map<String, dynamic>;
    final stageKey = '${widget.category['id']}${stageIndex + 1}';

    if (_selectedMode == 'Normal') {
      final personalBest = stageData[stageKey]['scoreNormal'] as int;
      final maxScore = stageData[stageKey]['maxScore'] as int;
      final stars = data['normalStageStars'][stageIndex] as int;
      return {'personalBest': personalBest, 'stars': stars, 'maxScore': maxScore};
    } else {
      final personalBest = stageData[stageKey]['scoreHard'] as int;
      final maxScore = stageData[stageKey]['maxScore'] as int;
      final stars = data['hardStageStars'][stageIndex] as int;
      return {'personalBest': personalBest, 'stars': stars, 'maxScore': maxScore};
    }
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

  Color darken(Color color, [double amount = 0.1]) {
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
            builder: (context) => AdventurePage(selectedLanguage: widget.selectedLanguage),
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
                  Positioned(
                    top: 60,
                    left: 35,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 100, // Adjust the width as needed
                        maxHeight: 100, // Adjust the height as needed
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white), // Adjust the icon size and color as needed
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdventurePage(selectedLanguage: widget.selectedLanguage),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 35,
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.language, color: Colors.white, size: 40), // Larger icon
                      underline: Container(), // Remove underline
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'fil',
                          child: Text('Filipino'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            widget.selectedLanguage = newValue;
                            _fetchStages(); // Fetch stages again with the new language
                          });
                        }
                      },
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 90),
                        child: Column(
                          children: [
                            const TextWithShadow(text: 'Handa Bata', fontSize: 90),
                            Transform.translate(
                              offset: const Offset(0, -40),
                              child: const TextWithShadow(text: 'Mobile', fontSize: 85),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.questName.replaceAll(' ', '\n'), // Replace spaces with new lines
                              style: GoogleFonts.rubik(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center, // Center align the text
                            ),
                            const SizedBox(width: 40), // Add spacing between text and buttons
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedMode = 'Normal';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black, // Text color
                                    backgroundColor: _selectedMode == 'Normal' ? const Color(0xFF32c067) : const Color(0xFFD9D9D9), // Background color
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1A0D30), // Much darker border color
                                      width: 4, // Thicker border width for bottom
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Normal'),
                                ),
                                const SizedBox(height: 10), // Add spacing between buttons
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedMode = 'Hard';
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black, // Text color
                                    backgroundColor: _selectedMode == 'Hard' ? Colors.red : const Color(0xFFD9D9D9), // Background color
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1A0D30), // Much darker border color
                                      width: 4, // Thicker border width for bottom
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 39, vertical: 15),
                                  ),
                                  child: const Text('Hard'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _stages.length,
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
                                      showStageDialog(
                                        context,
                                        stageNumber,
                                        {
                                          'id': widget.category['id']!,
                                          'name': widget.category['name']!,
                                        },
                                        stageStats['maxScore'], // Pass maxScore
                                        stageData,
                                        _selectedMode,
                                        stageStats['personalBest'],
                                        stageStats['stars'],
                                        widget.selectedLanguage, // Pass selectedLanguage
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
                                          style: GoogleFonts.vt323(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
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