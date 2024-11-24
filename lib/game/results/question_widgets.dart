import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/localization/results/localization.dart';
import 'package:responsive_builder/responsive_builder.dart';

Widget buildMultipleChoiceQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      final refinedSize = sizingInformation.refinedSize;
      
      // Adjust sizes based on refined size
      double questionFontSize;
      double optionFontSize;
      double verticalPadding;
      double horizontalPadding;
      double numberWidth;

      if (refinedSize == RefinedSize.small) {
        questionFontSize = 16.0;
        optionFontSize = 14.0;
        verticalPadding = 8.0;
        horizontalPadding = 16.0;
        numberWidth = 36.0;
      } else if (refinedSize == RefinedSize.normal) {
        questionFontSize = 18.0;
        optionFontSize = 16.0;
        verticalPadding = 10.0;
        horizontalPadding = 20.0;
        numberWidth = 40.0;
      } else if (isTablet) {
        questionFontSize = 28.0;
        optionFontSize = 24.0;
        verticalPadding = 16.0;
        horizontalPadding = 32.0;
        numberWidth = 56.0;
      } else {
        questionFontSize = 20.0;
        optionFontSize = 18.0;
        verticalPadding = 12.0;
        horizontalPadding = 24.0;
        numberWidth = 48.0;
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: numberWidth),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'],
                            style: GoogleFonts.rubik(
                              fontSize: questionFontSize
                            ),
                          ),
                          SizedBox(height: verticalPadding),
                          ...question['options'].map<Widget>((option) {
                            bool isCorrect = option == question['correctAnswer'];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: verticalPadding
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(
                                    fontSize: optionFontSize
                                  )),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.rubik(
                                        fontSize: optionFontSize,
                                        color: isCorrect ? Colors.green : Colors.black,
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 3,
              bottom: 3,
              left: 2,
              child: Container(
                width: numberWidth,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.rubik(
                      fontSize: numberWidth / 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  );
}

Widget buildIdentificationQuestionWidget(BuildContext context, int index, Map<String, dynamic> question, String language) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      final refinedSize = sizingInformation.refinedSize;
      
      // Adjust sizes based on refined size
      double questionFontSize;
      double labelFontSize;
      double answerFontSize;
      double verticalPadding;
      double horizontalPadding;
      double numberWidth;

      if (refinedSize == RefinedSize.small) {
        questionFontSize = 16.0;
        labelFontSize = 14.0;
        answerFontSize = 14.0;
        verticalPadding = 8.0;
        horizontalPadding = 12.0;
        numberWidth = 36.0;
      } else if (refinedSize == RefinedSize.normal) {
        questionFontSize = 18.0;
        labelFontSize = 16.0;
        answerFontSize = 16.0;
        verticalPadding = 10.0;
        horizontalPadding = 16.0;
        numberWidth = 40.0;
      } else if (isTablet) {
        questionFontSize = 28.0;
        labelFontSize = 24.0;
        answerFontSize = 24.0;
        verticalPadding = 16.0;
        horizontalPadding = 24.0;
        numberWidth = 56.0;
      } else {
        questionFontSize = 20.0;
        labelFontSize = 18.0;
        answerFontSize = 18.0;
        verticalPadding = 12.0;
        horizontalPadding = 20.0;
        numberWidth = 48.0;
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: numberWidth + 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'],
                            style: GoogleFonts.rubik(fontSize: questionFontSize),
                          ),
                          SizedBox(height: verticalPadding),
                          Text(
                            ResultsLocalization.translate('correctAnswer', language),
                            style: GoogleFonts.rubik(
                              fontSize: labelFontSize,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(height: verticalPadding / 2),
                          Text(
                            question['correctAnswer'],
                            style: GoogleFonts.rubik(
                              fontSize: answerFontSize,
                              color: Colors.green,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 3,
              bottom: 3,
              left: 2,
              child: Container(
                width: numberWidth,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.rubik(
                      fontSize: numberWidth / 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  );
}

Widget buildFillInTheBlanksQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      final refinedSize = sizingInformation.refinedSize;
      
      // Adjust sizes based on refined size
      double questionFontSize;
      double answerFontSize;
      double verticalPadding;
      double horizontalPadding;
      double numberWidth;
      double blankPadding;

      if (refinedSize == RefinedSize.small) {
        questionFontSize = 16.0;
        answerFontSize = 14.0;
        verticalPadding = 8.0;
        horizontalPadding = 12.0;
        numberWidth = 36.0;
        blankPadding = 6.0;
      } else if (refinedSize == RefinedSize.normal) {
        questionFontSize = 18.0;
        answerFontSize = 16.0;
        verticalPadding = 10.0;
        horizontalPadding = 16.0;
        numberWidth = 40.0;
        blankPadding = 8.0;
      } else if (isTablet) {
        questionFontSize = 28.0;
        answerFontSize = 24.0;
        verticalPadding = 16.0;
        horizontalPadding = 24.0;
        numberWidth = 56.0;
        blankPadding = 12.0;
      } else {
        questionFontSize = 20.0;
        answerFontSize = 18.0;
        verticalPadding = 12.0;
        horizontalPadding = 20.0;
        numberWidth = 48.0;
        blankPadding = 10.0;
      }

      String formattedQuestion = question['question'];
      List<String> correctAnswers = question['correctAnswer'].split(',');
      List<InlineSpan> textSpans = [];
      int lastIndex = 0;

      for (int i = 0; i < correctAnswers.length; i++) {
        int inputIndex = formattedQuestion.indexOf('<input>', lastIndex);
        if (inputIndex == -1) break;

        if (inputIndex > lastIndex) {
          textSpans.add(TextSpan(
            text: formattedQuestion.substring(lastIndex, inputIndex),
            style: GoogleFonts.rubik(
              fontSize: questionFontSize,
              color: Colors.black
            ),
          ));
        }

        textSpans.add(WidgetSpan(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: blankPadding,
              vertical: blankPadding / 2
            ),
            margin: EdgeInsets.symmetric(
              horizontal: blankPadding / 2
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF241242),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Text(
              correctAnswers[i],
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: answerFontSize
              ),
            ),
          ),
        ));

        lastIndex = inputIndex + '<input>'.length;
      }

      if (lastIndex < formattedQuestion.length) {
        textSpans.add(TextSpan(
          text: formattedQuestion.substring(lastIndex),
          style: GoogleFonts.rubik(
            fontSize: questionFontSize,
            color: Colors.black
          ),
        ));
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: numberWidth + 16),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.rubik(
                            fontSize: questionFontSize,
                            color: Colors.black,
                            height: 1.5,
                            letterSpacing: 0.5
                          ),
                          children: textSpans,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 3,
              bottom: 3,
              left: 2,
              child: Container(
                width: numberWidth,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.rubik(
                      fontSize: numberWidth / 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  );
}

Widget buildMatchingTypeQuestionWidget(BuildContext context, int index, Map<String, dynamic> question, String language) {
  return ResponsiveBuilder(
    builder: (context, sizingInformation) {
      final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
      final refinedSize = sizingInformation.refinedSize;
      
      // Adjust sizes based on refined size
      double questionFontSize;
      double labelFontSize;
      double pairFontSize;
      double verticalPadding;
      double horizontalPadding;
      double numberWidth;

      if (refinedSize == RefinedSize.small) {
        questionFontSize = 16.0;
        labelFontSize = 14.0;
        pairFontSize = 14.0;
        verticalPadding = 8.0;
        horizontalPadding = 12.0;
        numberWidth = 36.0;
      } else if (refinedSize == RefinedSize.normal) {
        questionFontSize = 18.0;
        labelFontSize = 16.0;
        pairFontSize = 16.0;
        verticalPadding = 10.0;
        horizontalPadding = 16.0;
        numberWidth = 40.0;
      } else if (isTablet) {
        questionFontSize = 28.0;
        labelFontSize = 24.0;
        pairFontSize = 24.0;
        verticalPadding = 16.0;
        horizontalPadding = 24.0;
        numberWidth = 56.0;
      } else {
        questionFontSize = 20.0;
        labelFontSize = 18.0;
        pairFontSize = 18.0;
        verticalPadding = 12.0;
        horizontalPadding = 20.0;
        numberWidth = 48.0;
      }

      List<Map<String, dynamic>> correctPairs = List<Map<String, dynamic>>.from(question['correctPairs'] ?? []);
      
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: numberWidth + 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'],
                            style: GoogleFonts.rubik(fontSize: questionFontSize),
                          ),
                          SizedBox(height: verticalPadding),
                          Text(
                            ResultsLocalization.translate('correctPairs', language),
                            style: GoogleFonts.rubik(
                              fontSize: labelFontSize,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(height: verticalPadding / 2),
                          ...correctPairs.map((pair) {
                            String section1 = pair['section1']?.toString() ?? '';
                            String section2 = pair['section2']?.toString() ?? '';
                            return Padding(
                              padding: EdgeInsets.only(bottom: verticalPadding / 2),
                              child: Text(
                                '$section1 - $section2',
                                style: GoogleFonts.rubik(
                                  fontSize: pairFontSize,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 3,
              bottom: 3,
              left: 2,
              child: Container(
                width: numberWidth,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.rubik(
                      fontSize: numberWidth / 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  );
}