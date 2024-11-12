import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../localization/play/localization.dart';
import '../../services/badge_service.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_model.dart';

class FavoriteBadges extends StatefulWidget {
  final String selectedLanguage;
  final List<int> badgeShowcase;

  const FavoriteBadges({
    super.key, 
    required this.selectedLanguage,
    required this.badgeShowcase,
  });

  @override
  FavoriteBadgesState createState() => FavoriteBadgesState();
}

class FavoriteBadgesState extends State<FavoriteBadges> {
  final BadgeService _badgeService = BadgeService();
  final UserProfileService _userProfileService = UserProfileService();
  
  // Add state management
  late List<int> _badgeShowcase;
  final Map<int, Map<String, dynamic>> _badgeCache = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Add subscriptions
  late StreamSubscription<UserProfile> _profileSubscription;
  late StreamSubscription<List<Map<String, dynamic>>> _badgeSubscription;

  @override
  void initState() {
    super.initState();
    _badgeShowcase = List<int>.from(widget.badgeShowcase);
    _setupSubscriptions();
    _loadShowcaseBadges();
  }

  void _setupSubscriptions() {
    // Listen to profile updates for showcase changes
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted) {
        setState(() => _badgeShowcase = profile.badgeShowcase);
        _loadShowcaseBadges();  // Reload when showcase changes
      }
    });

    // Listen to badge updates
    _badgeSubscription = _badgeService.badgeUpdates.listen((badges) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadShowcaseBadges() async {
    try {
      // Queue showcase badges with high priority
      for (var badgeId in _badgeShowcase) {
        if (badgeId != -1) {
          _badgeService.queueBadgeLoad(badgeId, BadgePriority.SHOWCASE);
        }
      }

      // Get badge details
      final badges = await Future.wait(
        _badgeShowcase.map((id) => 
          id != -1 ? _badgeService.getBadgeDetails(id) : Future.value(null)
        )
      );

      if (!mounted) return;

      setState(() {
        for (int i = 0; i < _badgeShowcase.length; i++) {
          if (badges[i] != null) {
            _badgeCache[_badgeShowcase[i]] = badges[i]!;
          }
        }
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load badges';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    _badgeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scaleFactor = 0.9;

    return Column(
      children: [
        // Title section
        Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: const Offset(3, 0),
            child: Text(
              PlayLocalization.translate('favoriteBadges', widget.selectedLanguage),
              style: GoogleFonts.rubik(
                fontSize: ResponsiveValue<double>(
                  context,
                  defaultValue: 18 * scaleFactor,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 16 * scaleFactor),
                    const Condition.largerThan(name: MOBILE, value: 20 * scaleFactor),
                  ],
                ).value,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        SizedBox(
          height: ResponsiveValue<double>(
            context,
            defaultValue: 10 * scaleFactor,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 8 * scaleFactor),
              const Condition.largerThan(name: MOBILE, value: 12 * scaleFactor),
            ],
          ).value,
        ),
        // Content section
        if (_isLoading) 
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null) 
          Center(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.rubik(color: Colors.red),
            ),
          )
        else ...[  // Use spread operator for multiple widgets
          // Badge display section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _badgeShowcase.map((badgeId) {
              final badge = badgeId != -1 ? _badgeCache[badgeId] : null;
              return Expanded(
                child: Card(
                  color: const Color(0xFF4d278f),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Center(
                      child: badge != null && badge['img'].isNotEmpty 
                        ? Image.asset(
                            'assets/badges/${badge['img']}',
                            width: ResponsiveValue<double>(
                              context,
                              defaultValue: 64 * scaleFactor,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 48 * scaleFactor),
                                const Condition.largerThan(name: MOBILE, value: 80 * scaleFactor),
                              ],
                            ).value,
                            height: ResponsiveValue<double>(
                              context,
                              defaultValue: 64 * scaleFactor,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 48 * scaleFactor),
                                const Condition.largerThan(name: MOBILE, value: 80 * scaleFactor),
                              ],
                            ).value,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          )
                        : const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Badge titles section
          SizedBox(height: ResponsiveValue<double>(
            context,
            defaultValue: 3 * scaleFactor,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 1 * scaleFactor),
              const Condition.largerThan(name: MOBILE, value: 5 * scaleFactor),
            ],
          ).value),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _badgeShowcase.map((badgeId) {
              final badge = badgeId != -1 ? _badgeCache[badgeId] : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveValue<double>(
                      context,
                      defaultValue: 12 * scaleFactor,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 10 * scaleFactor),
                        const Condition.largerThan(name: MOBILE, value: 14 * scaleFactor),
                      ],
                    ).value,
                  ),
                  // Only show title if badge['title'] is not empty
                  child: badge != null && badge['title'].isNotEmpty 
                    ? Text(
                        badge['title'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rubik(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 12 * scaleFactor,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 10 * scaleFactor),
                              const Condition.largerThan(name: MOBILE, value: 14 * scaleFactor),
                            ],
                          ).value,
                        ),
                      )
                    : const SizedBox.shrink(), // Empty box when no title
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}