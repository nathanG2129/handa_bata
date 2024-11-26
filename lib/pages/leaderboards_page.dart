import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';
import 'package:handabatamae/widgets/header_footer/footer_widget.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../localization/leaderboards/localization.dart';
import '../pages/arcade_page.dart';
import '../services/leaderboard_service.dart';
import 'package:handabatamae/services/avatar_service.dart';

class LeaderboardsPage extends StatefulWidget {
  final String selectedLanguage;

  const LeaderboardsPage({
    super.key,
    required this.selectedLanguage,
  });

  @override
  LeaderboardsPageState createState() => LeaderboardsPageState();
}

class LeaderboardsPageState extends State<LeaderboardsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isUserProfileVisible = false;
  final StageService _stageService = StageService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  String _selectedLanguage = 'en';
  final AvatarService _avatarService = AvatarService();

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
      _tabController = TabController(length: _categories.length, vsync: this);
      _isLoading = false;
    });
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboardData(String categoryId) async {
    return _leaderboardService.getLeaderboard(categoryId);
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _handleBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage),
      ),
    );
  }

  Widget _buildLeaderboardItem(
    LeaderboardEntry data, 
    int index, 
    double horizontalPadding, 
    double rankWidth,
    double listItemPadding,
  ) {
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
              color: const Color(0xFF4d278f),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.rubik(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: ListTile(
              leading: FutureBuilder<Map<String, dynamic>?>(
                future: _avatarService.getAvatarDetails(
                  data.avatarId,
                  priority: LoadPriority.HIGH,
                ),
                builder: (context, snapshot) {
                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: snapshot.hasData
                      ? Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              image: AssetImage('assets/avatars/${snapshot.data!['img']}'),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.black,
                        ),
                  );
                },
              ),
              title: Text(
                data.nickname,
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
              trailing: Text(
                formatTime(data.crntRecord),
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  color: Colors.white
                ),
              ),
            ),
          ),
        ],
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
          _handleBack();
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
                      onBack: _handleBack,
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
                                  text: LeaderboardsLocalization.translate('title', _selectedLanguage),
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
                                        LeaderboardsLocalization.getArcadeName(category['name'], _selectedLanguage),
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
                                      return FutureBuilder<List<LeaderboardEntry>>(
                                        future: _fetchLeaderboardData(category['id']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(child: Text('Error: ${snapshot.error}'));
                                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                              child: Center(
                                                child: Text(
                                                  LeaderboardsLocalization.translate('no_records', _selectedLanguage),
                                                  style: const TextStyle(
                                                    fontFamily: 'Rubik',
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          } else {
                                            List<LeaderboardEntry> leaderboardData = snapshot.data!;
                                            return Column(
                                              children: leaderboardData.map((data) {
                                                final index = leaderboardData.indexOf(data);
                                                return _buildLeaderboardItem(
                                                  data, 
                                                  index, 
                                                  horizontalPadding, 
                                                  rankWidth,
                                                  listItemPadding,
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