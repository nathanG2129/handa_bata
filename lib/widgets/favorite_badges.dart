import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework

class FavoriteBadges extends StatelessWidget {
  const FavoriteBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Favorite Badges',
          style: GoogleFonts.rubik(
            fontSize: ResponsiveValue<double>(
              context,
              defaultValue: 18,
              conditionalValues: [
                const Condition.smallerThan(name: MOBILE, value: 16),
                const Condition.largerThan(name: MOBILE, value: 20),
              ],
            ).value,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ), // Use Rubik font and white color
        ),
        SizedBox(
          height: ResponsiveValue<double>(
            context,
            defaultValue: 10,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 8),
              const Condition.largerThan(name: MOBILE, value: 12),
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
                      defaultValue: 20.0,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0),
                        const Condition.largerThan(name: MOBILE, value: 24.0),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30),
                            const Condition.largerThan(name: MOBILE, value: 50),
                          ],
                        ).value,
                        color: Colors.amber,
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: 10,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 8),
                            const Condition.largerThan(name: MOBILE, value: 12),
                          ],
                        ).value,
                      ),
                      Text(
                        'Badge 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14),
                              const Condition.largerThan(name: MOBILE, value: 18),
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
                defaultValue: 16,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 12),
                  const Condition.largerThan(name: MOBILE, value: 20),
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
                      defaultValue: 20.0,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0),
                        const Condition.largerThan(name: MOBILE, value: 24.0),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30),
                            const Condition.largerThan(name: MOBILE, value: 50),
                          ],
                        ).value,
                        color: Colors.amber,
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: 10,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 8),
                            const Condition.largerThan(name: MOBILE, value: 12),
                          ],
                        ).value,
                      ),
                      Text(
                        'Badge 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14),
                              const Condition.largerThan(name: MOBILE, value: 18),
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
                defaultValue: 16,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 12),
                  const Condition.largerThan(name: MOBILE, value: 20),
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
                      defaultValue: 20.0,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16.0),
                        const Condition.largerThan(name: MOBILE, value: 24.0),
                      ],
                    ).value,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveValue<double>(
                          context,
                          defaultValue: 40,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 30),
                            const Condition.largerThan(name: MOBILE, value: 50),
                          ],
                        ).value,
                        color: Colors.amber,
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: 10,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 8),
                            const Condition.largerThan(name: MOBILE, value: 12),
                          ],
                        ).value,
                      ),
                      Text(
                        'Badge 3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14),
                              const Condition.largerThan(name: MOBILE, value: 18),
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