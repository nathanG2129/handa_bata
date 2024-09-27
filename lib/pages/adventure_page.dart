import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';
import 'package:handabatamae/widgets/adventure_button.dart'; // Import AdventureButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class AdventurePage extends StatefulWidget {
  const AdventurePage({super.key});

  @override
  _AdventurePageState createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    print('Fetching categories...');
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories('en'); // Assuming 'en' is the language
    print('Fetched categories: $categories');
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PlayPage(title: '',)),
    );
  }

  Color _getButtonColor(String categoryName) {
    if (categoryName.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (categoryName.contains('Storm') || categoryName.contains('Flood')) {
      return const Color(0xFF2C62DE);
    } else if (categoryName.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (categoryName.contains('Drought') || categoryName.contains('Tsunami')) {
      return const Color(0xFF31111D);
    } else {
      return Colors.grey; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/backgrounds/background.svg', // Use the common background image
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
                child: AdventureButton(
                  onPressed: () {
                    // Define the action for the Adventure button if needed
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, // Align to the start
                      children: [
                        const SizedBox(height: 20), // Adjust the height to position the first button closer
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                height: 420, // Adjust the height to show only 4 quests at a time
                                child: ListView.builder(
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    final buttonColor = _getButtonColor(category['name']);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20), // Apply margin only to the bottom
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                                          height: 75, // Fixed height
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // Define the action for the category button
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white, // Text color
                                              backgroundColor: buttonColor, // Set background color based on category
                                              shape: RoundedRectangleBorder(
                                                borderRadius: const BorderRadius.all(Radius.circular(0)), // Sharp corners
                                                side: const BorderSide(color: Colors.black, width: 2.0), // Black border
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  top: 12,
                                                  left: 0,
                                                  child: Text(
                                                    '${category['name']}',
                                                    style: GoogleFonts.rubik(
                                                      fontSize: 20, // Larger font size
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white, // Text color
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 39,
                                                  left: 0,
                                                  right: 8,
                                                  child: Text(
                                                    category['description'],
                                                    style: GoogleFonts.rubik(
                                                      fontSize: 12,
                                                      color: Colors.white, // Text color
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20), // Adjust the bottom padding as needed
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const PlayPage(title: '',)),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF241242), // Text color
                    backgroundColor: Colors.white, // Background color
                    minimumSize: const Size(100, 40), // Smaller button size
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                    ),
                  ),
                  child: const Text('Back to Play Page'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}