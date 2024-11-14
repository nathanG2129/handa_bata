import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

Widget buildReactionWidget(int stars) {
  String reaction;
  
  switch (stars) {
    case 3:
      reaction = 'Excellent!';
      break;
    case 2:
      reaction = 'Great job!';
      break;
    case 1:
      reaction = 'Good effort!';
      break;
    default:
      reaction = 'Keep trying!';
  }
  
  return TextWithShadow(
    text: reaction,
    fontSize: 48,
  );
}

Widget buildStarsWidget(int stars) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (index) {
      bool isLit = index < stars;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SvgPicture.string(
          '''
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="48"
            height="48"
            viewBox="0 0 12 11"
          >
            <path
              d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
              fill="${isLit ? '#F1B33A' : '#453958'}"
              stroke="${isLit ? '#F1B33A' : '#453958'}"
              stroke-width="0.2"
            />
            ${isLit ? '''
              <path
                d="M6 2L7 4L9 4.5L7.5 6L8 8L6 7L4 8L4.5 6L3 4.5L5 4L6 2Z"
                fill="#FFD700"
              />
            ''' : ''}
          </svg>
          ''',
          width: 48,
          height: 48,
        ),
      );
    }),
  );
}

Widget buildRecordWidget(String record) {
  return buildStatisticItem('Record', record);
}

Widget buildStatisticsWidget(int score, double accuracy, int streak, {String? record}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      buildStatisticItem('Score', score.toString()),
      buildStatisticItem('Accuracy', '${(accuracy * 100).toStringAsFixed(1)}%'),
      buildStatisticItem('Streak', streak.toString()),
      if (record != null) buildRecordWidget(record), // Add the record widget if record is provided
    ],
  );
}

Widget buildStatisticItem(String label, String value) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    margin: const EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      color: const Color(0xFF3A1D6E), // Darker shade of the background color
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.rubik(fontSize: 20, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
        ),
      ],
    ),
  );
}