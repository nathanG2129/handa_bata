import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/stage_models.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/dialog_boxes/stage_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ignore: must_be_immutable
class StagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category;
  String selectedLanguage;
  final String? savedGameDocId;

  StagesPage({
    super.key,
    required this.questName,
    required this.category,
    required this.selectedLanguage,
    this.savedGameDocId,
  });

  @override
  StagesPageState createState() => StagesPageState();
}

class StagesPageState extends State<StagesPage> {
  final StageService _stageService = StageService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _stages = [];
  String _selectedMode = 'Normal';
  bool _isUserProfileVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    try {
      print('Fetching stages for category ${widget.category['id']} in ${widget.selectedLanguage}');
      
      setState(() => _stages = []);

      // Use improved StageService with sync and caching
      await _stageService.synchronizeData();
      
      List<Map<String, dynamic>> stages = await _stageService.fetchStages(
        widget.selectedLanguage, 
        widget.category['id']!
      );
      
      if (mounted) {
        setState(() {
          // Filter out arcade stages
          _stages = stages.where((stage) => 
            !stage['stageName'].toLowerCase().contains('arcade')
          ).toList();
        });
      }

      // Prefetch next stages
      _prefetchNextStages(0);  // Start prefetching from first stage
    } catch (e) {
      print('Error fetching stages: $e');
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  // Add prefetch for next stages
  void _prefetchNextStages(int currentIndex) async {
    try {
      final categoryId = widget.category['id']!;
      GameSaveData? localData = await _authService.getLocalGameSaveData(categoryId);
      
      if (localData != null) {
        // Only prefetch if next stage is unlocked
        if (currentIndex + 1 < _stages.length && 
            localData.isStageUnlocked(currentIndex + 1, _selectedMode)) {
          _stageService.queueStageLoad(
            categoryId,
            GameSaveData.getStageKey(categoryId, currentIndex + 2), // +2 because stage numbers start at 1
            StagePriority.HIGH
          );

          // Also prefetch hard mode if normal mode is completed with stars
          if (_selectedMode == 'normal' && 
              localData.normalStageStars[currentIndex + 1] > 0) {
            _stageService.queueStageLoad(
              categoryId,
              GameSaveData.getStageKey(categoryId, currentIndex + 2),
              StagePriority.LOW
            );
          }
        }

        // Prefetch second next stage if unlocked
        if (currentIndex + 2 < _stages.length && 
            localData.isStageUnlocked(currentIndex + 2, _selectedMode)) {
          _stageService.queueStageLoad(
            categoryId,
            GameSaveData.getStageKey(categoryId, currentIndex + 3),
            StagePriority.MEDIUM
          );
        }
      }
    } catch (e) {
      print('❌ Error prefetching stages: $e');
    }
  }

  // Add retry mechanism
  Future<void> _retryLoading() async {
    await _fetchStages();
  }

  Future<Map<String, dynamic>> _fetchStageStats(int stageIndex) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'personalBest': 0, 'stars': 0, 'maxScore': 0, 'savedGame': null};
      }

      // Get local data using new GameSaveData structure
      final AuthService authService = AuthService();
      final GameSaveData? localData = await authService.getLocalGameSaveData(widget.category['id']!);
      
      if (localData != null) {
        // Use new helper methods from GameSaveData
        final stageKey = GameSaveData.getStageKey(
          widget.category['id']!,
          stageIndex + 1
        );
        
        // Get standardized stats format
        final stats = localData.getStageStats(stageKey, _selectedMode);

        // Check for saved game if savedGameDocId matches this stage
        Map<String, dynamic>? savedGame;
        if (widget.savedGameDocId != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? savedGameJson = prefs.getString('${GameStateKeys.SAVE_PREFIX}${widget.savedGameDocId}');
          if (savedGameJson != null) {
            savedGame = jsonDecode(savedGameJson);
          }
        }

        // Return stats in consistent format
        return {
          'personalBest': stats['personalBest'] ?? 0,
          'stars': stats['stars'] ?? 0,
          'maxScore': stats['maxScore'] ?? 0,
          'savedGame': savedGame,
        };
      }

      // Fallback to Firebase if no local data
      final docRef = FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('GameSaveData')
          .doc(widget.category['id']);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        return {'personalBest': 0, 'stars': 0, 'maxScore': 0, 'savedGame': null};
      }

      // Convert Firebase data to GameSaveData
      final gameSaveData = GameSaveData.fromMap(docSnapshot.data() as Map<String, dynamic>);
      
      // Use same helper methods for consistency
      final stageKey = GameSaveData.getStageKey(
        widget.category['id']!,
        stageIndex + 1
      );
      
      final stats = gameSaveData.getStageStats(stageKey, _selectedMode);

      // Check for saved game in Firebase
      Map<String, dynamic>? savedGame;
      if (widget.savedGameDocId != null) {
        final savedGameDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .collection('GameProgress')
            .doc(widget.savedGameDocId)
            .get();
        
        if (savedGameDoc.exists) {
          savedGame = savedGameDoc.data();
        }
      }

      return {
        'personalBest': stats['personalBest'] ?? 0,
        'stars': stats['stars'] ?? 0,
        'maxScore': stats['maxScore'] ?? 0,
        'savedGame': savedGame,
      };
    } catch (e) {
      print('❌ Error fetching stage stats: $e');
      return {'personalBest': 0, 'stars': 0, 'maxScore': 0, 'savedGame': null};
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

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUserProfileVisible) {
          setState(() {
            _isUserProfileVisible = false;
          });
          return false;
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdventurePage(selectedLanguage: widget.selectedLanguage),
            ),
          );
          return false;
        }
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
                              builder: (context) => AdventurePage(selectedLanguage: widget.selectedLanguage),
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
                                        const SizedBox(width: 20), // Add spacing between text and buttons
                                        Column(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMode = 'Normal';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: _selectedMode == 'Normal' ? Colors.white : Colors.black, // Text color
                                                backgroundColor: _selectedMode == 'Normal' ? const Color(0xFF32c067) : const Color(0xFFD9D9D9), // Background color
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                                ),
                                                side: BorderSide(
                                                  color: _selectedMode == 'Normal' ? darken(const Color(0xFF32c067), 0.2) : const Color(0xFF1A0D30), // Darker border color
                                                  width: 4, // Thicker border width for bottom
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                              ),
                                              child: Text(
                                                'Normal',
                                                style: GoogleFonts.rubik(
                                                  color: _selectedMode == 'Normal' ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15), // Add spacing between buttons
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMode = 'Hard';
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: _selectedMode == 'Hard' ? Colors.white : Colors.black, // Text color
                                                backgroundColor: _selectedMode == 'Hard' ? Colors.red : const Color(0xFFD9D9D9), // Background color
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                                ),
                                                side: BorderSide(
                                                  color: _selectedMode == 'Hard' ? darken(Colors.red, 0.2) : const Color(0xFF1A0D30), // Darker border color
                                                  width: 4, // Thicker border width for bottom
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 39, vertical: 15),
                                              ),
                                              child: Text(
                                                'Hard',
                                                style: GoogleFonts.rubik(
                                                  color: _selectedMode == 'Hard' ? Colors.white : Colors.black,
                                                ),
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
                            SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 70,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final rowIndex = index ~/ 3;
                                  final columnIndex = index % 3;
                                  final isEvenRow = rowIndex % 2 == 0;
                                  final stageIndex = isEvenRow
                                      ? index
                                      : (rowIndex + 1) * 3 - columnIndex - 1;
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
                                      final stars = stageStats['stars'];
  
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  Map<String, dynamic> stageData = _stages[stageIndex];
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
                                                    stars,
                                                    widget.selectedLanguage, // Pass selectedLanguage
                                                    _stageService, // Pass the StageService instance
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
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: List.generate(3, (index) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0.0), // Add horizontal spacing
                                                  child: Transform.translate(
                                                    offset: Offset(0, index == 1 ? 10 : 0), // Lower the 2nd star
                                                    child: SvgPicture.string(
                                                      '''
                                                      <svg
                                                        xmlns="http://www.w3.org/2000/svg"
                                                        width="36"
                                                        height="36"
                                                        viewBox="0 0 12 11"
                                                      >
                                                        <path
                                                          d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
                                                          fill="${stars > index ? '#F1B33A' : '#453958'}"
                                                        />
                                                      </svg>
                                                      ''',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                childCount: _stages.length,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(
                              height: 20, // Adjust the height as needed
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
                  if (_isUserProfileVisible)
                    UserProfilePage(onClose: _toggleUserProfile, selectedLanguage: widget.selectedLanguage),
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