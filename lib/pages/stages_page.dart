import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/widgets/stage_dialog.dart';

class StagesPage extends StatefulWidget {
  final String questName;
  final Map<String, String> category; // Update to accept a map

  const StagesPage({super.key, required this.questName, required this.category});

  @override
  StagesPageState createState() => StagesPageState();
}

class StagesPageState extends State<StagesPage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;
  String _selectedMode = 'Normal'; // Add a state variable for the selected mode

  @override
  void initState() {
    super.initState();
    print('StagesPage received category: ${widget.category}');
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    List<Map<String, dynamic>> stages = await _stageService.fetchStages('en', widget.category['id']!);
    if (!mounted) return;
    setState(() {
      _stages = stages;
      _isLoading = false;
    });
  }

  Future<int> _fetchNumberOfQuestions(int stageIndex) async {
    // Replace with actual logic to fetch the number of questions for the stage
    return 10; // Example: 10 questions
  }

  Color _getStageColor(String? category) {
    if (category == null) return Colors.grey; // Default color for null category
    if (category.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (category.contains('Storm') || category.contains('Flood')) {
      return const Color(0xFF2C62DE);
    } else if (category.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (category.contains('Drought') || category.contains('Tsunami')) {
      return const Color(0xFF31111D);
    } else {
      return Colors.grey; // Default color
    }
  }

  Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  String _getModifiedSvg(Color color1) {
    Color color2 = darken(color1);
    return '''
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="100%"
      height="100%"
      viewBox="0 0 12 11"
      fill="none"
    >
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M8 0H4V1H2V2H1V4H0V7H1V9H2V10H4V11H8V10H10V9H11V7H12V4H11V2H10V1H8V0ZM8 1V2H10V4H11V7H10V9H8V10H4V9H2V7H1V4H2V2H4V1H8Z"
        fill="${color2.toHex()}"
      />
      <path
        d="M4 1H8V2H10V4H11V7H10V9H8V10H4V9H2V7H1V4H2V2H4V1Z"
        fill="${color1.toHex()}"
      />
    </svg>
    ''';
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
                        setState(() {
                          _selectedMode = 'Normal'; // Set the selected mode to Normal
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: _selectedMode == 'Normal' ? Colors.blue : Colors.grey, // Background color
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                        ),
                      ),
                      child: const Text('Normal'),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMode = 'Hard'; // Set the selected mode to Hard
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: _selectedMode == 'Hard' ? Colors.red : Colors.grey, // Background color
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
                          final stageCategory = widget.category['name']; // Use the passed category name
                          final stageColor = _getStageColor(stageCategory);

                          return GestureDetector(
                            onTap: () async {
                              Map<String, dynamic> stageData = _stages[stageIndex];
                              int numberOfQuestions = await _fetchNumberOfQuestions(stageIndex);
                              if (!mounted) return;
                              showStageDialog(
                                context,
                                stageNumber,
                                {
                                  'id': widget.category['id']!, // Ensure the category id is passed correctly
                                  'name': widget.category['name']!, // Ensure the category name is passed correctly
                                },
                                numberOfQuestions,
                                stageData,
                                _selectedMode, // Pass the selected mode
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.string(
                                  _getModifiedSvg(stageColor),
                                  width: 100,
                                  height: 100,
                                ),
                                Text(
                                  '$stageNumber',
                                  style: GoogleFonts.vt323(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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

extension ColorExtension on Color {
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}