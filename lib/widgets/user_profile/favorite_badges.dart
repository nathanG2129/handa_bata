import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:collection/collection.dart';
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
  final UserProfileService _userProfileService = UserProfileService();
  final BadgeService _badgeService = BadgeService();
  late StreamSubscription<UserProfile> _profileSubscription;
  late StreamSubscription<List<Map<String, dynamic>>> _badgeSubscription;
  late List<int> _badgeShowcase;

  @override
  void initState() {
    super.initState();
    _badgeShowcase = List<int>.from(widget.badgeShowcase);
    
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted) {
        setState(() {
          _badgeShowcase = profile.badgeShowcase;
        });
      }
    });
    _badgeSubscription = _badgeService.badgeUpdates.listen((badges) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(FavoriteBadges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(oldWidget.badgeShowcase, widget.badgeShowcase)) {
      setState(() {
        _badgeShowcase = List<int>.from(widget.badgeShowcase);
      });
    }
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    _badgeSubscription.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getBadgeDetails() async {
    try {
      final List<Map<String, dynamic>> allBadges = await _badgeService.fetchBadges();
      
      return _badgeShowcase.map((badgeId) {
        if (badgeId == -1) {
          return {'img': '', 'title': ''};
        }
        return allBadges.firstWhere(
          (badge) => badge['id'] == badgeId,
          orElse: () => {'img': 'default.png', 'title': 'Badge'},
        );
      }).toList();
    } catch (e) {
      return List.generate(3, (index) => {'img': '', 'title': ''});
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scaleFactor = 0.9;

    return Column(
      children: [
            // Start of Selection
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(3, 0), // Adjust the offset as needed
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
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getBadgeDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final badges = snapshot.data ?? 
              List.generate(3, (index) => {'img': '', 'title': ''});

            return Column(
              children: [
                // Badge images in colored containers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: badges.map((badge) => Expanded(
                    child: Card(
                      color: const Color(0xFF4d278f),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Center(
                          child: badge['img'].isNotEmpty 
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
                            : const SizedBox.shrink(), // Empty box when no badge
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                // Badge titles below
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: 3 * scaleFactor,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 1 * scaleFactor),
                      const Condition.largerThan(name: MOBILE, value: 5 * scaleFactor),
                    ],
                  ).value,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: badges.map((badge) => Expanded(
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
                      child: badge['title'].isNotEmpty 
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
                  )).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}