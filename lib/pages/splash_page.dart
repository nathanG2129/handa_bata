import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'login_page.dart';
import 'package:handabatamae/services/auth_service.dart';
import '../widgets/buttons/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '/localization/splash/localization.dart'; // Import the localization file
import '../widgets/loading_widget.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SplashPage extends StatefulWidget {
  final String selectedLanguage;
  const SplashPage({super.key, required this.selectedLanguage});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  String _selectedLanguage = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    // Call prefetch after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchData();
    });
  }

  Future<void> _prefetchData() async {
    try {
      setState(() => _isLoading = true);

      final bannerService = BannerService();
      final badgeService = BadgeService();
      final avatarService = AvatarService();
      final authService = AuthService();
      final stageService = StageService();

      UserProfileService.initialize(bannerService);

      // Check for server updates
      bool hasUpdates = await stageService.hasServerUpdates();
      
      if (hasUpdates) {
        await stageService.clearLocalCache();
        
        // Fetch fresh data - English first since we'll use it for maxScore
        final enCategories = await stageService.fetchCategories('en');
        final filCategories = await stageService.fetchCategories('fil');
        
        // Fetch all English stages first
        Map<String, List<Map<String, dynamic>>> allEnStages = {};
        for (var category in enCategories) {
          allEnStages[category['id']] = await stageService.fetchStages('en', category['id']);
        }

        // Fetch Filipino stages (but don't use for maxScore)
        for (var category in filCategories) {
          await stageService.fetchStages('fil', category['id']);
        }

        // Get current user and their game save data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update maxScore for each category based on English stages
          for (var entry in allEnStages.entries) {
            String categoryId = entry.key;
            List<Map<String, dynamic>> stages = entry.value;
            
            // Get current game save data for this category
            GameSaveData? currentSave = await authService.getLocalGameSaveData(categoryId);
            if (currentSave != null) {
              // Create new game save data to get fresh maxScores
              GameSaveData freshSave = await authService.createInitialGameSaveData(stages);
              
              // Update existing save data with new maxScores but keep progress
              Map<String, StageDataEntry> updatedStageData = {};
              currentSave.stageData.forEach((key, value) {
                if (freshSave.stageData.containsKey(key)) {
                  if (value is AdventureStageData) {
                    // Clamp scores to new maxScore if it decreased
                    int newMaxScore = freshSave.stageData[key]!.maxScore;
                    int clampedNormalScore = value.scoreNormal > newMaxScore ? newMaxScore : value.scoreNormal;
                    int clampedHardScore = value.scoreHard > newMaxScore ? newMaxScore : value.scoreHard;
                    
                    updatedStageData[key] = AdventureStageData(
                      maxScore: newMaxScore,
                      scoreNormal: clampedNormalScore,
                      scoreHard: clampedHardScore,
                    );
                    
                    // Log if scores were clamped
                    if (value.scoreNormal > newMaxScore || value.scoreHard > newMaxScore) {
                    }
                  } else if (value is ArcadeStageData) {
                    // Arcade scores don't need clamping since they're time-based
                    updatedStageData[key] = ArcadeStageData(
                      maxScore: freshSave.stageData[key]!.maxScore,
                      bestRecord: value.bestRecord,
                      crntRecord: value.crntRecord,
                    );
                  }
                }
              });

              // Create updated save data
              GameSaveData updatedSave = GameSaveData(
                stageData: updatedStageData,
                normalStageStars: currentSave.normalStageStars,
                hardStageStars: currentSave.hardStageStars,
                unlockedNormalStages: currentSave.unlockedNormalStages,
                unlockedHardStages: currentSave.unlockedHardStages,
                hasSeenPrerequisite: currentSave.hasSeenPrerequisite,
              );

              // Save updated data
              await authService.saveGameSaveDataLocally(categoryId, updatedSave);
            }
          }
        }
      }

      // More thorough cache check
      
      final localBadges = await badgeService.getLocalBadges();
      final localBanners = await bannerService.getLocalBanners();
      final localStages = await stageService.getStagesFromLocal('raw', useRawCache: true);
      final localAvatars = await avatarService.fetchAvatars();


      // Check for minimum required assets or if fresh data is needed
      if (!hasUpdates && 
          localBadges.length >= 8 && 
          localBanners.length >= 8 && 
          localStages.length >= 8 && 
          localAvatars.length >= 8) {
        
        // Just fetch user-specific data
        final userProfile = await authService.getUserProfile();
        if (userProfile != null) {
          await avatarService.getAvatarDetails(userProfile.avatarId, priority: LoadPriority.CRITICAL);
          if (userProfile.bannerId > 0) {
            await bannerService.getBannerDetails(userProfile.bannerId, priority: BannerPriority.CRITICAL);
          }
          await badgeService.fetchBadgesWithPriority(
            'Quake Quest',
            userProfile.badgeShowcase,
            priority: BadgePriority.CURRENT_QUEST
          );
        }

        // Queue background syncs
        stageService.triggerBackgroundSync();
        badgeService.triggerBackgroundSync();
        bannerService.triggerBackgroundSync();
        avatarService.triggerBackgroundSync();
        
        setState(() => _isLoading = false);
        return;
      } else {
        
        // If we're here, we need to fetch game assets

        // Check connection quality first
        final connectionQuality = await avatarService.checkConnectionQuality();

        // Priority load current user's avatar
        final userProfile = await authService.getUserProfile();
        
        // Fetch and store ALL categories
        final enCategories = await stageService.fetchCategories('en');
        final filCategories = await stageService.fetchCategories('fil');

        // Adjust fetch strategy based on connection quality
        if (connectionQuality == ConnectionQuality.OFFLINE) {
          // Only load from cache, no background fetching
        } else if (connectionQuality == ConnectionQuality.POOR) {
          // Load only critical data
          if (userProfile != null) {
            await stageService.fetchStages('en', enCategories.first['id']);
            await avatarService.getAvatarDetails(userProfile.avatarId, priority: LoadPriority.CRITICAL);
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.CURRENT_QUEST);
            if (userProfile.bannerId > 0) {
              await bannerService.getBannerDetails(userProfile.bannerId, priority: BannerPriority.CRITICAL);
            }
            await stageService.fetchStages('en', enCategories.first['id']);
          }
        } else {
          // Load everything with prioritization
          
          // Fetch English stages
          for (var category in enCategories) {
            await stageService.fetchStages('en', category['id']);
          }

          // Fetch Filipino stages
          for (var category in filCategories) {
            await stageService.fetchStages('fil', category['id']);
          }

          // Fetch ALL avatars
          await avatarService.fetchAvatars();

          if (userProfile != null) {
            await avatarService.getAvatarDetails(userProfile.avatarId, priority: LoadPriority.CRITICAL);
          }

          // Fetch ALL badges
          if (userProfile != null) {
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.CURRENT_QUEST);
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.SHOWCASE);
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.MEDIUM);
          } else {
            await badgeService.fetchBadges();
          }

          // Fetch ALL banners
          if (userProfile != null) {
            if (userProfile.bannerId > 0) {
              await bannerService.getBannerDetails(userProfile.bannerId, priority: BannerPriority.CRITICAL);
            }
            await bannerService.fetchBannersWithLevel(priority: BannerPriority.MEDIUM, userLevel: userProfile.level);
          } else {
            await bannerService.fetchBanners();
          }
        }

        
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // Update last prefetch timestamp after successful fetch
        await stageService.updateLastPrefetchTimestamp();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static const double titleFontSize = 90;
  static const double subtitleFontSize = 85;
  static const double buttonWidthFactor = 0.8;
  static const double buttonHeight = 55;
  static const double verticalOffset = -40.0;
  static const double topPadding = 210.0;
  static const double bottomPadding = 140.0;
  static const double buttonSpacing = 20.0;

  Future<void> _checkSignInStatus(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: LoadingWidget(),
            ),
          );
        },
      );

      AuthService authService = AuthService();
      bool isSignedIn = await authService.isSignedIn();

      if (!context.mounted) return;

      // Remove the loading dialog
      Navigator.of(context).pop();

      if (isSignedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
        );
      } else {
        // Check for local guest profile
        UserProfile? localGuestProfile = await authService.getLocalGuestProfile();

        if (!context.mounted) return;

        if (localGuestProfile != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
          );
        } else {
          // Create guest account with proper error handling
          try {
            // Show loading again for account creation
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: LoadingWidget(),
                  ),
                );
              },
            );

            UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
            if (userCredential.user != null) {
              await authService.createGuestProfile(userCredential.user!);
              
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Remove loading dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            Navigator.of(context).pop(); // Remove loading dialog
            
            // Show error dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to create guest account: $e'),
                  actions: [
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Remove loading dialog if still showing
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ResponsiveBuilder(
            builder: (context, sizingInformation) {
              return Stack(
                children: [
                  // Background
                  SvgPicture.asset(
                    'assets/backgrounds/background.svg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  
                  // Language Dropdown
                  Positioned(
                    top: ResponsiveUtils.valueByDevice(
                      context: context,
                      mobile: 40.0,
                      tablet: 50.0,
                      desktop: 60.0,
                    ),
                    right: ResponsiveUtils.valueByDevice(
                      context: context,
                      mobile: 25.0,
                      tablet: 30.0,
                      desktop: 35.0,
                    ),
                    child: _buildLanguageDropdown(),
                  ),
                  
                  // Main Content
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 600.0,
                            tablet: 800.0,
                            desktop: 1200.0,
                          ),
                        ),
                        child: _buildMainContent(context),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        // Top spacing - increased for tablet
        Spacer(
          flex: ResponsiveUtils.valueByDevice(
            context: context,
            mobile: 3,
            tablet: 5,  // Increased from 2 to push content down more on tablet
            desktop: 2,
          ),
        ),
        
        // Title Section
        _buildTitleSection(context),
        
        // Middle spacing
        Spacer(
          flex: ResponsiveUtils.valueByDevice(
            context: context,
            mobile: 2,
            tablet: 4,  // Increased from 3 to add more space between title and buttons
            desktop: 3,
          ),
        ),
        
        // Buttons Section
        _buildButtonsSection(context),
        
        // Bottom spacing
        Spacer(
          flex: ResponsiveUtils.valueByDevice(
            context: context,
            mobile: 1,  // Increased to push copyright down on mobile
            tablet: 3,  // Increased to push copyright down on tablet
            desktop: 2,
          ),
        ),
        
        // Copyright
        _buildCopyright(),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final titleSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 60.0,
      tablet: 80.0,
      desktop: 90.0,
    );

    final subtitleSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 55.0,
      tablet: 70.0,
      desktop: 85.0,
    );

    return Transform.translate(
      offset: Offset(
        0,
        ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20.0,
          tablet: 20.0,
          desktop: 0.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TextWithShadow(
              text: SplashLocalization.translate('title', _selectedLanguage),
              fontSize: titleSize,
            ),
          ),
          Transform.translate(
            offset: Offset(
              0,
              ResponsiveUtils.valueByDevice(
                context: context,
                mobile: -8.0,
                tablet: -15.0,
                desktop: -20.0,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TextWithShadow(
                text: SplashLocalization.translate('subtitle', _selectedLanguage),
                fontSize: subtitleSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    final buttonWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.8,  // Increased from 0.7
      tablet: MediaQuery.of(context).size.width * 0.5,
      desktop: 600.0,
    );

    final buttonHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 50.0,  // Increased from 45.0
      tablet: 55.0,
      desktop: 65.0,
    );

    final buttonSpacing = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 20.0,  // Increased from 15.0
      tablet: 30.0,
      desktop: 45.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 16.0,  // Reduced from 20.0
          tablet: 40.0,
          desktop: 60.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoginButton(buttonWidth, buttonHeight),
          SizedBox(height: buttonSpacing),
          _buildPlayNowButton(buttonWidth, buttonHeight),
        ],
      ),
    );
  }

  Widget _buildLoginButton(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomButton(
        text: SplashLocalization.translate('login', _selectedLanguage),
        color: const Color(0xFF351B61),
        textColor: Colors.white,
        width: width,
        height: height,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(selectedLanguage: _selectedLanguage)),
          );
        },
      ),
    );
  }

  Widget _buildPlayNowButton(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomButton(
        text: SplashLocalization.translate('play_now', _selectedLanguage),
        color: const Color(0xFFF1B33A),
        textColor: Colors.black,
        width: width,
        height: height,
        onTap: () => _checkSignInStatus(context),
      ),
    );
  }

  Widget _buildCopyright() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        SplashLocalization.translate('copyright', _selectedLanguage),
        style: GoogleFonts.vt323(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isDesktop = sizingInformation.deviceScreenType == DeviceScreenType.desktop;
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
        
        // Calculate icon size based on device type
        final iconSize = isDesktop ? 40.0 :
                        isTablet ? 36.0 : 32.0;
        
        // Calculate menu text size
        final menuTextSize = isDesktop ? 18.0 :
                           isTablet ? 16.0 : 14.0;

        return PopupMenuButton<String>(
          icon: SvgPicture.asset(
            'assets/icons/language_switcher.svg',
            width: iconSize,
            height: iconSize,
            color: Colors.white,
          ),
          padding: EdgeInsets.zero,
          offset: const Offset(0, 30),
          color: const Color(0xFF241242),
          onSelected: (String newValue) {
            _changeLanguage(newValue);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedLanguage == 'en' ? 'English' : 'Ingles',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'en') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'fil',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filipino',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: menuTextSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedLanguage == 'fil') 
                    SvgPicture.asset(
                      'assets/icons/check.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: LoadingWidget(),
      ),
    );
  }
}