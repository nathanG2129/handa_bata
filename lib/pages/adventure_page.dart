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
  static const double questListHeight = 415; // Set the height of the quest list
  late String _selectedLanguage; // Add this line

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
    print('Selected languagesdasds: $_selectedLanguage');
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    //print('Fetching categories...');
    List<Map<String, dynamic>> categories = await _stageService.fetchCategories(_selectedLanguage); // Assuming 'en' is the language
    //print('Fetched categories: $categories');
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
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 75), // Adjust the top padding as needed
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
                                                    print('Navigating to StagesPage with category: $category');
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => StagesPage(
                                                          questName: category['name'],
                                                          category: {
                                                            'id': category['id'],
                                                            'name': category['name'],
                                                          },
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20), // Adjust the bottom padding as needed
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage,)),
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
          ),
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final Map<String, dynamic> category;
  final Color buttonColor;

  const AnimatedButton({required this.category, required this.buttonColor});

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        print('Navigating to StagesPage with category: ${widget.category}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StagesPage(
              questName: widget.category['name'],
              category: {
                'id': widget.category['id'],
                'name': widget.category['name'],
              },
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.buttonColor,
            border: Border.all(color: Colors.black, width: 2.0),
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(4, 4),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                offset: const Offset(-4, -4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                left: 10,
                right: 10,
                child: Text(
                  widget.category['name'],
                  style: GoogleFonts.rubik(
                    fontSize: 20, // Larger font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned(
                top: 39,
                left: 10,
                right: 10,
                child: Text(
                  widget.category['description'],
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: Colors.white, // Text color
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}