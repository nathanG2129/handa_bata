import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final bool isMobileLargeOrSmaller = 
            sizingInformation.deviceScreenType == DeviceScreenType.mobile &&
            MediaQuery.of(context).size.width <= 414;

        ResponsiveUtils.valueByDevice(
          context: context,
          mobile: isMobileLargeOrSmaller ? 8 : 12,
          tablet: 16,
          desktop: 20,
        );

        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(3, 0),
                child: Text(
                  PlayLocalization.translate('favoriteBadges', widget.selectedLanguage),
                  style: GoogleFonts.rubik(
                    fontSize: ResponsiveUtils.valueByDevice(
                      context: context,
                      mobile: isMobileLargeOrSmaller ? 14 : 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.valueByDevice(
                context: context,
                mobile: isMobileLargeOrSmaller ? 8 : 12,
                tablet: 16,
                desktop: 20,
              ),
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
                                width: ResponsiveUtils.valueByDevice(
                                  context: context,
                                  mobile: isMobileLargeOrSmaller ? 48 : 64,
                                  tablet: 80,
                                  desktop: 96,
                                ),
                                height: ResponsiveUtils.valueByDevice(
                                  context: context,
                                  mobile: isMobileLargeOrSmaller ? 48 : 64,
                                  tablet: 80,
                                  desktop: 96,
                                ),
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
              SizedBox(height: ResponsiveUtils.valueByDevice(
                context: context,
                mobile: isMobileLargeOrSmaller ? 1 : 5,
                tablet: 5,
                desktop: 5,
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _badgeShowcase.map((badgeId) {
                  final badge = badgeId != -1 ? _badgeCache[badgeId] : null;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.valueByDevice(
                          context: context,
                          mobile: isMobileLargeOrSmaller ? 10 : 14,
                          tablet: 14,
                          desktop: 18,
                        ),
                      ),
                      // Only show title if badge['title'] is not empty
                      child: badge != null && badge['title'].isNotEmpty 
                        ? Text(
                            badge['title'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rubik(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.valueByDevice(
                                context: context,
                                mobile: isMobileLargeOrSmaller ? 10 : 14,
                                tablet: 14,
                                desktop: 18,
                              ),
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
      },
    );
  }
}