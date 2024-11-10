import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/pages/badge_details_dialog.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';

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

  const BadgePage({
    super.key, 
    required this.onClose,
    this.selectionMode = false,
    this.currentBadgeShowcase,
    this.onBadgesSelected,
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

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeData();
    _setupSubscriptions();
    
    if (widget.selectionMode && widget.currentBadgeShowcase != null) {
      _selectedBadgesNotifier.value = widget.currentBadgeShowcase!
          .where((id) => id != -1)
          .toList();
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
    // Listen to both profile updates and badge updates
    _profileSubscription = _userProfileService.profileUpdates.listen((updatedProfile) {
      if (mounted) {
        setState(() {
          _unlockedBadges = updatedProfile.unlockedBadge;
          // Force refresh badges when profile updates
          _refreshBadges();
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
      _animationController.forward();

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
      child: GestureDetector(
        onTap: _closeDialog,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing dialog
                child: StreamBuilder<UserProfile>(
                  stream: _userProfileService.profileUpdates,
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.hasData) {
                      _unlockedBadges = profileSnapshot.data!.unlockedBadge;
                    }
                    
                    return StreamBuilder<bool>(
                      stream: _badgeService.syncStatus,
                      builder: (context, syncSnapshot) {
                        final isSyncing = syncSnapshot.data ?? false;
                        
                        return Stack(
                          children: [
                            _buildMainContent(),
                            if (isSyncing)
                              const Positioned(
                                top: 120,
                                right: 30,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF3A1A5F),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Center(
                  child: Text(
                    'Badges',
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: 42,
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildFilterDropdown(),
                                ),
                              _buildBadgeGrid(_badges),
                            ],
                          ),
                        ),
                      ),
                      if (widget.selectionMode)
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF3A1A5F),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          child: _buildSaveButton(),
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
  }

  Widget _buildFilterDropdown() {
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
                fontSize: 20,
              ),
              onChanged: _handleFilterChange,
              items: BadgeFilter.values.map((filter) => DropdownMenuItem(
                value: filter,
                child: Text(_getFilterName(filter)),
              )).toList(),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBadges(List<Map<String, dynamic>> badges, BadgeFilter filter) {
    print('🔍 Filtering badges:');
    print('Total badges: ${badges.length}');
    print('Unlocked badges array: $_unlockedBadges');

    if (filter == BadgeFilter.myCollection) {
      print('🎯 Filtering My Collection');
      var filteredBadges = badges.where((badge) {
        int badgeId = badge['id'] as int;
        bool isUnlocked = badgeId < _unlockedBadges.length && _unlockedBadges[badgeId] == 1;
        return isUnlocked;
      }).toList();
      print('Found ${filteredBadges.length} unlocked badges');
      return filteredBadges;
    }
    
    if (filter == BadgeFilter.allBadges) {
      print('📋 Showing all badges');
      return badges;
    }
    
    String prefix = filter.toString().split('.').last.replaceAll('Badges', '').toLowerCase();
    print('🏷️ Filtering by prefix: $prefix');
    if (prefix == 'arcade') {
      var filteredBadges = badges.where((badge) => 
        (badge['img'] as String).startsWith('arcade')).toList();
      print('Filtered arcade badges count: ${filteredBadges.length}');
      return filteredBadges;
    } else {
      var filteredBadges = badges.where((badge) => 
        (badge['img'] as String).startsWith('$prefix-quest')).toList();
      print('Filtered quest badges count: ${filteredBadges.length}');
      return filteredBadges;
    }
  }

  void _handleBadgeSelection(int badgeId) {
    List<int> currentSelection = List.from(_selectedBadgesNotifier.value);
    
    if (currentSelection.contains(badgeId)) {
      currentSelection.remove(badgeId);
    } else if (currentSelection.length < 3) {
      currentSelection.add(badgeId);
    } else {
      currentSelection.removeAt(0);
      currentSelection.add(badgeId);
    }
    
    _selectedBadgesNotifier.value = List.from(currentSelection);
  }

  Future<void> _handleBadgeUpdate(List<int> badgeIds) async {
    try {
      print('💾 Saving badge selection: $badgeIds');
      
      // Create a fixed-size List<int> with explicit typing
      final List<int> badgeShowcase = List<int>.filled(3, -1);
      
      // Copy selected badges (up to 3)
      for (var i = 0; i < badgeIds.length && i < 3; i++) {
        badgeShowcase[i] = badgeIds[i];
      }

      print('📝 Final badge showcase: $badgeShowcase');
      print('📝 Badge showcase type: ${badgeShowcase.runtimeType}');

      // Use UserProfileService instead of AuthService
      await _userProfileService.updateProfileWithIntegration('badgeShowcase', badgeShowcase);
      
      widget.onBadgesSelected?.call(badgeShowcase);
      _closeDialog();
    } catch (e) {
      print('❌ Error saving badge showcase: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating badges: $e')),
      );
    }
  }

  Widget _buildBadgeGrid(List<Map<String, dynamic>> badges) {
    return ValueListenableBuilder<BadgeFilter>(
      valueListenable: _filterNotifier,
      builder: (context, currentFilter, _) {
        var filteredBadges = _filterBadges(badges, currentFilter);
        
        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveValue<int>(
              context,
              defaultValue: 2,
              conditionalValues: [
                const Condition.largerThan(name: TABLET, value: 4),
              ],
            ).value,
            crossAxisSpacing: 0.0,
            mainAxisSpacing: 20.0,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredBadges.length,
          itemBuilder: (context, index) {
            final badge = filteredBadges[index];
            return FutureBuilder<Map<String, dynamic>?>(
              future: _badgeService.getBadgeDetails(badge['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final badgeData = snapshot.data ?? badge;
                // Build badge UI with badgeData
                return BadgeItem(
                  badge: badgeData,
                  isUnlocked: _unlockedBadges[badges.indexOf(badge)] == 1,
                  isSelected: _selectedBadgesNotifier.value.contains(badge['id']),
                  onTap: () => _handleBadgeTap(badge),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return ValueListenableBuilder<List<int>>(
      valueListenable: _selectedBadgesNotifier,
      builder: (context, selectedBadges, _) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.vt323(fontSize: 20),
          ),
          onPressed: selectedBadges.isNotEmpty 
              ? () => _handleBadgeUpdate(selectedBadges)
              : null,
          child: const Text('Save Changes'),
        );
      },
    );
  }

  void _handleBadgeTap(Map<String, dynamic> badge) {
    if (widget.selectionMode) {
      _handleBadgeSelection(badge['id']);
    } else {
      _showBadgeDetails(badge);
    }
  }

  Widget BadgeItem({
    required Map<String, dynamic> badge,
    required bool isUnlocked,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/badges/${badge['img']}',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(height: 5),
                Text(
                  badge['title'] ?? 'Badge',
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
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
        return BadgeDetailsDialog(badge: badge);
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
      print('Error refreshing badges: $e');
    }
  }

  // Add retry mechanism
  Future<void> _retryLoading() async {
    await _initializeData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}