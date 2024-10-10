import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';
import 'stages_page.dart'; // Import StagesPage
import 'package:handabatamae/widgets/adventure_button.dart'; // Import AdventureButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

class AdventurePage extends StatefulWidget {
  final String selectedLanguage;

  const AdventurePage({super.key, required this.selectedLanguage});

  @override
  AdventurePageState createState() => AdventurePageState();
}

class AdventurePageState extends State<AdventurePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  static const double questListHeight = 475; // Set the height of the quest list
  late String _selectedLanguage; // Add this line

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories(_selectedLanguage);
    setState(() {
      _categories = categories;
      _sortCategories();
      _isLoading = false;
    });
  }

  void _sortCategories() {
    const order = ['Quake', 'Storm', 'Volcano', 'Drought', 'Flood', 'Tsunami'];
    _categories.sort((a, b) {
      final aIndex = order.indexOf(order.firstWhere((element) => a['name'].contains(element), orElse: () => ''));
      final bIndex = order.indexOf(order.firstWhere((element) => b['name'].contains(element), orElse: () => ''));
      return aIndex.compareTo(bIndex);
    });
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage)),
    );
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _fetchCategories(); // Fetch categories again with the new language
    });
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
      body: ResponsiveBreakpoints(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: MaxWidthBox(
          maxWidth: 1200,
          child: ResponsiveScaledBox(
            width: ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 450),
              const Condition.between(start: 800, end: 1100, value: 800),
              const Condition.between(start: 1000, end: 1200, value: 1000),
            ]).value,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/background.svg', // Use the common background image
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 60,
                  left: 20,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 100, // Adjust the width as needed
                      maxHeight: 100, // Adjust the height as needed
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white), // Adjust the icon size and color as needed
                      onPressed: () {
                        _navigateBack(context);
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 35,
                  child: DropdownButton<String>(
                    icon: const Icon(Icons.language, color: Colors.white, size: 40), // Larger icon
                    underline: Container(), // Remove underline
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'fil',
                        child: Text('Filipino'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _changeLanguage(newValue);
                      }
                    },
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 90), // Adjust the top padding as needed
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
                              const SizedBox(height: 30), // Adjust the height to position the first button closer
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      height: questListHeight, // Set the height of the quest list
                                      child: ListView.builder(
                                        padding: const EdgeInsets.only(top: 0), // Remove extra space at the top
                                        itemCount: _categories.length,
                                        itemBuilder: (context, index) {
                                          final category = _categories[index];
                                          final buttonColor = _getButtonColor(category['name']);
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: index == _categories.length - 1 ? 0 : 20), // Apply margin only to the bottom except for the last item
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: SizedBox(
                                                width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                                                height: 100, // Increased height
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => StagesPage(
                                                          questName: category['name'],
                                                          category: {
                                                            'id': category['id'],
                                                            'name': category['name'],
                                                          },
                                                          selectedLanguage: _selectedLanguage, // Pass the selected language
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    foregroundColor: Colors.white, // Text color
                                                    backgroundColor: buttonColor, // Set background color based on category
                                                    shape: const RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                                      side: BorderSide(color: Colors.black, width: 2.0), // Black border
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        top: 6,
                                                        left: 0,
                                                        child: Text(
                                                          '${category['name']}',
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 30, // Larger font size
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
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 20,
                                                            color: Colors.white, // Text color
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}