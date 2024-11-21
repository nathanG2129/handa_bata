import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/stage_models.dart';
import 'package:handabatamae/pages/adventure_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/game_save_manager.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/dialog_boxes/stage_dialog.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget 
import 'package:handabatamae/widgets/buttons/button_3d.dart'; // Import Button3D

// ignore: must_be_immutable
class StagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category;
  String selectedLanguage;
  final GameSaveData? gameSaveData;
  final String? savedGameDocId;

  StagesPage({
    super.key,
    required this.questName,
    required this.category,
    required this.selectedLanguage,
    this.gameSaveData,
    this.savedGameDocId,
  });

  @override
  StagesPageState createState() => StagesPageState();
}

class StagesPageState extends State<StagesPage> {
  final GameSaveManager _gameSaveManager = GameSaveManager();
  final StageService _stageService = StageService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _stages = [];
  String _selectedMode = 'Normal';
  bool _isUserProfileVisible = false;
  GameSaveData? _gameSaveData; // Cached game save data from parent

  @override
  void initState() {
    super.initState();
    _gameSaveData = widget.gameSaveData; // Store the passed data
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    try {
      print('\n🎮 Stages Page - Fetching stages');
      print('📋 Category: ${widget.category['id']}');
      print('🌍 Language: ${widget.selectedLanguage}');
      
      await _stageService.debugCacheState();
      

      List<Map<String, dynamic>> stages = await _stageService.fetchStages(
        widget.selectedLanguage, 
        widget.category['id']!
      );
      
      if (mounted) {
        setState(() {
          _stages = stages.where((stage) => 
            !stage['stageName'].toLowerCase().contains('arcade')
          ).toList();
          print('✅ Loaded ${_stages.length} stages');
        });
      }

      if (_gameSaveData != null) {
        print('🎯 Prefetching next stages');
        _prefetchNextStages(0);
      }
    } catch (e) {
      print('❌ Error fetching stages: $e');
      if (mounted) {
      }
    }
  }

  void _prefetchNextStages(int currentIndex) async {
    try {
      // Use cached game save data for prefetching
      if (_gameSaveData != null) {
        if (currentIndex + 1 < _stages.length && 
            _gameSaveData!.isStageUnlocked(currentIndex + 1, _selectedMode)) {
          _stageService.queueStageLoad(
            widget.category['id']!,
            GameSaveData.getStageKey(widget.category['id']!, currentIndex + 2),
            StagePriority.HIGH
          );

          // Also prefetch hard mode if normal mode is completed with stars
          if (_selectedMode == 'normal' && 
              _gameSaveData!.normalStageStars[currentIndex + 1] > 0) {
            _stageService.queueStageLoad(
              widget.category['id']!,
              GameSaveData.getStageKey(widget.category['id']!, currentIndex + 2),
              StagePriority.LOW
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error prefetching stages: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchStageStats(int stageIndex) async {
    try {
      // Use cached game save data if available
      GameSaveData? saveData = _gameSaveData;
      
      // Fallback to loading if not cached
      if (saveData == null) {
        saveData = await _authService.getLocalGameSaveData(widget.category['id']!);
        _gameSaveData = saveData; // Cache for future use
      }

      // Get stage key
      final stageKey = GameSaveData.getStageKey(
        widget.category['id']!,
        stageIndex + 1
      );

      final stageName = 'Stage ${stageIndex + 1}';

      // Get saved game state from GameSaveManager (separate from GameSaveData)
      final savedGameState = await _gameSaveManager.getSavedGameState(
        categoryId: widget.category['id']!,
        stageName: stageName,
        mode: _selectedMode.toLowerCase(),
      );
      
      if (saveData != null) {
        // Get progress stats from GameSaveData
        final stats = saveData.getStageStats(stageKey, _selectedMode);
        return {
          'personalBest': stats['personalBest'] ?? 0,
          'stars': stats['stars'] ?? 0,
          'maxScore': stats['maxScore'] ?? 0,
          'savedGame': savedGameState?.toJson(), // Game state from GameSaveManager
          'isUnlocked': saveData.canUnlockStage(stageIndex, _selectedMode.toLowerCase()),
        };
      }

      return {
        'personalBest': 0,
        'stars': 0,
        'maxScore': 0,
        'savedGame': savedGameState?.toJson(),
        'isUnlocked': false,
      };
    } catch (e) {
      print('❌ Error fetching stage stats: $e');
      return {
        'personalBest': 0,
        'stars': 0,
        'maxScore': 0,
        'savedGame': null,
        'isUnlocked': false,
      };
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

  String _getLockSvg() {
    return '''
      <svg
        width="24"
        height="24"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
      >
        <path
          d="M15 2H9v2H7v4H4v14h16V8h-3V4h-2V2zm0 2v4H9V4h6zm-6 6h9v10H6V10h3zm4 3h-2v4h2v-4z"
          fill="#737373"
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
                                            Button3D(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMode = 'Normal';
                                                });
                                              },
                                              backgroundColor: _selectedMode == 'Normal' 
                                                ? const Color(0xFF32c067) 
                                                : const Color(0xFF351b61),
                                              borderColor: _selectedMode == 'Normal'
                                                ? darken(const Color(0xFF32c067))
                                                : const Color(0xFF1A0D30),
                                              width: 120,
                                              height: 60,
                                              child: Text(
                                                'NORMAL',
                                                style: GoogleFonts.rubik(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Button3D(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedMode = 'Hard';
                                                });
                                              },
                                              backgroundColor: _selectedMode == 'Hard' 
                                                ? Colors.red 
                                                : const Color(0xFF351b61),
                                              borderColor: _selectedMode == 'Hard'
                                                ? darken(Colors.red)
                                                : const Color(0xFF1A0D30),
                                              width: 120,
                                              height: 60,
                                              child: Text(
                                                'HARD',
                                                style: GoogleFonts.rubik(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
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
  
                                      // Add unlock check here
                                      bool isUnlocked = _gameSaveData?.canUnlockStage(
                                        stageIndex, 
                                        _selectedMode.toLowerCase()
                                      ) ?? false;
  
                                      return GestureDetector(
                                        onTap: isUnlocked ? () {
                                          // Show stage dialog only if unlocked
                                          showStageDialog(
                                            context,
                                            stageNumber,
                                            {
                                              'id': widget.category['id']!,
                                              'name': widget.category['name']!,
                                            },
                                            stageStats['maxScore'], // Pass maxScore
                                            _stages[stageIndex],
                                            _selectedMode,
                                            stageStats['personalBest'],
                                            stars,
                                            widget.selectedLanguage, // Pass selectedLanguage
                                            _stageService, // Pass the StageService instance
                                          );
                                        } : null,  // Null makes it non-clickable
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Column(
                                              children: [
                                                Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SvgPicture.string(
                                                      _getModifiedSvg(isUnlocked ? stageColor : const Color(0xFFD9D9D9)), // Use gray for locked stages
                                                      width: 100,
                                                      height: 100,
                                                    ),
                                                    if (isUnlocked)
                                                      Text(
                                                        '$stageNumber',
                                                        style: GoogleFonts.vt323(
                                                          fontSize: 36,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      )
                                                    else
                                                      SvgPicture.string(
                                                        _getLockSvg(),
                                                        width: 50,
                                                        height: 50,
                                                      ),
                                                  ],
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
                                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                                    child: Transform.translate(
                                                      offset: Offset(0, index == 1 ? 10 : 0),
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
                                                            fill="${isUnlocked && stars > index ? '#F1B33A' : '#453958'}"
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
                                        ),
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
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  const Spacer(), // Push the footer to the bottom
                                  FooterWidget(selectedLanguage: widget.selectedLanguage), // Add the footer here
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