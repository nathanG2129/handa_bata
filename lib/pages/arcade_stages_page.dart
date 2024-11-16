import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/dialog_boxes/arcade_stage_dialog.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'package:handabatamae/models/stage_models.dart';  // Add this import
import '../services/game_save_manager.dart';

// ignore: must_be_immutable
class ArcadeStagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category;
  String selectedLanguage;
  final GameSaveData? gameSaveData;
  final String? savedGameDocId;

  ArcadeStagesPage({
    super.key,
    required this.questName,
    required this.category,
    required this.selectedLanguage,
    this.gameSaveData,
    this.savedGameDocId,
  });

  @override
  ArcadeStagesPageState createState() => ArcadeStagesPageState();
}

class ArcadeStagesPageState extends State<ArcadeStagesPage> {
  final StageService _stageService = StageService();
  final AuthService _authService = AuthService();
  final GameSaveManager _gameSaveManager = GameSaveManager();
  List<Map<String, dynamic>> _stages = [];
  List<Map<String, dynamic>> _categories = [];
  // ignore: unused_field
  bool _isLoading = true;
  GameSaveData? _gameSaveData; // Store passed game save data

  @override
  void initState() {
    super.initState();
    _gameSaveData = widget.gameSaveData; // Store passed data
    _fetchStages();
    _fetchCategories();
  }

  Future<void> _fetchStages() async {
    try {
      print('Fetching stages for category ${widget.category['id']} in ${widget.selectedLanguage}');
      
      setState(() => _isLoading = true);

      // Use improved StageService with sync and caching
      await _stageService.synchronizeData();
      
      List<Map<String, dynamic>> stages = await _stageService.fetchStages(
        widget.selectedLanguage, 
        widget.category['id']!
      );
      
      if (mounted) {
        setState(() {
          // Filter for arcade stages only
          _stages = stages.where((stage) => 
            stage['stageName'].toLowerCase().contains('arcade')
          ).toList();
          _isLoading = false;
        });
      }

      // Prefetch next stages
      _prefetchNextStages(0);  // Start prefetching from first stage
    } catch (e) {
      print('❌ Error fetching stages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _stageService.fetchCategories(widget.selectedLanguage);
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print('❌ Error fetching categories: $e');
    }
  }

  // Add prefetch for next stages
  void _prefetchNextStages(int currentIndex) async {
    try {
      final categoryId = widget.category['id']!;
      final arcadeKey = GameSaveData.getArcadeKey(categoryId);
      
      // Get current game save data
      GameSaveData? localData = await _authService.getLocalGameSaveData(categoryId);
      
      if (localData != null) {
        // Arcade stages are always available
        if (currentIndex + 1 < _stages.length) {
          _stageService.queueStageLoad(
            categoryId,
            arcadeKey,
            StagePriority.HIGH
          );
        }

        // Also prefetch next category's arcade stage if available
        if (_categories.length > 1) {
          final nextCategoryId = _categories[1]['id'];
          final nextArcadeKey = GameSaveData.getArcadeKey(nextCategoryId);
          
          _stageService.queueStageLoad(
            nextCategoryId,
            nextArcadeKey,
            StagePriority.MEDIUM
          );
        }
      }
    } catch (e) {
      print('❌ Error prefetching arcade stages: $e');
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

      // Get arcade key
      final arcadeKey = GameSaveData.getArcadeKey(widget.category['id']!);

      // Get saved game state from GameSaveManager
      final savedGameState = await _gameSaveManager.getSavedGameState(
        categoryId: widget.category['id']!,
        stageName: arcadeKey,
        mode: 'normal',
      );
      
      if (saveData != null) {
        // Get arcade stats from GameSaveData
        final stats = saveData.getStageStats(arcadeKey, 'normal');
        return {
          'bestRecord': stats['bestRecord'] ?? -1,
          'crntRecord': stats['crntRecord'] ?? -1,
          'savedGame': savedGameState?.toJson(),
        };
      }

      return {
        'bestRecord': -1,
        'crntRecord': -1,
        'savedGame': savedGameState?.toJson(),
      };
    } catch (e) {
      print('❌ Error fetching arcade stats: $e');
      return {
        'bestRecord': -1,
        'crntRecord': -1,
        'savedGame': null
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
                                            'normal',
                                            stageStats['bestRecord'],
                                            stageStats['crntRecord'],
                                            0,
                                            widget.selectedLanguage,
                                            _stageService,
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