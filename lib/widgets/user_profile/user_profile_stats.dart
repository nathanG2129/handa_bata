import 'dart:async'; // Add this for StreamSubscription
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../localization/play/localization.dart';
import '../../services/user_profile_service.dart'; // Fix path
import '../../models/user_model.dart'; // Fix path

class UserProfileStats extends StatefulWidget {
  final String selectedLanguage;
  final int totalBadges;
  final int totalStagesCleared;

  const UserProfileStats({
    super.key,
    required this.selectedLanguage,
    required this.totalBadges,
    required this.totalStagesCleared,
  });

  @override
  UserProfileStatsState createState() => UserProfileStatsState();
}

class UserProfileStatsState extends State<UserProfileStats> {
  final UserProfileService _userProfileService = UserProfileService();
  late StreamSubscription<UserProfile> _profileSubscription;

  int _totalBadges = 0;
  int _totalStages = 0;

  @override
  void initState() {
    super.initState();
    _totalBadges = widget.totalBadges;
    _totalStages = widget.totalStagesCleared;

    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted) {
        setState(() {
          _totalBadges = profile.totalBadgeUnlocked;
          _totalStages = profile.totalStageCleared;
        });
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum height for the text containers when the language is 'fil'
    final double maxHeight = widget.selectedLanguage == 'fil' ? .0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Card(
            color: const Color(0xFF4d278f), // Card color for Total Badges
            shape: const RoundedRectangleBorder(// Black border
              borderRadius: BorderRadius.zero, // Purely rectangular
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveValue<double>(
                  context,
                  defaultValue: 12.8,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 9.6),
                    const Condition.largerThan(name: MOBILE, value: 16.0),
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
                          PlayLocalization.translate('totalBadges', widget.selectedLanguage),
                          style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                        ),
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveValue<double>(
                        context,
                        defaultValue: 6.4,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 4.8),
                          const Condition.largerThan(name: MOBILE, value: 8.0),
                        ],
                      ).value,
                      horizontal: ResponsiveValue<double>(
                        context,
                        defaultValue: 8.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 9.6),
                          const Condition.largerThan(name: MOBILE, value: 16.0),
                        ],
                      ).value,
                    ), // Larger padding for two-digit numbers
                    child: Text(
                      '$_totalBadges',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.8),
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
                  defaultValue: 12.8,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 9.6),
                    const Condition.largerThan(name: MOBILE, value: 16.0),
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
                          PlayLocalization.translate('stagesCleared', widget.selectedLanguage),
                          style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                        ),
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveValue<double>(
                        context,
                        defaultValue: 6.4,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 4.8),
                          const Condition.largerThan(name: MOBILE, value: 8.0),
                        ],
                      ).value,
                      horizontal: ResponsiveValue<double>(
                        context,
                        defaultValue: 8.0,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 9.6),
                          const Condition.largerThan(name: MOBILE, value: 16.0),
                        ],
                      ).value,
                    ), // Larger padding for two-digit numbers
                    child: Text(
                      '$_totalStages',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
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