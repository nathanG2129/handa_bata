import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';
import 'arcade_stages_page.dart'; // Import ArcadeStagesPage
import 'package:handabatamae/widgets/arcade_button.dart'; // Import ArcadeButton
import 'package:handabatamae/services/stage_service.dart'; // Import StageService
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

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
  static const double questListHeight = 475;
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
                  Positioned(
                    top: 60,
                    left: 35,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 100,
                        maxHeight: 100,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayPage(selectedLanguage: widget.selectedLanguage, title: '',),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 35,
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.language, color: Colors.white, size: 40),
                      underline: Container(),
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
                        padding: const EdgeInsets.only(top: 90),
                        child: ArcadeButton(
                          onPressed: () {
                            // Define the action for the Arcade button if needed
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 30),
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        height: questListHeight,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.only(top: 0),
                                          itemCount: _categories.length,
                                          itemBuilder: (context, index) {
                                            final category = _categories[index];
                                            final buttonColor = _getButtonColor(category['name']);
                                            return Padding(
                                              padding: EdgeInsets.only(bottom: index == _categories.length - 1 ? 0 : 20),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: SizedBox(
                                                  width: MediaQuery.of(context).size.width * 0.8,
                                                  height: 100,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ArcadeStagesPage(
                                                            questName: category['name'],
                                                            category: {
                                                              'id': category['id'],
                                                              'name': category['name'],
                                                            },
                                                            selectedLanguage: _selectedLanguage,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor: Colors.white,
                                                      backgroundColor: buttonColor,
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.all(Radius.circular(0)),
                                                        side: BorderSide(color: Colors.black, width: 2.0),
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
                                                              fontSize: 30,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 43,
                                                          left: 0,
                                                          right: 8,
                                                          child: Text(
                                                            category['description'] ?? '',
                                                            style: GoogleFonts.vt323(
                                                              fontSize: 22,
                                                              color: Colors.white,
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
      ),
    );
  }
}