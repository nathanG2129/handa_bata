import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

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
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 0), // Remove extra space at the top
                        itemCount: _stages.length,
                        itemBuilder: (context, index) {
                          final stage = _stages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Adjust padding as needed
                            child: ElevatedButton(
                              onPressed: () {
                                // Define the action when a stage is tapped
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, // Text color
                                backgroundColor: Colors.grey, // Background color
                                shape: const CircleBorder(), // Circular button
                                padding: const EdgeInsets.all(20), // Adjust padding for circular shape
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    stage['stageName'] ?? 'Unknown Stage',
                                    style: GoogleFonts.rubik(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    stage['description'] ?? 'No description available',
                                    style: GoogleFonts.rubik(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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