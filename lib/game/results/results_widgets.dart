import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/localization/results/localization.dart';
import 'package:responsive_builder/responsive_builder.dart';

Widget buildReactionWidget(int stars, String language) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      
      String message = stars == 0 ? ResultsLocalization.translate('niceTry', language) : 
                      stars == 1 ? ResultsLocalization.translate('goodJob', language) :
                      stars == 2 ? ResultsLocalization.translate('impressive', language) : 
                      ResultsLocalization.translate('outstanding', language);
                      
      return Column(
        children: [
          TextWithShadow(
            text: message,
            fontSize: isTablet ? 56 : 48,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Image.asset(
            stars == 0 
                ? 'assets/gifs/Defeat.gif'
                : 'assets/gifs/Victory.gif',
            height: isTablet ? 200 : 175,
            width: isTablet ? 200 : 175,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
          ),
        ],
      );
    }
  );
}

Widget buildStarsWidget(int stars) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      final starSize = isTablet ? 56.0 : 48.0;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          bool isLit = index < stars;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12.0 : 8.0
            ),
            child: SvgPicture.string(
              '''
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="$starSize"
                height="$starSize"
                viewBox="0 0 12 11"
              >
                <path
                  d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
                  fill="${isLit ? '#F1B33A' : '#453958'}"
                  stroke="${isLit ? '#F1B33A' : '#453958'}"
                  stroke-width="0.2"
                />
              </svg>
              ''',
              width: starSize,
              height: starSize,
            ),
          );
        }),
      );
    }
  );
}

Widget buildStatisticsWidget(int score, double accuracy, int streak, String language, {String? record}) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildStatisticItem(ResultsLocalization.translate('score', language), score.toString(), isTablet: isTablet),
          buildStatisticItem(ResultsLocalization.translate('accuracy', language), '${(accuracy * 100).toStringAsFixed(1)}%', isTablet: isTablet),
          buildStatisticItem(ResultsLocalization.translate('streak', language), streak.toString(), isTablet: isTablet),
          if (record != null) buildStatisticItem('Record', record, isTablet: isTablet),
        ],
      );
    }
  );
}

Widget buildStatisticItem(String label, String value, {bool isTablet = false}) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final refinedSize = sizingInformation.refinedSize;
      
      // Adjust padding and font sizes based on refined size
      double padding;
      double valueFontSize;
      double labelFontSize;
      double horizontalMargin;

      if (refinedSize == RefinedSize.small) {
        padding = 12.0;
        valueFontSize = 16.0;
        labelFontSize = 14.0;
        horizontalMargin = 4.0;
      } else if (refinedSize == RefinedSize.normal) {
        padding = 14.0;
        valueFontSize = 18.0;
        labelFontSize = 16.0;
        horizontalMargin = 6.0;
      } else if (isTablet) {
        padding = 20.0;
        valueFontSize = 24.0;
        labelFontSize = 22.0;
        horizontalMargin = 12.0;
      } else {
        padding = 16.0;
        valueFontSize = 20.0;
        labelFontSize = 18.0;
        horizontalMargin = 8.0;
      }

      return Container(
        padding: EdgeInsets.all(padding),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1D6E),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.rubik(
                fontSize: valueFontSize,
                color: Colors.white
              ),
            ),
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: labelFontSize,
                color: Colors.white
              ),
            ),
          ],
        ),
      );
    }
  );
}