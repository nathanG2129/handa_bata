import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildMultipleChoiceQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0), // Sharp corners
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 56), // Space for the correctness container
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['question'],
                          style: GoogleFonts.rubik(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        ...question['options'].map<Widget>((option) {
                          bool isCorrect = option == question['correctAnswer'];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 18)), // Bullet point
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    color: isCorrect ? Colors.green : Colors.black,
                                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
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
              width: 40,
              decoration: BoxDecoration(
                color: question['isCorrect'] ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Center(
                child: Text(
                  '${index + 1}', // Placeholder for question number
                  style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget buildIdentificationQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0), // Sharp corners
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 56), // Space for the correctness container
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'],
                            style: GoogleFonts.rubik(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct Answer:',
                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.black,  fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question['correctAnswer'],
                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
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
                width: 40,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}', // Placeholder for question number
                    style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFillInTheBlanksQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
      // Replace <input> placeholders with the correct answers
      String formattedQuestion = question['question'];
      List<String> correctAnswers = question['correctAnswer'].split(',');
    
      List<InlineSpan> textSpans = [];
      int lastIndex = 0;
    
      for (int i = 0; i < correctAnswers.length; i++) {
        int inputIndex = formattedQuestion.indexOf('<input>', lastIndex);
        if (inputIndex == -1) break;
    
        // Add the text before the <input> placeholder
        if (inputIndex > lastIndex) {
          textSpans.add(TextSpan(text: formattedQuestion.substring(lastIndex, inputIndex)));
        }
    
        // Add the correct answer in a box with green and bold text
        textSpans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF241242),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Text(
              correctAnswers[i],
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ));
    
        lastIndex = inputIndex + '<input>'.length;
      }
    
      // Add any remaining text after the last <input> placeholder
      if (lastIndex < formattedQuestion.length) {
        textSpans.add(TextSpan(text: formattedQuestion.substring(lastIndex)));
      }
    
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Stack(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0), // Sharp corners
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 56), // Space for the correctness container
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.rubik(fontSize: 18, color: Colors.black, height: 1.5, letterSpacing: 0.5),
                              children: textSpans,
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
                width: 40,
                decoration: BoxDecoration(
                  color: question['isCorrect'] ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}', // Placeholder for question number
                    style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

  Widget buildMatchingTypeQuestionWidget(BuildContext context, int index, Map<String, dynamic> question) {
    List<Map<String, String>> correctPairs = List<Map<String, String>>.from(question['correctPairs'] ?? []);
  
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0), // Sharp corners
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 56), // Space for the correctness container
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question['question'],
                          style: GoogleFonts.rubik(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Correct Pairs:',
                          style: GoogleFonts.rubik(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...correctPairs.map((pair) {
                          return Text(
                            '${pair['section1']} - ${pair['section2']}',
                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
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
              width: 40,
              decoration: BoxDecoration(
                color: question['isCorrect'] ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Center(
                child: Text(
                  '${index + 1}', // Placeholder for question number
                  style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }