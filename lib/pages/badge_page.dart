import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/pages/badge_details_dialog.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeFilter {
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

  const BadgePage({super.key, required this.onClose});

  @override
  _BadgePageState createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _badgesFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ValueNotifier<BadgeFilter> _filterNotifier = ValueNotifier(BadgeFilter.allBadges);

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filterNotifier.dispose();
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

  List<Map<String, dynamic>> _filterBadges(List<Map<String, dynamic>> badges, BadgeFilter filter) {
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
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _badgesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No badges found.'));
                    } else {
                      if (!_animationController.isAnimating && !_animationController.isCompleted) {
                        _animationController.forward();
                      }
                      final badges = snapshot.data!;
                      final filteredBadges = _filterBadges(badges, _filterNotifier.value);
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
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: _buildFilterDropdown(),
                                        ),
                                        ValueListenableBuilder<BadgeFilter>(
                                          valueListenable: _filterNotifier,
                                          builder: (context, currentFilter, _) {
                                            final filteredBadges = _filterBadges(badges, currentFilter);
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
                                                itemCount: filteredBadges.length,
                                                itemBuilder: (context, index) {
                                                  final badge = filteredBadges[index];
                                                  return GestureDetector(
                                                    onTap: () => _showBadgeDetails(badge),
                                                    child: Card(
                                                      color: Colors.transparent,
                                                      elevation: 0,
                                                      margin: const EdgeInsets.symmetric(vertical: 0.0), // Reduce the margin
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Image.asset(
                                                              'assets/badges/${badge['img']}',
                                                              width: 50,
                                                              height: 50,
                                                              fit: BoxFit.cover,
                                                              filterQuality: FilterQuality.none, // Make the image pixelated
                                                            ),
                                                            const SizedBox(height: 5), // Reduce the space between image and text
                                                            SizedBox(
                                                              width: 100, // Set the width to match the badge image
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
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
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