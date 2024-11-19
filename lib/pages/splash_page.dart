import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
      print('🚀 Starting data prefetch check...');
      setState(() => _isLoading = true);

      final bannerService = BannerService();
      final badgeService = BadgeService();
      final avatarService = AvatarService();
      final authService = AuthService();
      final stageService = StageService();

      print('🔧 Initializing UserProfileService...');
      UserProfileService.initialize(bannerService);

      // Check for server updates
      print('🔍 Checking for server-side updates...');
      bool hasUpdates = await stageService.hasServerUpdates();
      
      if (hasUpdates) {
        print('🔄 Server has newer data, forcing fresh fetch');
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
          print('👤 User found, updating maxScores...');
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
                      print('⚠️ Scores clamped for stage $key:');
                      print('Normal: ${value.scoreNormal} -> $clampedNormalScore');
                      print('Hard: ${value.scoreHard} -> $clampedHardScore');
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
              print('✅ Updated maxScores for category: $categoryId');
            }
          }
        }
      }

      // More thorough cache check
      print('🔍 Checking cached game assets...');
      
      final localBadges = await badgeService.getLocalBadges();
      final localBanners = await bannerService.getLocalBanners();
      final localStages = await stageService.getStagesFromLocal('raw', useRawCache: true);
      final localAvatars = await avatarService.fetchAvatars();

      print('📊 Found cached assets:');
      print('- Badges: ${localBadges.length}');
      print('- Banners: ${localBanners.length}');
      print('- Stages: ${localStages.length}');
      print('- Avatars: ${localAvatars.length}');

      // Check for minimum required assets or if fresh data is needed
      if (!hasUpdates && 
          localBadges.length >= 8 && 
          localBanners.length >= 8 && 
          localStages.length >= 8 && 
          localAvatars.length >= 8) {
        print('✅ Found existing cached game assets, skipping full prefetch');
        
        // Just fetch user-specific data
        final userProfile = await authService.getUserProfile();
        if (userProfile != null) {
          print('👤 Loading user-specific data only');
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
        print('📥 Fresh data needed, starting full prefetch...');
        
        // If we're here, we need to fetch game assets
        print('📥 No complete cached assets, starting full prefetch...');

        // Check connection quality first
        print('📡 Checking connection quality...');
        final connectionQuality = await avatarService.checkConnectionQuality();

        // Priority load current user's avatar
        print('👤 Checking user profile...');
        final userProfile = await authService.getUserProfile();
        
        // Fetch and store ALL categories
        print('📥 Fetching all categories...');
        final enCategories = await stageService.fetchCategories('en');
        final filCategories = await stageService.fetchCategories('fil');
        print('✅ Categories fetched - EN: ${enCategories.length}, FIL: ${filCategories.length}');

        // Adjust fetch strategy based on connection quality
        if (connectionQuality == ConnectionQuality.OFFLINE) {
          print('📱 Offline mode: Using cached data only');
          // Only load from cache, no background fetching
        } else if (connectionQuality == ConnectionQuality.POOR) {
          print('📡 Poor connection: Loading essential data only');
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
          print('🚀 Good connection: Loading all data');
          // Load everything with prioritization
          print('📥 Fetching stages for all categories...');
          
          // Fetch English stages
          for (var category in enCategories) {
            print('📥 Fetching EN stages for category: ${category['name']}');
            await stageService.fetchStages('en', category['id']);
          }

          // Fetch Filipino stages
          for (var category in filCategories) {
            print('📥 Fetching FIL stages for category: ${category['name']}');
            await stageService.fetchStages('fil', category['id']);
          }

          // Fetch ALL avatars
          print('📥 Fetching all avatars...');
          final avatars = await avatarService.fetchAvatars();
          print('✅ Avatars cached: ${avatars.length}');

          if (userProfile != null) {
            await avatarService.getAvatarDetails(userProfile.avatarId, priority: LoadPriority.CRITICAL);
          }

          // Fetch ALL badges
          print('📥 Fetching all badges...');
          if (userProfile != null) {
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.CURRENT_QUEST);
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.SHOWCASE);
            await badgeService.fetchBadgesWithPriority('Quake Quest', userProfile.badgeShowcase, priority: BadgePriority.MEDIUM);
          } else {
            await badgeService.fetchBadges();
          }

          // Fetch ALL banners
          print('📥 Fetching all banners...');
          if (userProfile != null) {
            if (userProfile.bannerId > 0) {
              await bannerService.getBannerDetails(userProfile.bannerId, priority: BannerPriority.CRITICAL);
            }
            await bannerService.fetchBannersWithLevel(priority: BannerPriority.MEDIUM, userLevel: userProfile.level);
          } else {
            await bannerService.fetchBanners();
          }
        }

        print('🎉 All data prefetched based on connection quality!');
        
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // Update last prefetch timestamp after successful fetch
        await stageService.updateLastPrefetchTimestamp();
      }
    } catch (e) {
      print('❌ Error during prefetch: $e');
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
            print('❌ Error creating guest account: $e');
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
      print('❌ Error in _checkSignInStatus: $e');
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
          ResponsiveBreakpoints(
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 800, name: TABLET),
              Breakpoint(start: 801, end: 1920, name: DESKTOP),
              Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
            child: MaxWidthBox(
              maxWidth: 1200,
              child: ResponsiveScaledBox(
                width: ResponsiveValue<double>(
                  context,
                  defaultValue: 450.0,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 450.0),
                    const Condition.between(start: 800, end: 1100, value: 800.0),
                    const Condition.between(start: 1000, end: 1200, value: 1000.0),
                  ],
                ).value,
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
                            _changeLanguage(newValue);
                          }
                        },
                      ),
                    ),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: (ResponsiveValue<double>(
                                  context,
                                  defaultValue: topPadding,
                                  conditionalValues: [
                                    const Condition.smallerThan(name: MOBILE, value: topPadding * 0.8),
                                    const Condition.largerThan(name: MOBILE, value: topPadding * 1.2),
                                  ],
                                ).value), // Provide a default value
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: TextWithShadow(
                                      text: SplashLocalization.translate('title', _selectedLanguage),
                                      fontSize: (ResponsiveValue<double>(
                                        context,
                                        defaultValue: titleFontSize,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: titleFontSize * 0.8),
                                          const Condition.largerThan(name: MOBILE, value: titleFontSize * 1.2),
                                        ],
                                      ).value), // Provide a default value
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, (ResponsiveValue<double>(
                                      context,
                                      defaultValue: verticalOffset,
                                      conditionalValues: [
                                        const Condition.smallerThan(name: MOBILE, value: verticalOffset * 0.8),
                                        const Condition.largerThan(name: MOBILE, value: verticalOffset * 1.2),
                                      ],
                                    ).value)), // Provide a default value
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: TextWithShadow(
                                        text: SplashLocalization.translate('subtitle', _selectedLanguage),
                                        fontSize: (ResponsiveValue<double>(
                                          context,
                                          defaultValue: subtitleFontSize,
                                          conditionalValues: [
                                            const Condition.smallerThan(name: MOBILE, value: subtitleFontSize * 0.8),
                                            const Condition.largerThan(name: MOBILE, value: subtitleFontSize * 1.2),
                                          ],
                                        ).value), // Provide a default value
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          SizedBox(
                            width: (ResponsiveValue<double>(
                              context,
                              defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                                Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                              ],
                            ).value), // Provide a default value
                            height: (ResponsiveValue<double>(
                              context,
                              defaultValue: buttonHeight,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                                const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                              ],
                            ).value), // Provide a default value
                            child: CustomButton(
                              text: SplashLocalization.translate('login', _selectedLanguage),
                              color: const Color(0xFF351B61),
                              textColor: Colors.white,
                              width: (ResponsiveValue<double>(
                                context,
                                defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                                conditionalValues: [
                                  Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                                  Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                                ],
                              ).value), // Provide a default value
                              height: (ResponsiveValue<double>(
                                context,
                                defaultValue: buttonHeight,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                                  const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                                ],
                              ).value), // Provide a default value
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage(selectedLanguage: _selectedLanguage)),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            height: (ResponsiveValue<double>(
                              context,
                              defaultValue: buttonSpacing,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: buttonSpacing * 0.8),
                                const Condition.largerThan(name: MOBILE, value: buttonSpacing * 1.2),
                              ],
                            ).value), // Provide a default value
                          ),
                          SizedBox(
                            width: (ResponsiveValue<double>(
                              context,
                              defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                                Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                              ],
                            ).value), // Provide a default value
                            height: (ResponsiveValue<double>(
                              context,
                              defaultValue: buttonHeight,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                                const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                              ],
                            ).value), // Provide a default value
                            child: CustomButton(
                              text: SplashLocalization.translate('play_now', _selectedLanguage),
                              color: const Color(0xFFF1B33A),
                              textColor: Colors.black,
                              width: (ResponsiveValue<double>(
                                context,
                                defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                                conditionalValues: [
                                  Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                                  Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                                ],
                              ).value), // Provide a default value
                              height: (ResponsiveValue<double>(
                                context,
                                defaultValue: buttonHeight,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                                  const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                                ],
                              ).value), // Provide a default value
                              onTap: () {
                                _checkSignInStatus(context);
                              },
                            ),
                          ),
                          SizedBox(
                            height: (ResponsiveValue<double>(
                              context,
                              defaultValue: bottomPadding,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: bottomPadding * 0.8),
                                const Condition.largerThan(name: MOBILE, value: bottomPadding * 1.2),
                              ],
                            ).value), // Provide a default value
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              SplashLocalization.translate('copyright', _selectedLanguage),
                              style: GoogleFonts.vt323(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: LoadingWidget(),
              ),
            ),
        ],
      ),
    );
  }
}