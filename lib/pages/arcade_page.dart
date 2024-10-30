import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'play_page.dart';
import 'leaderboards_page.dart'; // Import LeaderboardsPage
import 'package:handabatamae/widgets/buttons/arcade_button.dart'; // Import ArcadeButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget
import 'package:handabatamae/widgets/buttons/button_3d.dart'; // Import Button3D

class ArcadePage extends StatefulWidget {
  final String selectedLanguage;

  const ArcadePage({super.key, required this.selectedLanguage});

  @override
  ArcadePageState createState() => ArcadePageState();
}

class ArcadePageState extends State<ArcadePage> {
  final StageService _stageService = StageService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isUserProfileVisible = false;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _fetchCategories();
  }

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _fetchCategories();
    });
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

  Color _getButtonColor(String categoryName) {
    if (categoryName.contains('Quake')) {
      return const Color(0xFFF5672B);
    } else if (categoryName.contains('Storm')) {
      return const Color(0xFF2C28E1);
    } else if (categoryName.contains('Flood')) {
      return const Color(0xFF2C62DE);
    } else if (categoryName.contains('Volcano')) {
      return const Color(0xFFB3261E);
    } else if (categoryName.contains('Drought')) {
      return const Color(0xFF8D6647);
    } else if (categoryName.contains('Tsunami')) {
      return const Color(0xFF033C72);
    } else {
      return Colors.grey;
    }
  }

  Color _darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Map<String, String> _getCategoryText(String categoryName) {
    if (categoryName.contains('Quake')) {
      return {
        'name': 'Shake',
        'description': _selectedLanguage == 'fil'
            ? 'Patunayan ang iyong lakas ng loob laban sa makapangyarihang pagyanig ng lupa!'
            : 'Prove your courage against the earth\'s mighty tremors!',
      };
    } else if (categoryName.contains('Storm')) {
      return {
        'name': 'Rumble',
        'description': _selectedLanguage == 'fil'
            ? 'Subukin ang iyong katapangan laban sa galit ng rumaragasang bagyo!'
            : 'Challenge your bravery against the fury of a raging typhoon!',
      };
    } else {
      return {
        'name': categoryName,
        'description': '',
      };
    }
  }

  void _onCategoryPressed(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArcadeStagesPage(
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
                    'assets/backgrounds/background.svg',
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
                            MaterialPageRoute(
                              builder: (context) => PlayPage(selectedLanguage: widget.selectedLanguage, title: ''),
                            ),
                          );
                        },
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
                                    padding: const EdgeInsets.only(top: 20),
                                    child: ArcadeButton(
                                      onPressed: () {
                                        // Define the action for the Arcade button if needed
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _isLoading
                                      ? const CircularProgressIndicator()
                                      : Column(
                                          children: _categories.map((category) {
                                            final buttonColor = _getButtonColor(category['name']);
                                            final categoryText = _getCategoryText(category['name']);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 30), // Apply margin only to the bottom
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Button3D(
                                                  width: 350,
                                                  height: 150,
                                                  onPressed: () => _onCategoryPressed(category),
                                                  backgroundColor: buttonColor,
                                                  borderColor: _darkenColor(buttonColor),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          categoryText['name']!,
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 30, // Larger font size
                                                            color: Colors.white, // Text color
                                                          ),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        Text(
                                                          categoryText['description']!,
                                                          style: GoogleFonts.vt323(
                                                            fontSize: 22,
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 0, bottom: 40),
                                    child: Button3D(
                                      width: 350,
                                      height: 150,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LeaderboardsPage(),
                                          ),
                                        );
                                      },
                                      backgroundColor: const Color.fromARGB(255, 37, 196, 100),
                                      borderColor: _darkenColor(const Color(0xFF28e172)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Leaderboards',
                                              style: GoogleFonts.vt323(
                                                fontSize: 30, // Larger font size
                                                color: Colors.white, // Text color
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Show the world what you\'re made of and climb the leaderboards!',
                                              style: GoogleFonts.vt323(
                                                fontSize: 22,
                                                color: Colors.white, // Text color
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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