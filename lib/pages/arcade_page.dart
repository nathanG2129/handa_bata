import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'play_page.dart';
import 'leaderboards_page.dart'; // Import LeaderboardsPage
import 'package:handabatamae/widgets/buttons/arcade_button.dart'; // Import ArcadeButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:handabatamae/models/stage_models.dart';  // Add this import
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'package:handabatamae/widgets/buttons/button_3d.dart'; // Import Button3D
import 'package:handabatamae/models/game_save_data.dart'; // Import GameSaveData
import 'package:handabatamae/services/auth_service.dart'; // Import AuthService
import 'package:handabatamae/utils/category_text_utils.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/localization/leaderboards/localization.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    Key? key,
    required this.onChange,
    required this.child,
  }) : super(key: key);

  @override
  MeasureSizeState createState() => MeasureSizeState();
}

class MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size != null) {
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}

class ArcadePage extends StatefulWidget {
  final String selectedLanguage;

  const ArcadePage({super.key, required this.selectedLanguage});

  @override
  ArcadePageState createState() => ArcadePageState();
}

class ArcadePageState extends State<ArcadePage> {
  final StageService _stageService = StageService();
  final AuthService _authService = AuthService();
  late StreamSubscription<List<Map<String, dynamic>>> _categorySubscription;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _categories = [];
  Map<String, GameSaveData> _categorySaveData = {}; // Cache for all categories
  late String _selectedLanguage;
  bool _isUserProfileVisible = false;
  double _maxButtonHeight = 0.0;  // Add this line

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _initializeData();
    
    _categorySubscription = _stageService.categoryUpdates.listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          _sortCategories();
          _maxButtonHeight = 0.0;  // Reset max height when categories change
        });
      }
    });
  }

  @override
  void dispose() {
    _categorySubscription.cancel();
    _categorySaveData.clear(); // Clear cache on dispose
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categories = await _stageService.fetchCategories(_selectedLanguage);
      
      // Load and sync game save data
      setState(() => _isSyncing = true);
      
      await Future.wait(
        categories.map((category) async {
          try {
            final saveData = await _authService.getLocalGameSaveData(category['id']);
            if (saveData != null) {
              _categorySaveData[category['id']] = saveData;
            }
          } catch (e) {
          }
        })
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _sortCategories();
          _isLoading = false;
          _isSyncing = false;
        });
      }

      if (categories.isNotEmpty) {
        _prefetchFirstCategory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories';
          _isLoading = false;
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _prefetchFirstCategory() async {
    if (_categories.isEmpty) return;

    final categoryId = _categories.first['id'];
    final arcadeKey = GameSaveData.getArcadeKey(categoryId);
    
    // Queue stage load - let StageService handle caching internally
    _stageService.queueStageLoad(
      categoryId,
      arcadeKey,
      StagePriority.HIGH
    );
  }

  Future<void> _retryLoading() async {
    _categorySaveData.clear(); // Clear cache before retry
    await _initializeData();
  }

  void _onCategoryPressed(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArcadeStagesPage(
          questName: category['name'],
          category: {
            'id': category['id'],
            'name': category['name'],
          },
          selectedLanguage: _selectedLanguage,
          gameSaveData: _categorySaveData[category['id']], // Pass cached data
        ),
      ),
    );
  }

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _initializeData();
    });
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage)),
    );
  }

  Color _getButtonColor(String categoryName) {
    if (categoryName.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (categoryName.contains('Storm')) {
      return const Color(0xFF2C28E1);
    } else if (categoryName.contains('Flood')) {
      return const Color(0xFF2C62DE);
    } else if (categoryName.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (categoryName.contains('Drought')) {
      return const Color(0xFF8D6647);
    } else if (categoryName.contains('Tsunami')) {
      return const Color(0xFF033C72);
    } else {
      return Colors.grey;
    }
  }

  Color _darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  void _sortCategories() {
    const order = ['Quake', 'Storm', 'Volcano', 'Drought', 'Flood', 'Tsunami'];
    _categories.sort((a, b) {
      final aIndex = order.indexOf(order.firstWhere(
          (element) => a['name'].contains(element), 
          orElse: () => ''));
      final bIndex = order.indexOf(order.firstWhere(
          (element) => b['name'].contains(element), 
          orElse: () => ''));
      return aIndex.compareTo(bIndex);
    });
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
          fill="white"
        />
      </svg>
    ''';
  }

  bool _isCategoryUnlocked(String categoryId) {
    final saveData = _categorySaveData[categoryId];
    if (saveData == null) return false;
    
    // Check if all normal stages have stars (same as arcade_stages_page.dart)
    return !saveData.normalStageStars.contains(0);
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
          _navigateBack(context);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2C1B47),
        body: Stack(
          children: [
            // Background
            SvgPicture.asset(
              'assets/backgrounds/background.svg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Content
            ResponsiveBuilder(
              builder: (context, sizingInformation) {
                final maxWidth = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: double.infinity,
                  tablet: MediaQuery.of(context).size.width * 0.9,
                  desktop: 1200,
                );

                final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
                  context: context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 48.0,
                );

                return Column(
                  children: [
                    // Header
                    HeaderWidget(
                      selectedLanguage: _selectedLanguage,
                      onBack: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayPage(
                              title: '',
                              selectedLanguage: _selectedLanguage,
                            ),
                          ),
                        );
                      },
                      onChangeLanguage: _changeLanguage,
                    ),
                    // Main content with constrained width
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Constrained content
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                  child: _buildContent(context, sizingInformation),
                                ),
                              ),
                            ),
                            // Footer outside of constraints
                            FooterWidget(selectedLanguage: _selectedLanguage),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Overlays
            if (_isUserProfileVisible)
              UserProfilePage(
                onClose: _toggleUserProfile,
                selectedLanguage: _selectedLanguage,
              ),
            if (_isSyncing)
              const Positioned(
                top: 16,
                right: 16,
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SizingInformation sizingInformation) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final arcadeButtonSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 30.0,
      tablet: 40.0,
      desktop: 50.0,
    );

    final categoryButtonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 300.0,
      tablet: 350.0,
      desktop: 500.0,
    );

    final categorySpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
    );

    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 24.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final descriptionFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20.0,
      tablet: 22.0,
      desktop: 25.0,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ArcadeButton(
            onPressed: () {
              // Define the action for the Arcade button if needed
            },
          ),
        ),
        SizedBox(height: arcadeButtonSpacing),
        // Wrap categories in a grid for tablet with consistent heights
        if (sizingInformation.deviceScreenType == DeviceScreenType.tablet)
          LayoutBuilder(
            builder: (context, constraints) {
              // First pass: measure all buttons and store measurements
              final measurements = _categories.map((category) {
                final buttonColor = _getButtonColor(category['name']);
                final categoryText = getCategoryText(category['name'], _selectedLanguage);
                final isUnlocked = _isCategoryUnlocked(category['id']);
                final key = GlobalKey();

                return MeasureSize(
                  onChange: (Size size) {
                    if (size.height > _maxButtonHeight && mounted) {
                      setState(() {
                        _maxButtonHeight = size.height;
                      });
                    }
                  },
                  child: Button3D(
                    key: key,
                    width: categoryButtonWidth,
                    onPressed: () {},
                    backgroundColor: buttonColor.withOpacity(isUnlocked ? 1.0 : 0.5),
                    borderColor: _darkenColor(buttonColor).withOpacity(isUnlocked ? 1.0 : 0.5),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryText['name']!,
                                style: GoogleFonts.vt323(
                                  fontSize: titleFontSize,
                                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.8),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isUnlocked 
                                  ? categoryText['description']!
                                  : _selectedLanguage == 'fil'
                                    ? 'Kumpletuhin ang ${category["name"]} sa Adventure para i-unlock ang game mode na ito.'
                                    : 'Complete ${category["name"]} at Adventure to unlock this game mode.',
                                style: GoogleFonts.vt323(
                                  fontSize: descriptionFontSize,
                                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();

              // Add measurement widgets to the tree
              return Stack(
                children: [
                  // Invisible measurement widgets
                  Opacity(
                    opacity: 0,
                    child: Wrap(
                      spacing: categorySpacing,
                      runSpacing: categorySpacing,
                      children: measurements,
                    ),
                  ),
                  // Actual visible buttons with consistent height
                  Wrap(
                    spacing: categorySpacing,
                    runSpacing: categorySpacing,
                    alignment: WrapAlignment.center,
                    children: _buildCategoryButtons(
                      categoryButtonWidth,
                      _maxButtonHeight > 0 ? _maxButtonHeight : null,
                      titleFontSize,
                      descriptionFontSize,
                    ),
                  ),
                ],
              );
            },
          )
        // Single column layout for mobile and desktop
        else
          ..._buildCategoryButtons(
            categoryButtonWidth,
            null,
            titleFontSize,
            descriptionFontSize,
          ),
        // Leaderboards button
        Padding(
          padding: EdgeInsets.only(
            top: categorySpacing,
            bottom: categorySpacing,
          ),
          child: Button3D(
            width: categoryButtonWidth,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardsPage(
                    selectedLanguage: _selectedLanguage,  // Pass the language
                  ),
                ),
              );
            },
            backgroundColor: const Color.fromARGB(255, 37, 196, 100),
            borderColor: _darkenColor(const Color(0xFF28e172)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaderboards',
                    style: GoogleFonts.vt323(
                      fontSize: titleFontSize,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LeaderboardsLocalization.translate('description', _selectedLanguage),
                    style: GoogleFonts.vt323(
                      fontSize: descriptionFontSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildCategoryButtons(
    double width,
    double? height,
    double titleFontSize,
    double descriptionFontSize,
  ) {
    return _categories.map((category) {
      final buttonColor = _getButtonColor(category['name']);
      final categoryText = getCategoryText(category['name'], _selectedLanguage);
      final isUnlocked = _isCategoryUnlocked(category['id']);

      final lockIconSize = ResponsiveUtils.valueByDevice<double>(
        context: context,
        mobile: 32.0,
        tablet: 36.0,
        desktop: 40.0,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: SizedBox(
          width: width,
          height: height,
          child: Button3D(
            width: width,
            height: height,
            onPressed: () {
              if (isUnlocked) {
                _onCategoryPressed(category);
              }
            },
            backgroundColor: buttonColor.withOpacity(isUnlocked ? 1.0 : 0.5),
            borderColor: _darkenColor(buttonColor).withOpacity(isUnlocked ? 1.0 : 0.5),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryText['name']!,
                        style: GoogleFonts.vt323(
                          fontSize: titleFontSize,
                          color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isUnlocked 
                          ? categoryText['description']!
                          : _selectedLanguage == 'fil'
                            ? 'Kumpletuhin ang ${category["name"]} sa Adventure para i-unlock ang game mode na ito.'
                            : 'Complete ${category["name"]} at Adventure to unlock this game mode.',
                        style: GoogleFonts.vt323(
                          fontSize: descriptionFontSize,
                          color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    right: 5,
                    top: 0,
                    child: SvgPicture.string(
                      _getLockSvg(),
                      width: lockIconSize,
                      height: lockIconSize,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: GoogleFonts.vt323(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryLoading,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}