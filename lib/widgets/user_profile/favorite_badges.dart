import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file

class FavoriteBadges extends StatelessWidget {
  final String selectedLanguage;

  const FavoriteBadges({super.key, required this.selectedLanguage});

  @override
  Widget build(BuildContext context) {
    const double scaleFactor = 0.8; // Define the scale factor

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
          ), // Use Rubik font and white color
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
                color: const Color(0xFF4d278f), // Card color for badges
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveValue<double>(
                      context,
                      defaultValue: 20.0 * scaleFactor,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0 * scaleFactor),
                        const Condition.largerThan(name: MOBILE, value: 24.0 * scaleFactor),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40 * scaleFactor,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30 * scaleFactor),
                            const Condition.largerThan(name: MOBILE, value: 50 * scaleFactor),
                          ],
                        ).value,
                        color: Colors.amber,
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
                      Text(
                        'Badge 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16 * scaleFactor,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14 * scaleFactor),
                              const Condition.largerThan(name: MOBILE, value: 18 * scaleFactor),
                            ],
                          ).value,
                        ), // White text color
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveValue<double>(
                context,
                defaultValue: 16 * scaleFactor,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 12 * scaleFactor),
                  const Condition.largerThan(name: MOBILE, value: 20 * scaleFactor),
                ],
              ).value,
            ),
            Expanded(
              child: Card(
                color: const Color(0xFF4d278f), // Card color for badges
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveValue<double>(
                      context,
                      defaultValue: 20.0 * scaleFactor,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0 * scaleFactor),
                        const Condition.largerThan(name: MOBILE, value: 24.0 * scaleFactor),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40 * scaleFactor,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30 * scaleFactor),
                            const Condition.largerThan(name: MOBILE, value: 50 * scaleFactor),
                          ],
                        ).value,
                        color: Colors.amber,
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
                      Text(
                        'Badge 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16 * scaleFactor,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14 * scaleFactor),
                              const Condition.largerThan(name: MOBILE, value: 18 * scaleFactor),
                            ],
                          ).value,
                        ), // White text color
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveValue<double>(
                context,
                defaultValue: 16 * scaleFactor,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 12 * scaleFactor),
                  const Condition.largerThan(name: MOBILE, value: 20 * scaleFactor),
                ],
              ).value,
            ),
            Expanded(
              child: Card(
                color: const Color(0xFF4d278f), // Card color for badges
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    ResponsiveValue<double>(
                      context,
                      defaultValue: 20.0 * scaleFactor,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0 * scaleFactor),
                        const Condition.largerThan(name: MOBILE, value: 24.0 * scaleFactor),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40 * scaleFactor,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30 * scaleFactor),
                            const Condition.largerThan(name: MOBILE, value: 50 * scaleFactor),
                          ],
                        ).value,
                        color: Colors.amber,
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
                      Text(
                        'Badge 3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16 * scaleFactor,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14 * scaleFactor),
                              const Condition.largerThan(name: MOBILE, value: 18 * scaleFactor),
                            ],
                          ).value,
                        ), // White text color
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}