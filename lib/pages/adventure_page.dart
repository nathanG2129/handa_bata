import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:handabatamae/widgets/button_3d.dart';
import 'play_page.dart';
import 'package:handabatamae/widgets/buttons/adventure_button.dart'; // Import AdventureButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'user_profile.dart'; // Import UserProfilePage

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
  late String _selectedLanguage;
  bool _isUserProfileVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
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

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  Color _getButtonColor(String categoryName) {
    if (categoryName.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (categoryName.contains('Storm') || categoryName.contains('Flood')) {
      return const Color(0xFF2C28E1);
    } else if (categoryName.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (categoryName.contains('Drought') || categoryName.contains('Tsunami')) {
      return const Color(0xFF31111D);
    } else {
      return Colors.grey; // Default color
    }
  }

  Color _darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  void _onCategoryPressed(Map<String, dynamic> category) {
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUserProfileVisible) {
          setState(() {
            _isUserProfileVisible = false;
          });
          return false;
        } else {
          _navigateBack(context);
          return false;
        }
      },
      child: Scaffold(
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
                      HeaderWidget(
                        selectedLanguage: _selectedLanguage,
                        onBack: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: _selectedLanguage)),
                          );
                        },
                        onToggleUserProfile: _toggleUserProfile,
                        onChangeLanguage: _changeLanguage,
                      ),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20), // Adjust the top padding as needed
                                    child: AdventureButton(
                                      onPressed: () {
                                        // Define the action for the Adventure button if needed
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 30), // Adjust the height to position the first button closer
                                  _isLoading
                                      ? const CircularProgressIndicator()
                                      : Column(
                                          children: _categories.map((category) {
                                            final buttonColor = _getButtonColor(category['name']);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 40), // Apply margin only to the bottom
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Button3D(
                                                  width: 350,
                                                  height: 215,
                                                  onPressed: () => _onCategoryPressed(category),
                                                  backgroundColor: buttonColor,
                                                  borderColor: _darkenColor(buttonColor),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${category['name']}',
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 30, // Larger font size
                                                            color: Colors.white, // Text color
                                                          ),
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          category['description'],
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 25,
                                                            color: Colors.white, // Text color
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                  const SizedBox(height: 20),
                                  const Spacer(), // Push the footer to the bottom
                                  const FooterWidget(), // Add the footer here
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isUserProfileVisible)
                    UserProfilePage(onClose: _toggleUserProfile, selectedLanguage: _selectedLanguage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}