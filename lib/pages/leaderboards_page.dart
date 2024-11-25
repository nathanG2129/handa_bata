import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
        body: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            // Get responsive values based on device type
            final horizontalPadding = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 16,
              tablet: 200,
              desktop: 48,
            );

            final titleFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 45,
              tablet: 55,
              desktop: 65,
            );

            final tabFontSize = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            );

            final rankWidth = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 40,
              tablet: 50,
              desktop: 60,
            );

            final listItemPadding = ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 4,
              tablet: 5,
              desktop: 8,
            );

            return Stack(
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
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Center(
                                child: TextWithShadow(
                                  text: 'Leaderboards',
                                  fontSize: titleFontSize,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: TabBar(
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
                                        style: GoogleFonts.rubik(fontSize: tabFontSize),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_tabController != null)
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.6,
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
                                                  margin: EdgeInsets.symmetric(
                                                    vertical: listItemPadding,
                                                    horizontal: horizontalPadding,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned(
                                                        left: 0,
                                                        top: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          width: rankWidth,
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
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      child: FooterWidget(selectedLanguage: _selectedLanguage),
                    ),
                  ],
                ),
                if (_isUserProfileVisible)
                  UserProfilePage(
                    onClose: _toggleUserProfile,
                    selectedLanguage: _selectedLanguage,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}