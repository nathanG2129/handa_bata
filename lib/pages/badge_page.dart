import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/localization/badge/badge_localization.dart';
import 'package:handabatamae/pages/badge_details_dialog.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

enum BadgeFilter {
  myCollection,
  allBadges,
  quakeBadges,
  stormBadges,
  volcanoBadges,
  droughtBadges,
  tsunamiBadges,
  floodBadges,
  arcadeBadges
}

class BadgePage extends StatefulWidget {
  final VoidCallback onClose;
  final bool selectionMode;
  final List<int>? currentBadgeShowcase;
  final Function(List<int>)? onBadgesSelected;
  final String? currentQuest;
    final String selectedLanguage;

  const BadgePage({
    super.key, 
    required this.onClose,
    this.selectionMode = false,
    this.currentBadgeShowcase,
    this.onBadgesSelected,
    this.currentQuest,
    required this.selectedLanguage,
  });

  @override
  _BadgePageState createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> with SingleTickerProviderStateMixin {
  final BadgeService _badgeService = BadgeService();
  final UserProfileService _userProfileService = UserProfileService();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> _badges = [];
  List<int> _unlockedBadges = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final ValueNotifier<BadgeFilter> _filterNotifier = ValueNotifier(BadgeFilter.myCollection);
  final ValueNotifier<List<int>> _selectedBadgesNotifier = ValueNotifier<List<int>>([]);
  StreamSubscription<UserProfile>? _profileSubscription;
  final ValueNotifier<bool> _syncNotifier = ValueNotifier(false);
  StreamSubscription<bool>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeData();
    _setupSubscriptions();
    
    if (widget.selectionMode && widget.currentBadgeShowcase != null) {
      _selectedBadgesNotifier.value = List<int>.from(
        widget.currentBadgeShowcase!.where((id) => id != -1)
      );
    }
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupSubscriptions() {
    // Listen to profile updates
    _profileSubscription = _userProfileService.profileUpdates.listen((updatedProfile) {
      if (mounted) {
        setState(() {
          _unlockedBadges = updatedProfile.unlockedBadge;
          _refreshBadges();
        });
      }
    });

    // Add sync status subscription
    _syncSubscription = _badgeService.syncStatus.listen((isSyncing) {
      if (mounted) {
        _syncNotifier.value = isSyncing;
      }
    });

    // Listen to badge updates
    _badgeService.badgeUpdates.listen((badges) {
      if (mounted) {
        setState(() {
          _badges = badges;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load badges and profile in parallel
      final results = await Future.wait([
        _badgeService.fetchBadges(),
        _userProfileService.fetchUserProfile(),
      ]);

      if (!mounted) return;

      setState(() {
        _badges = results[0] as List<Map<String, dynamic>>;
        _unlockedBadges = (results[1] as UserProfile?)?.unlockedBadge ?? [];
        _isLoading = false;
      });

      // Ensure animation starts after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.forward();
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load badges. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Update the build method to use StreamBuilder for sync status
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background with gesture detector
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDialog,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            // Dialog content
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent background tap from closing
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _syncNotifier,
                    builder: (context, isSyncing, _) {
                      if (_isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_errorMessage != null) {
                        return _buildErrorState();
                      }

                      return ResponsiveBuilder(
                        builder: (context, sizingInformation) {
                          // Check for specific mobile breakpoints
                          final screenWidth = MediaQuery.of(context).size.width;
                          final bool isMobileSmall = screenWidth <= 375;
                          final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375;
                          final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414;
                          final bool isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;

                          // Calculate sizes based on device type
                          final double headerFontSize = isMobileSmall ? 28 : 
                                                      isMobileLarge ? 32 :
                                                      isMobileExtraLarge ? 36 :
                                                      isTablet ? 38 : 42;

                        final double gridPadding = isMobileSmall ? 14 : 
                                                 isMobileLarge ? 14 :
                                                 isMobileExtraLarge ? 14 :
                                                 isTablet ? 16 : 16;

                          final double badgeSize = isMobileSmall ? 48 : 
                                                 isMobileLarge ? 52 :
                                                 isMobileExtraLarge ? 55 :
                                                 isTablet ? 60 : 65;

                          final double titleFontSize = isMobileSmall ? 20 : 
                                                     isMobileLarge ? 20 :
                                                     isMobileExtraLarge ? 20 :
                                                     isTablet ? 22 : 24;

                          return SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveUtils.valueByDevice(
                                  context: context,
                                  mobile: MediaQuery.of(context).size.width * 0.9,
                                  tablet: MediaQuery.of(context).size.width * 0.6,
                                  desktop: 800,
                                ),
                                minHeight: MediaQuery.of(context).size.height * 0.7,
                                maxHeight: MediaQuery.of(context).size.height * 0.7,
                              ),
                              margin: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: ResponsiveUtils.valueByDevice(
                                  context: context,
                                  mobile: isMobileSmall ? 60 : 80,
                                  tablet: 90,
                                  desktop: 110,
                                ),
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: const Color(0xFF3A1A5F),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobileSmall ? 6 : 
                                                isTablet ? 10 : 8,
                                        horizontal: isMobileSmall ? 12 : 
                                                  isTablet ? 18 : 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          BadgePageLocalization.translate('badges', widget.selectedLanguage),
                                          style: GoogleFonts.vt323(
                                            color: Colors.white,
                                            fontSize: headerFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        color: const Color(0xFF241242),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  children: [
                                                    if (!widget.selectionMode)
                                                      Padding(
                                                        padding: EdgeInsets.all(gridPadding),
                                                        child: _buildFilterDropdown(titleFontSize),
                                                      ),
                                                    _buildBadgeGrid(
                                                      _badges,
                                                      badgeSize,
                                                      titleFontSize,
                                                      isTablet,
                                                      gridPadding,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (widget.selectionMode)
                                              Container(
                                                width: double.infinity,
                                                color: const Color(0xFF3A1A5F),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isMobileSmall ? 6 : 8,
                                                  horizontal: isMobileSmall ? 12 : 16,
                                                ),
                                                child: _buildSaveButton(titleFontSize),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(double titleFontSize) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A5F),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: ValueListenableBuilder<BadgeFilter>(
          valueListenable: _filterNotifier,
          builder: (context, currentFilter, _) {
            return DropdownButton<BadgeFilter>(
              isExpanded: true,
              value: currentFilter,
              dropdownColor: const Color(0xFF3A1A5F),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: titleFontSize,
              ),
              onChanged: _handleFilterChange,
              items: [
                DropdownMenuItem(
                  value: BadgeFilter.myCollection,
                  child: Text(BadgePageLocalization.translate('myCollection', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.allBadges,
                  child: Text(BadgePageLocalization.translate('all', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.quakeBadges,
                  child: Text(BadgePageLocalization.translate('quakeBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.stormBadges,
                  child: Text(BadgePageLocalization.translate('stormBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.volcanoBadges,
                  child: Text(BadgePageLocalization.translate('volcanoBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.droughtBadges,
                  child: Text(BadgePageLocalization.translate('droughtBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.tsunamiBadges,
                  child: Text(BadgePageLocalization.translate('tsunamiBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.floodBadges,
                  child: Text(BadgePageLocalization.translate('floodBadges', widget.selectedLanguage)),
                ),
                DropdownMenuItem(
                  value: BadgeFilter.arcadeBadges,
                  child: Text(BadgePageLocalization.translate('arcadeBadges', widget.selectedLanguage)),
                ),
              ].toList(),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBadges(List<Map<String, dynamic>> badges, BadgeFilter filter) {

    // Add handling for allBadges filter
    if (filter == BadgeFilter.allBadges) {
      // Queue all badges with MEDIUM priority
      for (var badge in badges) {
        _badgeService.queueBadgeLoad(badge['id'], BadgePriority.MEDIUM);
      }
      return badges; // Return all badges without filtering
    }

    if (filter == BadgeFilter.myCollection) {
      // Queue unlocked badges with HIGH priority
      for (var badge in badges) {
        if (_unlockedBadges.length > badge['id'] && _unlockedBadges[badge['id']] == 1) {
          _badgeService.queueBadgeLoad(badge['id'], BadgePriority.HIGH);
        }
      }
      return badges.where((badge) => 
        _unlockedBadges.length > badge['id'] && _unlockedBadges[badge['id']] == 1
      ).toList();
    }
    
    // Handle other filters with appropriate priorities
    String prefix = filter.toString().split('.').last
        .replaceAll('Badges', '').toLowerCase();
    
    if (prefix == 'arcade') {
      var filteredBadges = badges.where((badge) => 
        (badge['img'] as String).startsWith('arcade')).toList();
      // Queue arcade badges with MEDIUM priority
      for (var badge in filteredBadges) {
        _badgeService.queueBadgeLoad(badge['id'], BadgePriority.MEDIUM);
      }
      return filteredBadges;
    } else {
      var filteredBadges = badges.where((badge) => 
        (badge['img'] as String).startsWith('$prefix-quest')).toList();
      // Queue quest badges with appropriate priority
      for (var badge in filteredBadges) {
        _badgeService.queueBadgeLoad(
          badge['id'],
          prefix == widget.currentQuest?.toLowerCase() 
            ? BadgePriority.CURRENT_QUEST 
            : BadgePriority.MEDIUM
        );
      }
      return filteredBadges;
    }
  }

  void _handleBadgeSelection(int badgeId) {
    List<int> currentSelection = List<int>.from(_selectedBadgesNotifier.value);
    
    if (currentSelection.contains(badgeId)) {
      currentSelection.remove(badgeId);
    } else if (currentSelection.length < 3) {
      currentSelection.add(badgeId);
    } else {
      currentSelection.removeAt(0);
      currentSelection.add(badgeId);
    }
    
    _selectedBadgesNotifier.value = currentSelection;
  }

  Future<void> _handleBadgeUpdate(List<int> badgeIds) async {
    try {
      
      // Create a fixed-size List<int> with explicit typing
      final List<int> badgeShowcase = List<int>.filled(3, -1);
      
      // Copy selected badges (up to 3)
      for (var i = 0; i < badgeIds.length && i < 3; i++) {
        badgeShowcase[i] = badgeIds[i];
      }


      // Use UserProfileService instead of AuthService
      await _userProfileService.updateProfileWithIntegration('badgeShowcase', badgeShowcase);
      
      widget.onBadgesSelected?.call(badgeShowcase);
      _closeDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(BadgePageLocalization.translate('errorUpdatingBadge', widget.selectedLanguage) + e.toString())),
      );
    }
  }

  Widget _buildBadgeGrid(
    List<Map<String, dynamic>> badges,
    double badgeSize,
    double titleFontSize,
    bool isTablet,
    double gridPadding,
  ) {
    return ValueListenableBuilder<BadgeFilter>(
      valueListenable: _filterNotifier,
      builder: (context, currentFilter, _) {
        var filteredBadges = _filterBadges(badges, currentFilter);
        
        return GridView.builder(
          padding: EdgeInsets.all(gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: gridPadding,
            mainAxisSpacing: gridPadding * 2,
            childAspectRatio: isTablet ? 1.0 : 0.85,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredBadges.length,
          itemBuilder: (context, index) {
            final badge = filteredBadges[index];
            return ValueListenableBuilder<List<int>>(
              valueListenable: _selectedBadgesNotifier,
              builder: (context, selectedBadges, _) {
                final isSelected = selectedBadges.contains(badge['id']);
                final isUnlocked = _unlockedBadges.length > badge['id'] && 
                                 _unlockedBadges[badge['id']] == 1;
                
                return BadgeItem(
                  badge: badge,
                  isUnlocked: isUnlocked,
                  isSelected: isSelected,
                  badgeSize: badgeSize,
                  titleFontSize: titleFontSize,
                  onTap: () => widget.selectionMode 
                      ? _handleBadgeSelection(badge['id'])
                      : _showBadgeDetails(badge),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton(double fontSize) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: _selectedBadgesNotifier,
      builder: (context, selectedBadges, _) {
        final bool isEnabled = selectedBadges.isNotEmpty;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Button3D(
              backgroundColor: const Color(0xFFF1B33A),
              borderColor: const Color(0xFF8B5A00),
              onPressed: () {
                if (isEnabled) {
                  _handleBadgeUpdate(selectedBadges);
                }
              },
              child: Text(
                BadgePageLocalization.translate('saveChanges', widget.selectedLanguage),
                style: GoogleFonts.vt323(
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );    
      },
    );
  }

  Widget BadgeItem({
    required Map<String, dynamic> badge,
    required bool isUnlocked,
    required bool isSelected,
    required VoidCallback onTap,
    required double badgeSize,
    required double titleFontSize,
  }) {
    const double lockedOpacity = 0.5;
    const double unlockedOpacity = 1.0;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: const Color(0xFF9474CC), width: 2)
              : null,
          color: Colors.transparent,
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Opacity(
              opacity: isUnlocked ? unlockedOpacity : lockedOpacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: badgeSize,
                    height: badgeSize,
                    child: Image.asset(
                      'assets/badges/${badge['img']}',
                      width: badgeSize,
                      height: badgeSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    badge['title'] ?? BadgePageLocalization.translate('badge', widget.selectedLanguage),
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: titleFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _errorMessage!,
          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _retryLoading,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  String _getFilterName(BadgeFilter filter) {
    switch (filter) {
      case BadgeFilter.myCollection:
        return 'My Collection';
      case BadgeFilter.allBadges:
        return 'All Badges';
      case BadgeFilter.quakeBadges:
        return 'Quake Badges';
      case BadgeFilter.stormBadges:
        return 'Storm Badges';
      case BadgeFilter.volcanoBadges:
        return 'Volcano Badges';
      case BadgeFilter.droughtBadges:
        return 'Drought Badges';
      case BadgeFilter.tsunamiBadges:
        return 'Tsunami Badges';
      case BadgeFilter.floodBadges:
        return 'Flood Badges';
      case BadgeFilter.arcadeBadges:
        return 'Arcade Badges';
    }
  }

  void _handleFilterChange(BadgeFilter? newValue) {
    if (newValue != null) {
      _filterNotifier.value = newValue;
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BadgeDetailsDialog(
          badge: badge,
          selectedLanguage: widget.selectedLanguage,
        );
      },
    );
  }

  // Fix the refresh badges method
  Future<void> _refreshBadges() async {
    if (!mounted) return;
    
    try {
      final badges = await _badgeService.fetchBadges();
      setState(() {
        _badges = badges;
      });
    } catch (e) {
    }
  }

  // Add retry mechanism
  Future<void> _retryLoading() async {
    await _initializeData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _syncSubscription?.cancel();  // Cancel sync subscription
    _animationController.dispose();
    _selectedBadgesNotifier.dispose();
    super.dispose();
  }
}