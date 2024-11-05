import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/badge_details_dialog.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/auth_service.dart';

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
  late Future<List<Map<String, dynamic>>> _badgesFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ValueNotifier<BadgeFilter> _filterNotifier = ValueNotifier(BadgeFilter.myCollection);
  final AuthService _authService = AuthService();
  final ValueNotifier<List<int>> _selectedBadgesNotifier = ValueNotifier<List<int>>([]);

  @override
  void initState() {
    super.initState();
    _badgesFuture = BadgeService().fetchBadges();
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

    if (widget.selectionMode && widget.currentBadgeShowcase != null) {
      _selectedBadgesNotifier.value = widget.currentBadgeShowcase!
          .where((id) => id != -1)
          .toList();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filterNotifier.dispose();
    _selectedBadgesNotifier.dispose();
    super.dispose();
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

  void _handleFilterChange(BadgeFilter? newValue) {
    if (newValue != null) {
      _filterNotifier.value = newValue;
    }
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

  List<Map<String, dynamic>> _filterBadges(List<Map<String, dynamic>> badges, BadgeFilter filter, List<int> unlockedBadges) {
    if (filter == BadgeFilter.myCollection) {
      return badges.where((badge) => 
        unlockedBadges[badges.indexOf(badge)] == 1).toList();
    }
    
    if (filter == BadgeFilter.allBadges) return badges;
    
    String prefix = filter.toString().split('.').last.replaceAll('Badges', '').toLowerCase();
    if (prefix == 'arcade') {
      return badges.where((badge) => 
        (badge['img'] as String).startsWith('arcade')).toList();
    } else {
      return badges.where((badge) => 
        (badge['img'] as String).startsWith('$prefix-quest')).toList();
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
      List<int> paddedBadgeIds = List.from(badgeIds);
      while (paddedBadgeIds.length < 3) {
        paddedBadgeIds.add(-1);
      }
      
      final AuthService authService = AuthService();
      await authService.updateUserProfile('badgeShowcase', paddedBadgeIds);
      widget.onBadgesSelected?.call(paddedBadgeIds);
      _closeDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorite badges. Please try again.'),
          ),
        );
      }
    }
  }

  Widget _buildBadgeGrid(List<Map<String, dynamic>> badges, List<int> unlockedBadges) {
    return ValueListenableBuilder<BadgeFilter>(
      valueListenable: _filterNotifier,
      builder: (context, currentFilter, _) {
        var filteredBadges = _filterBadges(badges, currentFilter, unlockedBadges);
        
        final visibleBadges = widget.selectionMode
            ? filteredBadges.where((badge) {
                final index = badges.indexOf(badge);
                return unlockedBadges[index] == 1;
              }).toList()
            : filteredBadges;

        return Container(
          padding: EdgeInsets.all(
            ResponsiveValue<double>(
              context,
              defaultValue: 20.0,
              conditionalValues: [
                const Condition.smallerThan(name: MOBILE, value: 16.0),
                const Condition.largerThan(name: MOBILE, value: 24.0),
              ],
            ).value,
          ),
          child: GridView.builder(
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
            itemCount: visibleBadges.length,
            itemBuilder: (context, index) {
              final badge = visibleBadges[index];
              final originalIndex = badges.indexOf(badge);
              final isUnlocked = unlockedBadges[originalIndex] == 1;

              return ValueListenableBuilder<List<int>>(
                valueListenable: _selectedBadgesNotifier,
                builder: (context, selectedBadges, _) {
                  final isSelected = selectedBadges.contains(badge['id']);
                  
                  return Opacity(
                    opacity: widget.selectionMode ? (isUnlocked ? 1.0 : 0.5) : (isUnlocked ? 1.0 : 0.5),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.selectionMode && isUnlocked) {
                          _handleBadgeSelection(badge['id']);
                        } else if (!widget.selectionMode && isUnlocked) {
                          _showBadgeDetails(badge);
                        }
                      },
                      child: Card(
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
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    badge['title'] ?? 'Badge',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
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
          onPressed: selectedBadges.length == 3 
              ? () => _handleBadgeUpdate(selectedBadges)
              : null,
          child: const Text('Save Changes'),
        );
      },
    );
  }

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
                onTap: () {},
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    _badgesFuture,
                    _authService.getUserProfile(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data![0].isEmpty) {
                      return const Center(child: Text('No badges found.'));
                    } else {
                      if (!_animationController.isAnimating && !_animationController.isCompleted) {
                        _animationController.forward();
                      }
                      final badges = snapshot.data![0] as List<Map<String, dynamic>>;
                      final userProfile = snapshot.data![1] as UserProfile;
                      
                      return SlideTransition(
                        position: _slideAnimation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
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
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Container(
                                    color: const Color(0xFF241242),
                                    child: Column(
                                      children: [
                                        if (!widget.selectionMode)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: _buildFilterDropdown(),
                                          ),
                                        _buildBadgeGrid(badges, userProfile.unlockedBadge),
                                        if (widget.selectionMode) ...[
                                          Container(
                                            width: double.infinity,
                                            color: const Color(0xFF3A1A5F),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                            child: _buildSaveButton(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}