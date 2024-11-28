import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'play_page.dart';
import 'package:handabatamae/widgets/buttons/adventure_button.dart'; // Import AdventureButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'user_profile.dart'; // Import UserProfilePage
import 'package:handabatamae/models/stage_models.dart';
import 'package:handabatamae/services/auth_service.dart'; // Import AuthService

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
  _MeasureSizeState createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
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

class AdventurePage extends StatefulWidget {
  final String selectedLanguage;

  const AdventurePage({super.key, required this.selectedLanguage});

  @override
  AdventurePageState createState() => AdventurePageState();
}

class AdventurePageState extends State<AdventurePage> {
  final StageService _stageService = StageService();
  final AuthService _authService = AuthService();
  late StreamSubscription<List<Map<String, dynamic>>> _categorySubscription;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _categories = [];
  Map<String, GameSaveData> _categorySaveData = {};
  late String _selectedLanguage;
  bool _isUserProfileVisible = false;
  double _maxButtonHeight = 0.0;

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
          _maxButtonHeight = 0.0;
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
    final saveData = _categorySaveData[categoryId];
    
    if (saveData != null) {
      // Use cached game save data for prefetching
      for (int i = 0; i < saveData.unlockedNormalStages.length; i++) {
        if (saveData.unlockedNormalStages[i]) {
          _stageService.queueStageLoad(
            categoryId,
            GameSaveData.getStageKey(categoryId, i + 1),
            i == 0 ? StagePriority.HIGH : StagePriority.MEDIUM
          );
        } else {
          break;
        }
      }
    }
  }

  Future<void> _retryLoading() async {
    _categorySaveData.clear(); // Clear cache before retry
    await _initializeData();
  }

  void _sortCategories() {
    const order = ['Quake', 'Storm', 'Volcano', 'Drought', 'Flood', 'Tsunami'];
    _categories.sort((a, b) {
      final aIndex = order.indexOf(order.firstWhere((element) => a['name'].contains(element), orElse: () => ''));
      final bIndex = order.indexOf(order.firstWhere((element) => b['name'].contains(element), orElse: () => ''));
      return aIndex.compareTo(bIndex);
    });
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage)),
    );
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _initializeData(); // Fetch categories again with the new language
    });
  }

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
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

  void _onCategoryPressed(Map<String, dynamic> category) {
    // try {
    //   final stages = await _stageService.fetchStages(_selectedLanguage, category['id']);
      
    //   print('\n=== Category: ${category['name']} ===');
    //   for (var stage in stages) {
    //     print('\nStage ${stage['stageName']}:');
        
    //     final stageDoc = await _stageService.fetchStageDocument(
    //       _selectedLanguage, 
    //       category['id'], 
    //       stage['stageName']
    //     );
        
    //     if (stageDoc['questions'] != null) {
    //       List<dynamic> questions = stageDoc['questions'];
    //       for (int i = 0; i < questions.length; i++) {
    //         final question = questions[i];
    //         final type = question['type'] ?? 'Unknown';
    //         print('- Question ${i + 1}: $type');
    //       }
    //     }
    //   }
    //   print('\n==================\n');
    // } catch (e) {
    //   print('Error fetching stages: $e');
    // }

    // // Existing navigation code
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StagesPage(
          questName: category['name'],
          category: {
            'id': category['id'],
            'name': category['name'],
          },
          selectedLanguage: _selectedLanguage,
          gameSaveData: _categorySaveData[category['id']],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SizingInformation sizingInformation) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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

    // Get responsive values for buttons
    final adventureButtonSpacing = ResponsiveUtils.valueByDevice<double>(
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
          child: AdventureButton(
            onPressed: () {
              // Define the action for the Adventure button if needed
            },
          ),
        ),
        SizedBox(height: adventureButtonSpacing),
        // Wrap categories in a grid for tablet with consistent heights
        if (sizingInformation.deviceScreenType == DeviceScreenType.tablet)
          LayoutBuilder(
            builder: (context, constraints) {
              // First pass: measure all buttons and store measurements
              final measurements = _categories.map((category) {
                final buttonColor = _getButtonColor(category['name']);
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
                    backgroundColor: buttonColor,
                    borderColor: _darkenColor(buttonColor),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'],
                            style: GoogleFonts.vt323(
                              fontSize: titleFontSize,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['description'],
                            style: GoogleFonts.vt323(
                              fontSize: descriptionFontSize,
                              color: Colors.white,
                            ),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
                    children: _categories.map((category) {
                      final buttonColor = _getButtonColor(category['name']);
                      return SizedBox(
                        width: categoryButtonWidth,
                        height: _maxButtonHeight > 0 ? _maxButtonHeight : null,
                        child: Button3D(
                          width: categoryButtonWidth,
                          height: _maxButtonHeight > 0 ? _maxButtonHeight : null,
                          onPressed: () => _onCategoryPressed(category),
                          backgroundColor: buttonColor,
                          borderColor: _darkenColor(buttonColor),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['name'],
                                  style: GoogleFonts.vt323(
                                    fontSize: titleFontSize,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category['description'],
                                  style: GoogleFonts.vt323(
                                    fontSize: descriptionFontSize,
                                    color: Colors.white,
                                  ),
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          )
        // Single column layout for mobile and desktop
        else
          ...(_categories.map((category) {
            final buttonColor = _getButtonColor(category['name']);
            return Padding(
              padding: EdgeInsets.only(bottom: categorySpacing),
              child: Align(
                alignment: Alignment.center,
                child: Button3D(
                  width: categoryButtonWidth,
                  onPressed: () => _onCategoryPressed(category),
                  backgroundColor: buttonColor,
                  borderColor: _darkenColor(buttonColor),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'],
                          style: GoogleFonts.vt323(
                            fontSize: titleFontSize,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category['description'],
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
            );
          }).toList()),
        const SizedBox(height: 20),
      ],
    );
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
}