import 'dart:async'; // Add this for StreamSubscription
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final bool isMobileLargeOrSmaller = 
            sizingInformation.deviceScreenType == DeviceScreenType.mobile &&
            MediaQuery.of(context).size.width <= 414;

        final double maxHeight = widget.selectedLanguage == 'fil' ? 40.0 : 32.0;
        final double padding = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: isMobileLargeOrSmaller ? 8 : 12,
          tablet: 16,
          desktop: 20,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
                color: const Color(0xFF4d278f),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
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
                          vertical: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: isMobileLargeOrSmaller ? 4 : 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                          horizontal: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: isMobileLargeOrSmaller ? 8 : 12,
                            tablet: 16,
                            desktop: 20,
                          ),
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
            SizedBox(
              width: ResponsiveUtils.valueByDevice(
                context: context,
                mobile: isMobileLargeOrSmaller ? 8 : 12,
                tablet: 16,
                desktop: 20,
              ),
            ),
            Expanded(
              child: Card(
                color: const Color(0xFF4d278f),
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
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
                          vertical: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: isMobileLargeOrSmaller ? 4 : 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                          horizontal: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: isMobileLargeOrSmaller ? 8 : 12,
                            tablet: 16,
                            desktop: 20,
                          ),
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
      },
    );
  }
}