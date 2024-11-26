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
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/dialog_boxes/stage_dialog.dart';
import 'package:responsive_builder/responsive_builder.dart';
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
        });
      }

      if (_gameSaveData != null) {
        _prefetchNextStages(0);
      }
    } catch (e) {
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

  Widget _buildStageButton(BuildContext context, int index, double buttonSize) {
    final stageNumber = index + 1;
    final stageCategory = widget.category['name'];
    final stageColor = _getStageColor(stageCategory);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStageStats(index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Error loading stage stats'));
        }
        
        final stageStats = snapshot.data!;
        final stars = stageStats['stars'];
        final isUnlocked = stageStats['isUnlocked'];

        return GestureDetector(
          onTap: isUnlocked ? () {
            showStageDialog(
              context,
              stageNumber,
              {
                'id': widget.category['id']!,
                'name': widget.category['name']!,
              },
              stageStats['maxScore'],
              _stages[index],
              _selectedMode,
              stageStats['personalBest'],
              stars,
              widget.selectedLanguage,
              _stageService,
            );
          } : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.string(
                        _getModifiedSvg(isUnlocked ? stageColor : const Color(0xFFD9D9D9)),
                        width: ResponsiveUtils.valueByDevice<double>(
                          context: context,
                          mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100, // Smaller for mobile devices
                          tablet: 140,
                          desktop: 160,
                        ),
                        height: ResponsiveUtils.valueByDevice<double>(
                          context: context,
                          mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100, // Smaller for mobile devices
                          tablet: 140,
                          desktop: 160,
                        ),
                      ),
                      if (isUnlocked)
                        Text(
                          '$stageNumber',
                          style: GoogleFonts.vt323(
                            fontSize: ResponsiveUtils.valueByDevice<double>(
                              context: context,
                              mobile: MediaQuery.of(context).size.width <= 414 ? 28 : 32, // Smaller font for mobile
                              tablet: 35,
                              desktop: 40,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        SvgPicture.string(
                          _getLockSvg(),
                          width: buttonSize * 0.4,
                          height: buttonSize * 0.4,
                        ),
                    ],
                  ),
                  SizedBox(height: buttonSize * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (starIndex) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: MediaQuery.of(context).size.width <= 414 ? 2 : 4, // Tighter padding for mobile
                            tablet: 6,
                            desktop: 8,
                          ),
                        ),
                        child: SvgPicture.string(
                          '''
                          <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 12 11">
                            <path d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
                              fill="${isUnlocked && stars > starIndex ? '#F1B33A' : '#453958'}"/>
                          </svg>
                          ''',
                          width: ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: MediaQuery.of(context).size.width <= 414 ? 18 : 20, // Smaller stars for mobile
                            tablet: 24,
                            desktop: 28,
                          ),
                          height: ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: MediaQuery.of(context).size.width <= 414 ? 18 : 20, // Smaller stars for mobile
                            tablet: 24,
                            desktop: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SizingInformation sizingInformation) {
    final contentPadding = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 16,
      tablet: 32,
      desktop: 48,
    );

    final maxWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: double.infinity,
      tablet: MediaQuery.of(context).size.width * 0.7,
      desktop: 1200,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Main content with constraints
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: contentPadding),
                child: Column(
                  children: [
                    // Title Section with reduced bottom padding
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.valueByDevice<double>(
                          context: context,
                          mobile: 20,
                          tablet: 25,
                          desktop: 30,
                        ),
                        bottom: ResponsiveUtils.valueByDevice<double>(
                          context: context,
                          mobile: 0,
                          tablet: 5,
                          desktop: 10,
                        ),
                      ),
                      child: _buildTitleSection(sizingInformation),
                    ),
                    // Grid Section - add Transform.translate
                    Transform.translate(
                      offset: Offset(0, ResponsiveUtils.valueByDevice<double>(
                        context: context,
                        mobile: -40,    // Move up more on mobile
                        tablet: -50,    // Move up slightly less on tablet
                        desktop: -60,   // Move up least on desktop
                      )),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: 0,
                            tablet: 0,
                            desktop: 0,
                          ),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveUtils.valueByDevice<int>(
                              context: context,
                              mobile: 2,
                              tablet: 3,
                              desktop: 4,
                            ),
                            crossAxisSpacing: ResponsiveUtils.valueByDevice<double>(
                              context: context,
                              mobile: 0,
                              tablet: 0,
                              desktop: 20,
                            ),
                            mainAxisSpacing: ResponsiveUtils.valueByDevice<double>(
                              context: context,
                              mobile: 0,
                              tablet: 0,
                              desktop: 20,
                            ),
                            childAspectRatio: 1,
                          ),
                          itemCount: _stages.length,
                          itemBuilder: (context, index) {
                            final columnsPerRow = ResponsiveUtils.valueByDevice<int>(
                              context: context,
                              mobile: 2,
                              tablet: 3,
                              desktop: 4,
                            );
                            
                            final row = index ~/ columnsPerRow;
                            final isEvenRow = row.isEven;
                            
                            // For the last incomplete row
                            if (index >= _stages.length - (_stages.length % columnsPerRow) && 
                                _stages.length % columnsPerRow != 0) {
                              final itemsInLastRow = _stages.length % columnsPerRow;
                              final positionInLastRow = index % columnsPerRow;
                              
                              if (positionInLastRow < itemsInLastRow) {
                                // If the previous row was odd (snake pattern), align to the right
                                if (!isEvenRow) {
                                  final startOfLastRow = _stages.length - itemsInLastRow;
                                  final reversedPosition = itemsInLastRow - 1 - positionInLastRow;
                                  return _buildStageButton(
                                    context,
                                    startOfLastRow + reversedPosition,
                                    ResponsiveUtils.valueByDevice<double>(
                                      context: context,
                                      mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100,
                                      tablet: 140,
                                      desktop: 160,
                                    ),
                                  );
                                }
                                // If previous row was even, keep normal left alignment
                                return _buildStageButton(
                                  context,
                                  index,
                                  ResponsiveUtils.valueByDevice<double>(
                                    context: context,
                                    mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100,
                                    tablet: 140,
                                    desktop: 160,
                                  ),
                                );
                              }
                              return const SizedBox();
                            }

                            // Normal snake pattern for complete rows
                            final adjustedIndex = isEvenRow 
                              ? index 
                              : (row * columnsPerRow) + (columnsPerRow - 1) - (index % columnsPerRow);

                            return _buildStageButton(
                              context,
                              adjustedIndex,
                              ResponsiveUtils.valueByDevice<double>(
                                context: context,
                                mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100,
                                tablet: 140,
                                desktop: 160,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Spacing before footer
                    SizedBox(
                      height: ResponsiveUtils.valueByDevice<double>(
                        context: context,
                        mobile: 40,
                        tablet: 45,
                        desktop: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer - outside constraints to span full width
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF351B61),
              border: Border(
                top: BorderSide(color: Colors.white, width: 2.0),
              ),
            ),
            child: FooterWidget(selectedLanguage: widget.selectedLanguage),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(SizingInformation sizingInformation) {
    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 65,
      tablet: 75,
      desktop: 80,
    );

    final horizontalSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20,
      tablet: 25,
      desktop: 30,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            TextWithShadow(
              text: widget.questName.split(' ')[0],
              fontSize: titleFontSize,
            ),
            Transform.translate(
              offset: Offset(0, -titleFontSize * 0.35),
              child: TextWithShadow(
                text: widget.questName.split(' ')[1],
                fontSize: titleFontSize,
              ),
            ),
          ],
        ),
        SizedBox(width: horizontalSpacing),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildModeButtons(
            ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 100,
              tablet: 120,
              desktop: 140,
            ),
            ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 45,
              tablet: 60,
              desktop: 60,
            ),
            ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 15,
              tablet: 20,
              desktop: 20,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModeButtons(double width, double height, double spacing) {
    return [
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
        width: width,
        child: Text(
          'NORMAL',
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontSize: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(height: spacing),
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
        width: width,
        child: Text(
          'HARD',
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontSize: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUserProfileVisible) {
          setState(() => _isUserProfileVisible = false);
          return false;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdventurePage(selectedLanguage: widget.selectedLanguage),
          ),
        );
        return false;
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            return Stack(
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
                            builder: (context) => AdventurePage(
                              selectedLanguage: widget.selectedLanguage,
                            ),
                          ),
                        );
                      },
                      onChangeLanguage: (String newValue) {
                        setState(() {
                          widget.selectedLanguage = newValue;
                          _fetchStages();
                        });
                      },
                    ),
                    Expanded(
                      child: _buildContent(context, sizingInformation),
                    ),
                  ],
                ),
                if (_isUserProfileVisible)
                  UserProfilePage(
                    onClose: _toggleUserProfile,
                    selectedLanguage: widget.selectedLanguage,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}