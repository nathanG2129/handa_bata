import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file

class UserProfileStats extends StatelessWidget {
  final int totalBadges;
  final int totalStagesCleared;
  final String selectedLanguage;

  const UserProfileStats({
    super.key,
    required this.totalBadges,
    required this.totalStagesCleared,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum height for the text containers when the language is 'fil'
    final double maxHeight = selectedLanguage == 'fil' ? .0 : 40.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Card(
            color: const Color(0xFF4d278f), // Card color for Total Badges
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1), // Black border
              borderRadius: BorderRadius.zero, // Purely rectangular
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveValue<double>(
                  context,
                  defaultValue: 16.0,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 12.0),
                    const Condition.largerThan(name: MOBILE, value: 20.0),
                  ],
                ).value,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: maxHeight,
                        ),
                        child: Text(
                          PlayLocalization.translate('totalBadges', selectedLanguage),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                        ),
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveValue<double>(
                        context,
                        defaultValue: 8.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 6.0),
                          const Condition.largerThan(name: MOBILE, value: 10.0),
                        ],
                      ).value,
                      horizontal: ResponsiveValue<double>(
                        context,
                        defaultValue: 10.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 12.0),
                          const Condition.largerThan(name: MOBILE, value: 20.0),
                        ],
                      ).value,
                    ), // Larger padding for two-digit numbers
                    child: Text(
                      '$totalBadges',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: const Color(0xFF4d278f), // Card color for Stages Cleared
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1), // Black border
              borderRadius: BorderRadius.zero, // Purely rectangular
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveValue<double>(
                  context,
                  defaultValue: 16.0,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 12.0),
                    const Condition.largerThan(name: MOBILE, value: 20.0),
                  ],
                ).value,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          minHeight: maxHeight,
                        ),
                        child: Text(
                          PlayLocalization.translate('stagesCleared', selectedLanguage),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                        ),
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveValue<double>(
                        context,
                        defaultValue: 8.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 6.0),
                          const Condition.largerThan(name: MOBILE, value: 10.0),
                        ],
                      ).value,
                      horizontal: ResponsiveValue<double>(
                        context,
                        defaultValue: 10.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 12.0),
                          const Condition.largerThan(name: MOBILE, value: 20.0),
                        ],
                      ).value,
                    ), // Larger padding for two-digit numbers
                    child: Text(
                      '$totalStagesCleared',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}