import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/pages/arcade_page.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/dialog_boxes/arcade_stage_dialog.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
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
  GameSaveData? _gameSaveData;

  @override
  void initState() {
    super.initState();
    _gameSaveData = widget.gameSaveData;
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    try {
      print('\n🎮 Arcade Stages Page - Fetching stages');
      print('📋 Category: ${widget.category['id']}');
      print('🌍 Language: ${widget.selectedLanguage}');
      
      await _stageService.debugCacheState();
      

      List<Map<String, dynamic>> stages = await _stageService.fetchStages(
        widget.selectedLanguage, 
        widget.category['id']!,
      );
      
      if (mounted) {
        setState(() {
          _stages = stages.where((stage) => 
            stage['stageName'].toLowerCase().contains('arcade')
          ).toList();
          print('✅ Loaded ${_stages.length} arcade stages');
        });
      }

      // Prefetch arcade stages for next category
      if (_gameSaveData != null) {
        print('🎯 Prefetching next arcade stages');
        _prefetchNextArcadeStages();
      }
    } catch (e) {
      print('❌ Error fetching arcade stages: $e');
      if (mounted) {
      }
    }
  }

  Future<void> _prefetchNextArcadeStages() async {
    try {
      final categories = await _stageService.fetchCategories(widget.selectedLanguage);
      final currentIndex = categories.indexWhere((c) => c['id'] == widget.category['id']);
      
      if (currentIndex >= 0 && currentIndex < categories.length - 1) {
        final nextCategory = categories[currentIndex + 1];
        print('🎯 Prefetching arcade stages for ${nextCategory['id']}');
        
        _stageService.queueStageLoad(
          nextCategory['id'],
          GameSaveData.getArcadeKey(nextCategory['id']),
          StagePriority.MEDIUM
        );
      }
    } catch (e) {
      print('❌ Error prefetching next arcade stages: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchStageStats(int stageIndex) async {
    try {
      GameSaveData? saveData = _gameSaveData;
      
      if (saveData == null) {
        saveData = await _authService.getLocalGameSaveData(widget.category['id']!);
        _gameSaveData = saveData;
      }

      final arcadeKey = GameSaveData.getArcadeKey(widget.category['id']!);

      final savedGameState = await _gameSaveManager.getSavedGameState(
        categoryId: widget.category['id']!,
        stageName: arcadeKey,
        mode: 'normal',
      );
      
      if (saveData != null) {
        final stats = saveData.getStageStats(arcadeKey, 'normal');
        
        final arcadeIndex = saveData.normalStageStars.length - 1;

        return {
          'bestRecord': stats['bestRecord'] ?? -1,
          'crntRecord': stats['crntRecord'] ?? -1,
          'savedGame': savedGameState?.toJson(),
          'isUnlocked': saveData.canUnlockStage(arcadeIndex, 'normal'),
        };
      }

      return {
        'bestRecord': -1,
        'crntRecord': -1,
        'savedGame': savedGameState?.toJson(),
        'isUnlocked': false,
      };
    } catch (e) {
      print('❌ Error fetching arcade stats: $e');
      return {
        'bestRecord': -1,
        'crntRecord': -1,
        'savedGame': null,
        'isUnlocked': false
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
                            builder: (context) => ArcadePage(selectedLanguage: widget.selectedLanguage),
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
              ],
            );
          },
        ),
      ),
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding),
                      child: Column(
                        children: [
                          // Title Section
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
                                mobile: 30,
                                tablet: 20,
                                desktop: 50,
                              ),
                            ),
                            child: _buildTitleSection(sizingInformation),
                          ),
                          // Arcade Stage - Single Stage Display
                          _buildArcadeStage(
                            context,
                            ResponsiveUtils.valueByDevice<double>(
                              context: context,
                              mobile: 100,
                              tablet: 140,
                              desktop: 180,
                            ),
                          ),
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
              ],
            ),
          ),
        ),
        // Footer - Now outside of ScrollView and Expanded
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            color: Color(0xFF351B61),
            border: Border(
              top: BorderSide(color: Colors.white, width: 2.0),
            ),
          ),
          child: FooterWidget(selectedLanguage: widget.selectedLanguage),
        ),
      ],
    );
  }

  Widget _buildTitleSection(SizingInformation sizingInformation) {
    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 65,
      tablet: 75,
      desktop: 80,
    );

    // Split the quest name and remove "Quest" if present
    final questWords = widget.questName.split(' ');
    final firstWord = questWords[0]; // This will be "Quake", "Storm", etc.

    return Column(
      children: [
        TextWithShadow(
          text: firstWord, // Just use the first word
          fontSize: titleFontSize,
        ),
        Transform.translate(
          offset: Offset(0, -titleFontSize * 0.35),
          child: TextWithShadow(
            text: 'Arcade', // Replace "Quest" with "Arcade"
            fontSize: titleFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildArcadeStage(BuildContext context, double buttonSize) {
    final stageCategory = widget.category['name'];
    final stageColor = _getStageColor(stageCategory);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStageStats(0),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Error loading stage stats'));
        }

        final stageStats = snapshot.data!;
        final isUnlocked = stageStats['isUnlocked'];

        return GestureDetector(
          onTap: isUnlocked ? () {
            showArcadeStageDialog(
              context,
              1,
              {
                'id': widget.category['id']!,
                'name': widget.category['name']!,
              },
              _stages[0],
              'normal',
              stageStats['bestRecord'],
              stageStats['crntRecord'],
              0,
              widget.selectedLanguage,
              _stageService,
            );
          } : null,
          child: Opacity(
            opacity: isUnlocked ? 1.0 : 0.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.string(
                  _getModifiedSvg(stageColor),
                  width: ResponsiveUtils.valueByDevice<double>(
                    context: context,
                    mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100,
                    tablet: 140,
                    desktop: 180,
                  ),
                  height: ResponsiveUtils.valueByDevice<double>(
                    context: context,
                    mobile: MediaQuery.of(context).size.width <= 414 ? 90 : 100,
                    tablet: 140,
                    desktop: 180,
                  ),
                ),
                Text(
                  '1',
                  style: GoogleFonts.rubik(
                    fontSize: ResponsiveUtils.valueByDevice<double>(
                      context: context,
                      mobile: MediaQuery.of(context).size.width <= 414 ? 20 : 24,
                      tablet: 35,
                      desktop: 45,
                    ),
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
  }
}

extension ColorExtension on Color {
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}