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
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'user_profile.dart'; // Import UserProfilePage
import 'package:handabatamae/models/stage_models.dart';
import 'package:handabatamae/services/auth_service.dart'; // Import AuthService

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

      // Load categories first
      final categories = await _stageService.fetchCategories(_selectedLanguage);
      
      // Load and sync game save data for all categories
      setState(() => _isSyncing = true);
      
      await Future.wait(
        categories.map((category) async {
          try {
            final saveData = await _authService.getLocalGameSaveData(category['id']);
            if (saveData != null) {
              _categorySaveData[category['id']] = saveData;
              
              // Sync with server if online
              await _authService.syncCategoryData(category['id']);
            }
          } catch (e) {
            print('❌ Error loading save data for category ${category['id']}: $e');
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

      // Prefetch first category's stages
      if (categories.isNotEmpty) {
        _prefetchFirstCategory();
      }
    } catch (e) {
      print('❌ Error initializing data: $e');
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
          gameSaveData: _categorySaveData[category['id']], // Pass cached data
        ),
      ),
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
                    'assets/backgrounds/background.svg', // Use the common background image
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Column(
                    children: [
                      HeaderWidget(
                        selectedLanguage: _selectedLanguage,
                        onBack: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage)),
                          );
                        },
                        onChangeLanguage: _changeLanguage, 
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  _buildContent(),
                                  const SizedBox(height: 20),
                                  const Spacer(), // Push the footer to the bottom
                                  const FooterWidget(), // Add the footer here
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isUserProfileVisible)
                    UserProfilePage(onClose: _toggleUserProfile, selectedLanguage: _selectedLanguage),
                  if (_isSyncing)
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
        const SizedBox(height: 30),
        ..._categories.map((category) {
          final buttonColor = _getButtonColor(category['name']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Align(
              alignment: Alignment.center,
              child: Button3D(
                width: 350,
                height: 215,
                onPressed: () => _onCategoryPressed(category),
                backgroundColor: buttonColor,
                borderColor: _darkenColor(buttonColor),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: GoogleFonts.vt323(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category['description'],
                        style: GoogleFonts.vt323(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}