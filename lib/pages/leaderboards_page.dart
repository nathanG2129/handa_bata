import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:handabatamae/pages/user_profile.dart';

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  LeaderboardsPageState createState() => LeaderboardsPageState();
}

class LeaderboardsPageState extends State<LeaderboardsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isUserProfileVisible = false;
  final StageService _stageService = StageService();
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
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
      _tabController = TabController(length: _categories.length, vsync: this);
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData(String categoryId) async {
    List<Map<String, dynamic>> leaderboardData = [];
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('User').get();

    for (var userDoc in userSnapshot.docs) {
      DocumentSnapshot gameSaveDataDoc = await userDoc.reference.collection('GameSaveData').doc(categoryId).get();
      if (gameSaveDataDoc.exists) {
        Map<String, dynamic> gameSaveData = gameSaveDataDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> stageData = gameSaveData['stageData'] as Map<String, dynamic>;

        for (var stageKey in stageData.keys) {
          if (stageKey.contains('Arcade')) {
            int bestRecord = stageData[stageKey]['bestRecord'] as int;
            int crntRecord = stageData[stageKey]['crntRecord'] as int;

            if (bestRecord != -1 && crntRecord != -1) {
              DocumentSnapshot profileDoc = await userDoc.reference.collection('ProfileData').doc(userDoc.id).get();
              if (profileDoc.exists) {
                Map<String, dynamic> profileData = profileDoc.data() as Map<String, dynamic>;
                leaderboardData.add({
                  'nickname': profileData['nickname'],
                  'crntRecord': crntRecord,
                });
              }
            }
          }
        }
      }
    }

    leaderboardData.sort((a, b) => a['crntRecord'].compareTo(b['crntRecord']));
    return leaderboardData;
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
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
          Navigator.pop(context);
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
                          Navigator.pop(context);
                        },
                        onChangeLanguage: _changeLanguage, 
                      ),
                      if (_isLoading)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverList(
                                delegate: SliverChildListDelegate(
                                  [
                                    const SizedBox(height: 20),
                                    const Center(
                                      child: TextWithShadow(
                                        text: 'Leaderboards',
                                        fontSize: 65,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TabBar(
                                      controller: _tabController,
                                      isScrollable: true,
                                      indicatorColor: Colors.white,
                                      labelColor: Colors.white,
                                      unselectedLabelColor: Colors.white,
                                      indicator: const UnderlineTabIndicator(
                                        borderSide: BorderSide(color: Colors.white, width: 2.0),
                                      ),
                                      tabs: _categories.map((category) {
                                          return Tab(
                                          child: Text(
                                            category['name'],
                                            style: GoogleFonts.rubik(fontSize: 18),
                                          ),
                                          );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                              if (_tabController != null)
                                SliverFillRemaining(
                                  hasScrollBody: true,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: _categories.map((category) {
                                      return FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _fetchLeaderboardData(category['id']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(child: Text('Error: ${snapshot.error}'));
                                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return const Center(
                                            child: Text(
                                              'No records yet, be the first to submit one!',
                                              style: TextStyle(
                                              fontFamily: 'Rubik',
                                              fontSize: 18,
                                              color: Colors.white,
                                              ),
                                            ),
                                            );
                                          } else {
                                            List<Map<String, dynamic>> leaderboardData = snapshot.data!;
                                            return Column(
                                              children: leaderboardData.map((data) {
                                                final index = leaderboardData.indexOf(data);
                                                Color containerColor;
                                                if (index == 0) {
                                                  containerColor = const Color(0xFFF1B33A); // Gold
                                                } else if (index == 1) {
                                                  containerColor = Colors.grey; // Silver
                                                } else if (index == 2) {
                                                  containerColor = const Color(0xFFCD7F32); // Bronze
                                                } else {
                                                  containerColor = const Color(0xFF241242); // Default
                                                }

                                                return Container(
                                                  color: containerColor,
                                                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          width: 40,
                                                          color: const Color(0xFF4d278f), // Rank container color
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            '${index + 1}',
                                                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(left: 50.0), // Add padding to the left to make space for the rank container
                                                        child: ListTile(
                                                          title: Text(
                                                            data['nickname'],
                                                            style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                          ),
                                                          trailing: Text(
                                                            formatTime(data['crntRecord']),
                                                            style: GoogleFonts.rubik(fontSize: 16, color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  children: [
                                    const Spacer(),
                                    FooterWidget(selectedLanguage: _selectedLanguage), // Add the footer here
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