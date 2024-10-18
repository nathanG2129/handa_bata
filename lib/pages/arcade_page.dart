import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';
import 'leaderboards_page.dart'; // Import LeaderboardsPage
import 'package:handabatamae/widgets/arcade_button.dart'; // Import ArcadeButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_widget.dart'; // Import HeaderWidget
import '../widgets/footer_widget.dart'; // Import FooterWidget
import '../widgets/arcade_category_button_container.dart'; // Import ArcadeCategoryButtonContainer

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
  late String _selectedLanguage;

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
      _fetchCategories();
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
      return Colors.grey;
    }
  }

  Color _darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context);
        return false;
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
                  SingleChildScrollView(
                    child: Column(
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
                          onToggleUserProfile: () {
                            // Define the action for toggling user profile if needed
                          },
                          onChangeLanguage: _changeLanguage,
                        ),
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
                                  final containerColor = _darkenColor(buttonColor, 0.2);
                                  return ArcadeCategoryButtonContainer(
                                    buttonColor: buttonColor,
                                    containerColor: containerColor,
                                    category: category,
                                    selectedLanguage: _selectedLanguage,
                                  );
                                }).toList(),
                              ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: ArcadeCategoryButtonContainer(
                            buttonColor: const Color(0xFF28e172),
                            containerColor: _darkenColor(const Color(0xFF28e172), 0.2),
                            category: const {
                              'name': 'Leaderboards',
                              'description': 'Show the world what you\'re made of and climb the leaderboards!',
                            },
                            selectedLanguage: _selectedLanguage,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LeaderboardsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const FooterWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}