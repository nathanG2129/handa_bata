import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../localization/play/localization.dart';
import '../../services/badge_service.dart';

class FavoriteBadges extends StatelessWidget {
  final String selectedLanguage;
  final List<int> badgeShowcase;

  const FavoriteBadges({
    super.key, 
    required this.selectedLanguage,
    required this.badgeShowcase,
  });

  Future<List<Map<String, dynamic>>> _getBadgeDetails() async {
    try {
      final BadgeService badgeService = BadgeService();
      final List<Map<String, dynamic>> allBadges = await badgeService.fetchBadges();
      
      return badgeShowcase.map((badgeId) {
        return allBadges.firstWhere(
          (badge) => badge['id'] == badgeId,
          orElse: () => {'img': 'default.png', 'title': 'Badge'},
        );
      }).toList();
    } catch (e) {
      return List.generate(3, (index) => {'img': 'default.png', 'title': 'Badge'});
    }
  }

  @override
  Widget build(BuildContext context) {
    const double scaleFactor = 0.8;

    return Column(
      children: [
        Text(
          PlayLocalization.translate('favoriteBadges', selectedLanguage),
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
              List.generate(3, (index) => {'img': 'default.png', 'title': 'Badge ${index + 1}'});

            return Column(
              children: [
                // Badge images in colored containers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: badges.map((badge) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveValue<double>(
                          context,
                          defaultValue: 10 * scaleFactor,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 6 * scaleFactor),
                            const Condition.largerThan(name: MOBILE, value: 10 * scaleFactor),
                          ],
                        ).value,
                      ),
                      child: Card(
                        color: const Color(0xFF4d278f),
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Padding(
                            padding: EdgeInsets.all(
                              ResponsiveValue<double>(
                                context,
                                defaultValue: 12.0 * scaleFactor,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 8.0 * scaleFactor),
                                  const Condition.largerThan(name: MOBILE, value: 16.0 * scaleFactor),
                                ],
                              ).value,
                            ),
                            child: Center(
                              child: Image.asset(
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                // Badge titles below
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: 8 * scaleFactor,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 6 * scaleFactor),
                      const Condition.largerThan(name: MOBILE, value: 10 * scaleFactor),
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
                          defaultValue: 8 * scaleFactor,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 6 * scaleFactor),
                            const Condition.largerThan(name: MOBILE, value: 10 * scaleFactor),
                          ],
                        ).value,
                      ),
                      child: Text(
                        badge['title'] ?? 'Badge',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vt323(
                          color: Colors.black,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16 * scaleFactor,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14 * scaleFactor),
                              const Condition.largerThan(name: MOBILE, value: 18 * scaleFactor),
                            ],
                          ).value,
                        ),
                      ),
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