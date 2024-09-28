import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/stage_dialog.dart'; // Import the new dialog file

class StagesPage extends StatefulWidget {
  final String questName;
  final String category;

  const StagesPage({super.key, required this.questName, required this.category});

  @override
  _StagesPageState createState() => _StagesPageState();
}

class _StagesPageState extends State<StagesPage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    print('Fetching stages for category: ${widget.category}');
    List<Map<String, dynamic>> stages = await _stageService.fetchStages('en', widget.category);
    print('Fetched stages: $stages');
    setState(() {
      _stages = stages;
      _isLoading = false;
    });
  }

  Future<int> _fetchNumberOfQuestions(int stageIndex) async {
    // Replace with actual logic to fetch the number of questions for the stage
    return 10; // Example: 10 questions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add the background image
          SvgPicture.asset(
            'assets/backgrounds/background.svg', // Use the common background image
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              // Add the "Handa Bata Mobile" text from the splash page
              Padding(
                padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
                child: Column(
                  children: [
                    const TextWithShadow(text: 'Handa Bata', fontSize: 90),
                    Transform.translate(
                      offset: const Offset(0, -40), // Adjust this value to control the vertical offset
                      child: const TextWithShadow(text: 'Mobile', fontSize: 85),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 75), // Adjust the top padding as needed
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.questName,
                      style: GoogleFonts.rubik(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Text color
                      ),
                    ),
                    const SizedBox(width: 20), // Space between quest name and buttons
                    ElevatedButton(
                      onPressed: () {
                        // Define the action for the Normal button
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: Colors.blue, // Background color
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                        ),
                      ),
                      child: const Text('Normal'),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    ElevatedButton(
                      onPressed: () {
                        // Define the action for the Hard button
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: Colors.red, // Background color
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                        ),
                      ),
                      child: const Text('Hard'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // Space below the quest name and buttons
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.all(35), // Adjust padding as needed
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // 3 columns
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 50,
                        ),
                        itemCount: _stages.length,
                        itemBuilder: (context, index) {
                          final rowIndex = index ~/ 3;
                          final columnIndex = index % 3;
                          final isEvenRow = rowIndex % 2 == 0;
                          final stageIndex = isEvenRow
                              ? index
                              : (rowIndex + 1) * 3 - columnIndex - 1;
                          final stageNumber = stageIndex + 1;

                          return ElevatedButton(
                            onPressed: () async {
                              int numberOfQuestions = await _fetchNumberOfQuestions(stageIndex);
                              Map<String, dynamic> stageData = _stages[stageIndex];
                              showStageDialog(context, stageNumber, widget.questName, numberOfQuestions, stageData);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, // Text color
                              backgroundColor: Colors.grey, // Background color
                              shape: const CircleBorder(), // Circular button
                              padding: const EdgeInsets.all(20), // Adjust padding for circular shape
                              minimumSize: const Size(60, 60) 
                            ),
                            child: Center(
                              child: Text(
                                '$stageNumber',
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}