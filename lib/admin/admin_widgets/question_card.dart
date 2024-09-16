import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildQuestionCard(int index, List<Map<String, dynamic>> questions, Function editQuestion, Function removeQuestion, List<String> Function(Map<String, dynamic>) getAnswerOptions) {
  final question = questions[index];
  final ScrollController scrollController = ScrollController(); // Create a ScrollController

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0.0), // Square corners
      side: const BorderSide(color: Colors.black, width: 2.0), // Black border
    ),
    child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 100.0), // Add padding to the right to reserve space for the indicator
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: SizedBox(
                        width: 400.0, // Set a fixed width for the question container
                        height: 60.0, // Limit the visible height of the question text to three lines
                        child: Scrollbar(
                          controller: scrollController, // Attach the ScrollController to the Scrollbar
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: scrollController, // Attach the ScrollController to the SingleChildScrollView
                            scrollDirection: Axis.vertical,
                            child: Text(
                              'Question ${index + 1}: ${question['question']}',
                              style: GoogleFonts.vt323(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (question['type'] == 'Matching Type') ...[
                                Text('Section 1 Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 16)),
                                Wrap(
                                  spacing: 8.0, // Space between items
                                  runSpacing: 4.0, // Space between lines
                                  children: question['section1'].map<Widget>((option) {
                                    return buildOptionContainer(option, 16);
                                  }).toList(),
                                ),
                                const SizedBox(height: 8.0),
                                Text('Section 2 Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 16)),
                                Wrap(
                                  spacing: 8.0, // Space between items
                                  runSpacing: 4.0, // Space between lines
                                  children: question['section2'].map<Widget>((option) {
                                    return buildOptionContainer(option, 16);
                                  }).toList(),
                                ),
                              ],
                              if (question['type'] != 'Matching Type' && question['options'] != null && question['options'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 16)),
                                    Wrap(
                                      spacing: 8.0, // Space between items
                                      runSpacing: 4.0, // Space between lines
                                      children: question['options'].map<Widget>((option) {
                                        return buildOptionContainer(option, 16);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              if (question['type'] == 'Fill in the Blank' && question['options'] != null && question['options'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Options:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 16)),
                                    Wrap(
                                      spacing: 8.0, // Space between items
                                      runSpacing: 4.0, // Space between lines
                                      children: question['options'].map<Widget>((option) {
                                        return buildOptionContainer(option, 16);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0), // Add some spacing between the columns
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (question['answer'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Answer:', style: GoogleFonts.vt323(color: Colors.black, fontSize: 16)),
                                    Wrap(
                                      spacing: 8.0, // Space between items
                                      runSpacing: 4.0, // Space between lines
                                      children: getAnswerOptions(question).map<Widget>((option) {
                                        return buildOptionContainer(option, 16);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.0), // Black border
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                question['type'],
                style: GoogleFonts.vt323(fontStyle: FontStyle.italic, color: Colors.black, fontSize: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  iconSize: 20.0, // Smaller icon size
                  padding: const EdgeInsets.all(4.0), // Smaller padding
                  onPressed: () => editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  iconSize: 20.0, // Smaller icon size
                  padding: const EdgeInsets.all(4.0), // Smaller padding
                  onPressed: () => removeQuestion(index),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildOptionContainer(String option, double fontSize) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4.0),
    padding: const EdgeInsets.all(4.0), // Smaller padding
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 1.0),
      borderRadius: BorderRadius.circular(4.0),
    ),
    child: Text(
      option,
      style: GoogleFonts.vt323(color: Colors.black, fontSize: fontSize),
    ),
  );
}